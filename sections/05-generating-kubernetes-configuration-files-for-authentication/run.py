#!/usr/bin/env python3

import sys
import pathlib
import os
import inspect
import subprocess

this_file = pathlib.Path((inspect.getfile(inspect.currentframe())))
app_dir = this_file.joinpath('..', '..', '..').resolve()
sys.path.insert(0, app_dir.as_posix())

from lib.config import Config  # noqa: E402
from lib.public_addresses import PublicAddresses  # noqa: E402
from lib.path import Path  # noqa: E402


class Run(object):
    def __init__(self, name, config_file, id_file):
        config = Config(config_file)

        public_addresses = PublicAddresses(config.all_hostnames, name=name)
        path = Path()

        certs_path = path.certs
        certs_path.mkdir(parents=True, exist_ok=True)

        config_auto_gen_path = path.config_auto_gen
        config_auto_gen_path.mkdir(parents=True, exist_ok=True)

        kubernetes_public_address = public_addresses['kubernetes']

        os.chdir(config_auto_gen_path)

        ca_file = '{}/ca.pem'.format(certs_path)
        kube_apiserver_port = config['kube_apiserver_port']
        kube_apiserver = 'https://{}:{}'.format(
            kubernetes_public_address,
            kube_apiserver_port
        )
        localhost_kube_apiserver = 'https://127.0.0.1:{}'.format(kube_apiserver_port)

        print('#### Client Authentication Configs ####')

        print('# **** The kubelet Kubernetes Configuration File **** #')
        for host in config.workers:
            instance_name = host['hostname']
            aws_hostname = host['aws_hostname']
            kubeconfig_file = config_auto_gen_path.joinpath('{}.kubeconfig'.format(instance_name))

            subprocess.run([
                'kubectl', 'config', 'set-cluster', name,
                '--certificate-authority={}'.format(ca_file),
                '--embed-certs=true',
                '--server={}'.format(kube_apiserver),
                '--kubeconfig={}'.format(kubeconfig_file)
            ])

            subprocess.run([
                'kubectl', 'config', 'set-credentials', 'system:node:{}'.format(aws_hostname),
                '--client-certificate={}/{}.pem'.format(certs_path, instance_name),
                '--client-key={}/{}-key.pem'.format(certs_path, instance_name),
                '--embed-certs=true',
                '--kubeconfig={}'.format(kubeconfig_file)
            ])

            subprocess.run([
                'kubectl', 'config', 'set-context', 'default',
                '--cluster={}'.format(name),
                '--user=system:node:{}'.format(aws_hostname),
                '--kubeconfig={}'.format(kubeconfig_file)
            ])

            subprocess.run([
                'kubectl', 'config', 'use-context', 'default',
                '--kubeconfig={}'.format(kubeconfig_file)
            ])

        print('# **** The kube-proxy Kubernetes Configuration File **** #')
        base_name = 'kube-proxy'
        config_file = config_auto_gen_path.joinpath('{}.kubeconfig'.format(base_name))
        subprocess.run([
            'kubectl', 'config', 'set-cluster', name,
            '--certificate-authority={}'.format(ca_file),
            '--embed-certs=true',
            '--server={}'.format(kube_apiserver),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-credentials', 'system:{}'.format(base_name),
            '--client-certificate={}'.format(certs_path.joinpath('{}.pem'.format(base_name))),
            '--client-key={}'.format(certs_path.joinpath('{}-key.pem'.format(base_name))),
            '--embed-certs=true',
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-context', 'default',
            '--cluster={}'.format(name),
            '--user=system:{}'.format(base_name),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'use-context', 'default',
            '--kubeconfig={}'.format(config_file)
        ])

        print('# **** The kube-controller-manager Kubernetes Configuration File **** #')
        base_name = 'kube-controller-manager'
        config_file = config_auto_gen_path.joinpath('{}.kubeconfig'.format(base_name))
        subprocess.run([
            'kubectl', 'config', 'set-cluster', name,
            '--certificate-authority={}'.format(ca_file),
            '--embed-certs=true',
            '--server={}'.format(localhost_kube_apiserver),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-credentials', 'system:{}'.format(base_name),
            '--client-certificate={}'.format(certs_path.joinpath('{}.pem'.format(base_name))),
            '--client-key={}'.format(certs_path.joinpath('{}-key.pem'.format(base_name))),
            '--embed-certs=true',
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-context', 'default',
            '--cluster={}'.format(name),
            '--user=system:{}'.format(base_name),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'use-context', 'default',
            '--kubeconfig={}'.format(config_file)
        ])

        print('# **** The kube-scheduler Kubernetes Configuration File **** #')
        base_name = 'kube-scheduler'
        config_file = config_auto_gen_path.joinpath('{}.kubeconfig'.format(base_name))
        subprocess.run([
            'kubectl', 'config', 'set-cluster', name,
            '--certificate-authority={}'.format(ca_file),
            '--embed-certs=true',
            '--server={}'.format(localhost_kube_apiserver),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-credentials', 'system:{}'.format(base_name),
            '--client-certificate={}'.format(certs_path.joinpath('{}.pem'.format(base_name))),
            '--client-key={}'.format(certs_path.joinpath('{}-key.pem'.format(base_name))),
            '--embed-certs=true',
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-context', 'default',
            '--cluster={}'.format(name),
            '--user=system:{}'.format(base_name),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'use-context', 'default',
            '--kubeconfig={}'.format(config_file)
        ])

        print('# **** The admin Kubernetes Configuration File **** #')
        base_name = 'admin'
        config_file = config_auto_gen_path.joinpath('{}.kubeconfig'.format(base_name))
        subprocess.run([
            'kubectl', 'config', 'set-cluster', name,
            '--certificate-authority={}'.format(ca_file),
            '--embed-certs=true',
            '--server={}'.format(localhost_kube_apiserver),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-credentials', base_name,
            '--client-certificate={}'.format(certs_path.joinpath('{}.pem'.format(base_name))),
            '--client-key={}'.format(certs_path.joinpath('{}-key.pem'.format(base_name))),
            '--embed-certs=true',
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'set-context', 'default',
            '--cluster={}'.format(name),
            '--user={}'.format(base_name),
            '--kubeconfig={}'.format(config_file)
        ])

        subprocess.run([
            'kubectl', 'config', 'use-context', 'default',
            '--kubeconfig={}'.format(config_file)
        ])


Run(sys.argv[1], sys.argv[2], sys.argv[3])
