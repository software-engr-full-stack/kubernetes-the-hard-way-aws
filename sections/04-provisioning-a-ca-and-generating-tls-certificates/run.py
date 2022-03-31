#!/usr/bin/env python3

import sys
import pathlib
import os
import inspect
import subprocess
import time

this_file = pathlib.Path((inspect.getfile(inspect.currentframe())))
app_dir = this_file.joinpath('..', '..', '..').resolve()
sys.path.insert(0, app_dir.as_posix())

from lib.config import Config  # noqa: E402
from lib.public_addresses import PublicAddresses  # noqa: E402
from lib.path import Path  # noqa: E402


class Run(object):
    def __init__(self):
        config = Config(app_dir.joinpath('config.yml'))

        name = config['name']

        public_addresses = PublicAddresses(config.all_hostnames, name=name)
        path = Path()

        certs_path = path.certs
        certs_path.mkdir(parents=True, exist_ok=True)

        if self._certs_present(certs_path):
            print('... certificates already created, returning...')
            return

        self._certs(config, public_addresses, certs_path)

    def _sync_and_delay(self, delay=2):
        subprocess.run(['sync'])
        print("... sleeping for '{}' seconds to allow files to be written to storage...".format(delay))
        time.sleep(delay)

    def _certs_present(self, certs_path):
        # TODO: do more robust check, probably check every file that is supposed to be created.
        files = os.listdir(certs_path)

        return len(files) >= 33

    def _certs(self, config, public_addresses, certs_path):
        os.chdir(certs_path)

        print('##### Certificate Authority ####')

        base_name = 'ca'
        out_file = certs_path.joinpath('{}-config.json'.format(base_name))
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

        out_file = certs_path.joinpath('{}-csr.json'.format(base_name))
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
                '''.format(**config.organization)
            ))

        p1 = subprocess.Popen(['cfssl', 'gencert', '-initca',  out_file], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', base_name], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay()

        print()
        print('#### Client and Server Certificates ####')

        print('# **** The Admin Client Certificate **** #')
        base_name = 'admin'
        out_file = certs_path.joinpath('{}-csr.json'.format(base_name))
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "{base_name}",
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
                '''.format(**{**config.organization, **{'base_name': base_name}})
            ))

        p1 = subprocess.Popen([
            'cfssl', 'gencert',
            '-ca={}/ca.pem'.format(certs_path),
            '-ca-key={}/ca-key.pem'.format(certs_path),
            '-config={}/ca-config.json'.format(certs_path),
            '-profile=kubernetes',
            out_file
        ], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', base_name], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay()

        print()
        print('# **** The Kubelet Client Certificates **** #')

        for host in config.workers:
            instance_name = host['hostname']
            aws_hostname = host['aws_hostname']
            out_file = certs_path.joinpath('{}-csr.json'.format(instance_name))
            with open(out_file, 'w') as stream:
                stream.write(inspect.cleandoc(
                    '''
                        {{
                          "CN": "system:node:{aws_hostname}",
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
                    '''.format(**{**config.organization, **{'aws_hostname': aws_hostname}})
                ))

            external_ip = public_addresses[instance_name]
            internal_ip = host['internal_ip']

            p1 = subprocess.Popen([
                'cfssl', 'gencert',
                '-ca={}/ca.pem'.format(certs_path),
                '-ca-key={}/ca-key.pem'.format(certs_path),
                '-config={}/ca-config.json'.format(certs_path),
                '-hostname={},{},{}'.format(aws_hostname, external_ip, internal_ip),
                '-profile=kubernetes',
                out_file
            ], stdout=subprocess.PIPE)
            subprocess.Popen(['cfssljson', '-bare', instance_name], stdin=p1.stdout)
            p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay()

        print()
        print('# **** The Controller Manager Client Certificate **** #')
        base_name = 'kube-controller-manager'
        out_file = certs_path.joinpath('{}-csr.json'.format(base_name))
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "system:{base_name}",
                      "key": {{
                        "algo": "rsa",
                        "size": 2048
                      }},
                      "names": [
                        {{
                          "C": "{country}",
                          "L": "{city}",
                          "O": "system:{base_name}",
                          "OU": "{ou}",
                          "ST": "{state}"
                        }}
                      ]
                    }}
                '''.format(**{**config.organization, **{'base_name': base_name}})
            ))

        p1 = subprocess.Popen([
            'cfssl', 'gencert',
            '-ca={}/ca.pem'.format(certs_path),
            '-ca-key={}/ca-key.pem'.format(certs_path),
            '-config={}/ca-config.json'.format(certs_path),
            '-profile=kubernetes',
            out_file
        ], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', base_name], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay()

        print()
        print('# **** The Kube Proxy Client Certificate **** #')
        base_name = 'kube-proxy'
        out_file = certs_path.joinpath('{}-csr.json'.format(base_name))
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "system:{base_name}",
                      "key": {{
                        "algo": "rsa",
                        "size": 2048
                      }},
                      "names": [
                        {{
                          "C": "{country}",
                          "L": "{city}",
                          "O": "system:node-proxier",
                          "OU": "{ou}",
                          "ST": "{state}"
                        }}
                      ]
                    }}
                '''.format(**{**config.organization, **{'base_name': base_name}})
            ))

        p1 = subprocess.Popen([
            'cfssl', 'gencert',
            '-ca={}/ca.pem'.format(certs_path),
            '-ca-key={}/ca-key.pem'.format(certs_path),
            '-config={}/ca-config.json'.format(certs_path),
            '-profile=kubernetes',
            out_file
        ], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', base_name], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay()

        print()
        print('# **** The Scheduler Client Certificate **** #')
        base_name = 'kube-scheduler'
        out_file = certs_path.joinpath('{}-csr.json'.format(base_name))
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "system:{base_name}",
                      "key": {{
                        "algo": "rsa",
                        "size": 2048
                      }},
                      "names": [
                        {{
                          "C": "{country}",
                          "L": "{city}",
                          "O": "system:{base_name}",
                          "OU": "{ou}",
                          "ST": "{state}"
                        }}
                      ]
                    }}
                '''.format(**{**config.organization, **{'base_name': base_name}})
            ))

        p1 = subprocess.Popen([
            'cfssl', 'gencert',
            '-ca={}/ca.pem'.format(certs_path),
            '-ca-key={}/ca-key.pem'.format(certs_path),
            '-config={}/ca-config.json'.format(certs_path),
            '-profile=kubernetes',
            out_file
        ], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', base_name], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay(4)

        print()
        print('# **** The Kubernetes API Server Certificate **** #')
        base_name = 'kubernetes'
        out_file = certs_path.joinpath('{}-csr.json'.format(base_name))
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "{base_name}",
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
                '''.format(**{**config.organization, **{'base_name': base_name}})
            ))

        kubernetes_hostnames = [
            'kubernetes',
            'kubernetes.default',
            'kubernetes.default.svc',
            'kubernetes.default.svc.cluster',
            'kubernetes.svc.cluster.local'
        ]

        hostnames = [
            config['network']['internal_cluster_services_ip'],
            *config.controller_internal_ips,
            *config.controller_aws_hostnames,
            public_addresses['kubernetes'],
            '127.0.0.1',
            *kubernetes_hostnames
        ]

        p1 = subprocess.Popen([
            'cfssl', 'gencert',
            '-ca={}/ca.pem'.format(certs_path),
            '-ca-key={}/ca-key.pem'.format(certs_path),
            '-config={}/ca-config.json'.format(certs_path),
            '-hostname={}'.format(','.join(hostnames)),
            '-profile=kubernetes',
            out_file
        ], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', base_name], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay()

        print()
        print('#### The Service Account Key Pair ####')
        base_name = 'service-account'
        out_file = certs_path.joinpath('{}-csr.json'.format(base_name))
        print("Writing '{}'...".format(out_file))
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    {{
                      "CN": "system:service-accounts",
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
                '''.format(**config.organization)
            ))

        p1 = subprocess.Popen([
            'cfssl', 'gencert',
            '-ca={}/ca.pem'.format(certs_path),
            '-ca-key={}/ca-key.pem'.format(certs_path),
            '-config={}/ca-config.json'.format(certs_path),
            '-profile=kubernetes',
            out_file
        ], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', base_name], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        self._sync_and_delay()


Run()
