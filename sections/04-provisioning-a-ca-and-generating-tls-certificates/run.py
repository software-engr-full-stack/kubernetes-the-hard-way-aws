#!/usr/bin/env python3

import sys
import pathlib
import os
import inspect
import yaml
import subprocess


class Run(object):
    def __init__(self, certs_dir, config_file):
        certs_path = pathlib.Path(certs_dir)
        certs_path.mkdir(parents=True, exist_ok=True)

        with open(config_file, 'r') as stream:
            try:
                config = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                raise ValueError('YAML error: {}'.format(exc))

        print('* ---- Certificate Authority ---- *')

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

        csr_json = certs_path.joinpath('ca-csr.json')
        out_file = csr_json
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

        p1 = subprocess.Popen(['cfssl', 'gencert', '-initca',  csr_json], stdout=subprocess.PIPE)
        subprocess.Popen(['cfssljson', '-bare', 'ca'], stdin=p1.stdout)
        p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.

        print()
        print('* ---- Client and Server Certificates ---- *')

        print('* ---- The Admin Client Certificate ---- *')


Run(sys.argv[1], sys.argv[2])
