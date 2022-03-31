#!/usr/bin/env python3

import sys
import pathlib
import inspect
import subprocess

this_file = pathlib.Path((inspect.getfile(inspect.currentframe())))
app_dir = this_file.joinpath('..', '..').resolve()
sys.path.insert(0, app_dir.as_posix())

from lib.config import Config  # noqa: E402
from lib.path import Path  # noqa: E402


class Run(object):
    def __init__(self, op):
        config = Config(app_dir.joinpath('config.yml'))

        name = config['name']
        path = Path()

        secrets_path = path.secrets
        secrets_path.mkdir(parents=True, exist_ok=True)

        id_file = secrets_path.joinpath(config['id_file_bname'])

        op_table = {
            'create': [name, id_file, config['id_file_ktype']],
            'destroy': [name, id_file]
        }
        if op not in op_table:
            raise ValueError("... ERROR: invalid op '{}', valid ops...\n{}".format(op, op_table))

        args = op_table[op]

        method = getattr(self, op)
        method(*args)

    def create(self, name, id_file, key_type):
        if id_file.is_file():
            print('... id file already exists, exiting...')
            sys.exit()

        result = subprocess.run([
            'aws', 'ec2', 'create-key-pair',
            '--key-name', name,
            '--key-type', key_type,
            '--query', 'KeyMaterial',
            '--output', 'text'
        ], stdout=subprocess.PIPE)

        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        id_data = result.stdout.decode('utf-8')

        with open(id_file, 'w') as stream:
            stream.write(id_data)

        id_file.chmod(0o600)

    def destroy(self, name, id_file):
        result = subprocess.run(
            ['aws', 'ec2', 'delete-key-pair', '--key-name', name],
            stdout=subprocess.PIPE
        )

        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        id_file.unlink()


Run(sys.argv[1])
