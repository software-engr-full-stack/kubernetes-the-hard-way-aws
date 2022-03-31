#!/usr/bin/env python3

import sys
import pathlib
import inspect
import subprocess
import time

this_file = pathlib.Path((inspect.getfile(inspect.currentframe())))
app_dir = this_file.joinpath('..', '..', '..').resolve()
sys.path.insert(0, app_dir.as_posix())

from lib.config import Config  # noqa: E402
from lib.public_addresses import PublicAddresses  # noqa: E402


class Run(object):
    def __init__(self):
        print('# **** Nginx GET Test **** #')
        time.sleep(2)

        config = Config(app_dir.joinpath('config.yml'))

        public_addresses = PublicAddresses(config.all_hostnames)

        result = subprocess.run([
            'kubectl', 'get', 'service', 'nginx',
            '--output=jsonpath={range .spec.ports[0]}{.nodePort}'
        ], stdout=subprocess.PIPE)

        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        node_port = result.stdout.decode('utf-8')

        print(node_port)

        for host in config.workers:
            instance_name = host['hostname']
            external_ip = public_addresses[instance_name]

            result = subprocess.run(['curl', '--head', 'http://{}:{}'.format(external_ip, node_port)])
            if result.returncode != 0:
                raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

            print('... expected output...')
            print(inspect.cleandoc(
                '''
                    HTTP/1.1 200 OK
                    Server: nginx/1.19.10
                    Date: Sun, 02 May 2021 05:31:52 GMT
                    Content-Type: text/html
                    Content-Length: 612
                    Last-Modified: Tue, 13 Apr 2021 15:13:59 GMT
                    Connection: keep-alive
                    ETag: "6075b537-264"
                    Accept-Ranges: bytes
                '''
            ))


Run()
