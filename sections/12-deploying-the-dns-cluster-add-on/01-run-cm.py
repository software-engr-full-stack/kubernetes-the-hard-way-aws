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
    def __init__(self):
        config = Config(app_dir.joinpath('config.yml'))

        name = config['name']
        inventory_dir = config['inventory_dir']

        inventory_path = pathlib.Path(inventory_dir).resolve()

        public_addresses = PublicAddresses(config.all_hostnames, name=name)
        path = Path()

        id_file = path.secrets.joinpath(config['id_file_bname'])

        env = os.environ.copy()
        env['ANSIBLE_CONFIG'] = path.app.joinpath('ansible.cfg')

        for host in config.workers:
            instance_name = host['hostname']
            inventory_file = inventory_path.joinpath(instance_name)
            ip_addresses = [public_addresses[instance_name]]
            print("... creating inventory file '{}' for IPs '{}'...".format(inventory_file, ip_addresses))
            CreateInventoryFile(ip_addresses, inventory_file)

            result = subprocess.run([
                'ansible-playbook',
                '--inventory-file', inventory_file,
                '--extra-vars', 'id_file={}'.format(id_file),
                '--extra-vars', 'rem_usr={}'.format(config['remote_user']),
                '--extra-vars', 'app_name={}'.format(name),
                this_file.parent.joinpath('playbook-worker-fix-dns-nat-issue.yml')
            ], env=env)

            if result.returncode != 0:
                raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))


Run()
