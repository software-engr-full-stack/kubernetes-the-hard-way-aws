#!/usr/bin/env python3

import argparse
import pathlib
import re


class CreateInventoryFile(object):
    def __init__(self, ip_addresses, inventory_file):
        this_dir = pathlib.Path(__file__).parent.resolve()
        template_file = this_dir.joinpath('inventory.template')

        inventory_file = pathlib.Path(inventory_file).resolve()
        inventory_file.parent.mkdir(parents=True, exist_ok=True)

        with open(template_file, 'r') as fh:
            template_str = fh.read()

        with open(inventory_file, 'w') as fh:
            fh.write(template_str.format(remote_ips="\n".join(ip_addresses)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Create inventory file')

    parser.add_argument(
        '-i', '--ip-addresses',
        dest='ip_addresses',
        required=True,
        help='IP addresses separated by space'
    )

    parser.add_argument(
        '-o', '--inventory-file',
        dest='inventory_file',
        required=True,
        help='the output file'
    )

    args = parser.parse_args()

    CreateInventoryFile(re.split(r'\s+', args.ip_addresses), args.inventory_file)
