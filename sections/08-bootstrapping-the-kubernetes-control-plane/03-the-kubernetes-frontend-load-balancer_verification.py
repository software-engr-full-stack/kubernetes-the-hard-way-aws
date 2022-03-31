#!/usr/bin/env python3

import sys
import pathlib
import inspect
import subprocess

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

        result = subprocess.run([
            'curl',
            '--cacert', path.certs.joinpath('ca.pem'),
            'https://{}:{}/version'.format(
                public_addresses['kubernetes'], config['network']['kube_apiserver_port']
            )
        ])

        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        print('.. expected output...')
        print(inspect.cleandoc(
            '''
                {
                  "major": "1",
                  "minor": "21",
                  "gitVersion": "v1.21.0",
                  "gitCommit": "cb303e613a121a29364f75cc67d3d580833a7479",
                  "gitTreeState": "clean",
                  "buildDate": "2021-04-08T16:25:06Z",
                  "goVersion": "go1.16.1",
                  "compiler": "gc",
                  "platform": "linux/amd64"
                }
            '''
        ))


Run()
