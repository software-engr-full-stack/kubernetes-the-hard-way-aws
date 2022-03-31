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
    def __init__(self, name, config_file):
        print('# **** The Admin Kubernetes Configuration File **** #')

        config = Config(config_file)

        public_addresses = PublicAddresses(config.all_hostnames, name=name)
        path = Path()

        kubernetes_public_address = public_addresses['kubernetes']

        print(kubernetes_public_address)

        subprocess.run([
            'kubectl', 'config', 'set-cluster', name,
            '--certificate-authority={}/ca.pem'.format(path.certs),
            '--embed-certs=true',
            '--server=https://{}:{}'.format(
                kubernetes_public_address, config['network']['kube_apiserver_port']
            )
        ])

        base_name = 'admin'
        subprocess.run([
            'kubectl', 'config', 'set-credentials', base_name,
            '--client-certificate={}/{}.pem'.format(path.certs, base_name),
            '--client-key={}/{}-key.pem'.format(path.certs, base_name)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-context', name,
            '--cluster={}'.format(name),
            '--user={}'.format(base_name)
        ])

        subprocess.run(['kubectl', 'config', 'use-context', name])

        print()
        print('Verification: version')
        subprocess.run(['kubectl', 'version'])
        print()
        print('... expected output...')
        print(inspect.cleandoc(
            '''
                Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
                Server Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:25:06Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
            '''
        ))

        print()
        print('Verification: nodes')
        subprocess.run(['kubectl', 'get', 'nodes'])
        print()
        print('... expected output...')
        print(inspect.cleandoc(
            '''
                ip-10-240-0-20   Ready    <none>   91s   v1.21.0
            '''
        ))


Run(*sys.argv[1:])
