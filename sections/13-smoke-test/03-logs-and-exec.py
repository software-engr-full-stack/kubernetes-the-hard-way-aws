#!/usr/bin/env python

import sys
import pathlib
import inspect
import subprocess

this_file = pathlib.Path((inspect.getfile(inspect.currentframe())))
app_dir = this_file.joinpath('..', '..', '..').resolve()
sys.path.insert(0, app_dir.as_posix())

from lib.config import Config  # noqa: E402


class PortForwardLocalHostCurlTest(object):
    def __init__(self):
        print('# **** Logs and Exec **** #')

        config = Config(app_dir.joinpath('config.yml'))

        print(config)

        print('---- Logs ----')
        result = subprocess.run([
            'kubectl', 'get', 'pods',
            '--selector', 'app=nginx',
            '--output', 'jsonpath={.items[0].metadata.name}'
        ], stdout=subprocess.PIPE)

        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        pod_name = result.stdout.decode('utf-8')

        result = subprocess.run(['kubectl', 'logs', pod_name])
        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        print()
        print('... expected output...')
        print(inspect.cleandoc(
            '''
                2022/03/31 18:38:08 [notice] 1#1: start worker processes
                2022/03/31 18:38:08 [notice] 1#1: start worker process 30
                127.0.0.1 - - [31/Mar/2022:19:01:52 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.68.0" "-"
                127.0.0.1 - - [31/Mar/2022:19:02:11 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.68.0" "-"
                127.0.0.1 - - [31/Mar/2022:19:02:17 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.68.0" "-"
            '''
        ))

        print()
        print('---- Exec ----')
        result = subprocess.run(['kubectl', 'exec', '-ti', pod_name, '--', 'nginx', '-v'])
        print()
        print('... expected output...')
        print(inspect.cleandoc(
            '''
                nginx version: nginx/1.19.10
            '''
        ))


PortForwardLocalHostCurlTest()
