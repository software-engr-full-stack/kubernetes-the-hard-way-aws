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
from lib.create_inventory_file import CreateInventoryFile  # noqa: E402
from lib.public_addresses import PublicAddresses  # noqa: E402
from lib.path import Path  # noqa: E402


class Run(object):
    def __init__(self, name, config_file, id_file, inventory_dir):
        config = Config(config_file)

        inventory_path = pathlib.Path(inventory_dir).resolve()

        public_addresses = PublicAddresses(config.all_hostnames, name=name)
        path = Path()

        env = os.environ.copy()
        env['ANSIBLE_CONFIG'] = path.app.joinpath('ansible.cfg')

        for host in config.controllers:
            instance_name = host['hostname']
            inventory_file = inventory_path.joinpath(instance_name)
            ip_addresses = [public_addresses[instance_name]]
            print("... creating inventory file '{}' for IPs '{}'...".format(inventory_file, ip_addresses))
            CreateInventoryFile(ip_addresses, inventory_file)

            subprocess.run([
                'ansible-playbook',
                '--inventory-file', inventory_file,
                '--extra-vars', 'id_file={}'.format(id_file),
                '--extra-vars', 'rem_usr={}'.format(config['remote_user']),
                '--extra-vars', 'certs_path={}'.format(path.certs),
                '--extra-vars', 'internal_ip={}'.format(host['internal_ip']),
                '--extra-vars', 'kubernetes_public_address={}'.format(public_addresses['kubernetes']),
                '--extra-vars', 'kube_apiserver_port={}'.format(config['network']['kube_apiserver_port']),
                '--extra-vars', 'service_cluster_ip_range={}'.format(config['network']['service_cluster_ip_range']),
                '--extra-vars', 'pod_cidr_block={}'.format(config['network']['pod_cidr_block']),
                '--extra-vars', 'config_auto_gen_path={}'.format(path.config_auto_gen),
                this_file.parent.joinpath('playbook-controller-1.yml')
            ], env=env)


Run(*sys.argv[1:])
