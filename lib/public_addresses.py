#!/usr/bin/env python3

import sys
import subprocess
import json


class PublicAddresses(object):
    def __init__(self, name, hostnames):
        if len(hostnames) < 1:
            raise ValueError('... ERROR: must pass at least 1 hostname')

        tag_values = ','.join(hostnames)
        result = subprocess.run([
            'aws', 'ec2', 'describe-instances',
            '--filter',
            'Name=tag:Name,Values={}'.format(tag_values),
            'Name=instance-state-name,Values=running',
            '--query=Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],PublicIpAddress]'
        ], stdout=subprocess.PIPE)

        data = {
            item[0]: item[1] for item in json.loads(result.stdout)
        }

        for given_hn in hostnames:
            if given_hn not in data:
                raise ValueError(
                    "... ERROR: given hostname '{}' not in provisioned hosts table...\n{}".format(
                        given_hn,
                        data
                    )
                )

        result = subprocess.run([
            'aws', 'ec2', 'describe-addresses',
            '--filter',
            'Name=tag:Name,Values={}'.format(name),
            '--query', 'Addresses[0].PublicIp',
            '--output', 'text'
        ], stdout=subprocess.PIPE)

        public_ip = result.stdout.decode('utf-8').strip()
        if public_ip.strip() == '' or public_ip == 'None':
            raise ValueError("... ERROR: public IP for '{}' not found".format(name))

        self.__data = {**data, 'kubernetes': public_ip}

    def __getitem__(self, key):
        if key not in self.__data:
            raise ValueError(
                "... ERROR: given hostname '{}' not in provisioned hosts table...\n{}".format(
                    key,
                    self.__data
                )
            )
        return self.__data[key]


if __name__ == '__main__':
    PublicAddresses(sys.argv[1:])
