#!/usr/bin/env python3

import argparse
import sys
import pathlib

from config import Config
from public_addresses import PublicAddresses


class CreateInventoryFile(object):
    def __init__(self):
        parser = argparse.ArgumentParser(description='Create inventory file')

        parser.add_argument(
            '-c', '--config-file',
            dest='config_file',
            required=True,
            help='the config file'
        )

        parser.add_argument(
            '-t', '--host-type',
            dest='host_type',
            required=True,
            help='host type whether controller or worker'
        )

        parser.add_argument(
            '-o', '--inventory-file',
            dest='inventory_file',
            required=True,
            help='the output file'
        )

        args = parser.parse_args()

        config = Config(args.config_file)

        public_addresses = PublicAddresses(config.all_hostnames)

        host_type_table = {
            'controller': config.controller_hostnames,
            'worker': config.worker_hostnames
        }
        if args.host_type not in host_type_table:
            raise ValueError(
                "... ERROR: invalid host type '{}', valid host types...\n{}".format(
                    args.host_type, host_type_table
                )
            )

        ips = [public_addresses[hname] for hname in host_type_table[args.host_type]]

        this_dir = pathlib.Path(__file__).parent.resolve()
        template_file = this_dir.joinpath('inventory.template')

        inventory_file = pathlib.Path(args.inventory_file).resolve()
        inventory_file.parent.mkdir(parents=True, exist_ok=True)

        with open(template_file, 'r') as fh:
            template_str = fh.read()

        with open(inventory_file, 'w') as fh:
            fh.write(template_str.format(remote_ips="\n".join(ips)))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise ValueError('... ERROR: must pass remote IPs')

    CreateInventoryFile()
