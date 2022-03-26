#!/usr/bin/env python3

import sys

from lib.public_addresses import PublicAddresses


class Build(object):
    def __init__(self, hostnames):
        if len(hostnames) < 1:
            raise ValueError('... ERROR: must pass at least 1 hostname')

        public_addresses = PublicAddresses(hostnames)
        print(public_addresses)


if __name__ == '__main__':
    Build(sys.argv[1:])
