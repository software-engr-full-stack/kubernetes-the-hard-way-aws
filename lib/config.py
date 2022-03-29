#!/usr/bin/env python3

import argparse
import yaml
import json


class Config(object):
    def __init__(self, config_file):
        with open(config_file, 'r') as stream:
            try:
                data = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                raise yaml.YAMLError('YAML error: {}'.format(exc))

        self.organization = data['organization']
        self.controllers = data['controllers']
        self.workers = data['workers']

        self.controller_aws_hostnames = [
            host['aws_hostname'] for host in self.controllers
        ]

        self.controller_internal_ips = [
            host['internal_ip'] for host in self.controllers
        ]

        self.controller_hostnames = [host['hostname'] for host in self.controllers]
        self.worker_hostnames = [host['hostname'] for host in self.workers]

        self.all_hostnames = [*self.controller_hostnames, *self.worker_hostnames]

        self.data = data

    def __getitem__(self, key):
        if key not in self.data:
            raise ValueError(
                "... ERROR: config key '{}' not in config table...\n{}".format(
                    key,
                    self.data
                )
            )
        return self.data[key]

    def list_to_dict(self, list, key='internal_ip'):
        return {item[key]: item for item in list}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Config')

    parser.add_argument(
        '-c', '--config-file',
        dest='config_file',
        required=True,
        help='the config file'
    )

    parser.add_argument(
        '-t', '--key',
        dest='key',
        help='the key for the config data'
    )

    default_output_type = 'json'
    parser.add_argument(
        '-o', '--output-type',
        dest='output_type',
        default='json',
        help='output type: default "{}"'.format(default_output_type)
    )

    parser.add_argument(
        '-s', '--shape',
        dest='shape',
        default='None => list',
        help='data shape whether list or dictionary'
    )

    args = parser.parse_args()

    config = Config(args.config_file)

    output = config[args.key] if args.key else config
    shaped = config.list_to_dict(output) if args.shape == 'dict' else output
    fmatted = json.dumps(shaped) if args.output_type == default_output_type else shaped

    print(fmatted)
