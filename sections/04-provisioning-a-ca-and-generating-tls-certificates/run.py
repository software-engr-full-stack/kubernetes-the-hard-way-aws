#!/usr/bin/env python3

# import sys
import pathlib
import os
import inspect
import yaml
import subprocess


class Run(object):
    def __init__(self, certs_dir, config_file, public_addresses):
        certs_path = pathlib.Path(certs_dir)
        certs_path.mkdir(parents=True, exist_ok=True)

        with open(config_file, 'r') as stream:
            try:
                config = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                raise ValueError('YAML error: {}'.format(exc))

        print('##### Certificate Authority ####')

        os.chdir(certs_dir)

        out_file = certs_path.joinpath('ca-config.json')
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {
                      "signing": {
                        "default": {
                          "expiry": "8760h"
                        },
                        "profiles": {
                          "kubernetes": {
                            "usages": ["signing", "key encipherment", "server auth", "client auth"],
                            "expiry": "8760h"
                          }
                        }
                      }
                    }
                '''
            ))

        ca_csr = certs_path.joinpath('ca-csr.json')
        out_file = ca_csr
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "Kubernetes",
                      "key": {{
                        "algo": "rsa",
                        "size": 2048
                      }},
                      "names": [
                        {{
                          "C": "{country}",
                          "L": "{city}",
                          "O": "{o}",
                          "OU": "{ou}",
                          "ST": "{state}"
                        }}
                      ]
                    }}
                '''.format(**config)
            ))

        p1 = subprocess.Popen(['cfssl', 'gencert', '-initca',  ca_csr], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', 'ca'], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        print()
        print('#### Client and Server Certificates ####')

        print('# **** The Admin Client Certificate **** #')
        admin_csr = certs_path.joinpath('admin-csr.json')
        out_file = admin_csr
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "admin",
                      "key": {{
                        "algo": "rsa",
                        "size": 2048
                      }},
                      "names": [
                        {{
                          "C": "{country}",
                          "L": "{city}",
                          "O": "system:masters",
                          "OU": "{ou}",
                          "ST": "{state}"
                        }}
                      ]
                    }}
                '''.format(**config)
            ))

        p1 = subprocess.Popen([
            'cfssl', 'gencert',
            '-ca={certs_path}/ca.pem'.format(certs_path=certs_path),
            '-ca-key={certs_path}/ca-key.pem'.format(certs_path=certs_path),
            '-config={certs_path}/ca-config.json'.format(certs_path=certs_path),
            '-profile=kubernetes',
            admin_csr
        ], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', 'admin'], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        print()
        print('# **** The Kubelet Client Certificates **** #')

        # TODO: parameterize instead of hard-coding "0", "1", etc.
        host_type = 'worker'
        ip_base = 'ip-10-240-0-2'
        for ix in [0]:
            instance = '-'.join([host_type, ix])
            instance_hostname = ''.join([ip_base, ix])
            instance_csr = certs_path.joinpath('{}-csr.json'.format(instance))
            out_file = instance_csr
            with open(out_file, 'w') as stream:
                stream.write(inspect.cleandoc(
                    '''
                        {{
                          "CN": "system:node:${instance_hostname}",
                          "key": {{
                            "algo": "rsa",
                            "size": 2048
                          }},
                          "names": [
                            {{
                              "C": "{country}",
                              "L": "{city}",
                              "O": "system:nodes",
                              "OU": "{ou}",
                              "ST": "{state}"
                            }}
                          ]
                        }}
                    '''.format(**{**config, **{'instance_hostname': instance_hostname}})
                ))
            # local EXTERNAL_IP=${PUBLIC_ADDRESS[${instance}]}

            # local INTERNAL_IP="10.240.0.2${i}"

            # cfssl gencert \
            #   -ca="$certs_dir"/ca.pem \
            #   -ca-key="$certs_dir"/ca-key.pem \
            #   -config="$certs_dir"/ca-config.json \
            #   -hostname=${INSTANCE_HOSTNAME},${EXTERNAL_IP},${INTERNAL_IP} \
            #   -profile=kubernetes \
            #   "$certs_dir"/${instance}-csr.json | cfssljson -bare ${instance}


# Run(sys.argv[1], sys.argv[2], sys.argv[3])
