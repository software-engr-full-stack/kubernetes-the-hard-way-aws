#!/usr/bin/env python3

import sys
import subprocess
import json


class PublicAddresses(object):
    def __init__(self, hostnames):
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

        self.__data = data

    def __getitem__(self, key):
        return self.__data[key]


if __name__ == '__main__':
    PublicAddresses(sys.argv[1:])
