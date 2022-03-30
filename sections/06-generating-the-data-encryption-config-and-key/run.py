#!/usr/bin/env python3

import sys
import pathlib
import os
import inspect
import base64
from cryptography.fernet import Fernet

this_file = pathlib.Path((inspect.getfile(inspect.currentframe())))
app_dir = this_file.joinpath('..', '..', '..').resolve()
sys.path.insert(0, app_dir.as_posix())

from lib.path import Path  # noqa: E402


class Run(object):
    def __init__(self):
        # head -c 32 /dev/urandom | base64
        encryption_key = base64.b64encode(Fernet.generate_key())[:32].decode('utf-8')
        path = Path()

        config_auto_gen_path = path.config_auto_gen
        config_auto_gen_path.mkdir(parents=True, exist_ok=True)

        os.chdir(config_auto_gen_path)
        out_file = config_auto_gen_path.joinpath('encryption-config.yaml')
        with open(out_file, 'w') as stream:
            stream.write(inspect.cleandoc(
                '''
                    kind: EncryptionConfig
                    apiVersion: v1
                    resources:
                      - resources:
                          - secrets
                        providers:
                          - aescbc:
                              keys:
                                - name: key1
                                  secret: {}
                          - identity: {{}}
                '''.format(encryption_key)
            ))


Run()
