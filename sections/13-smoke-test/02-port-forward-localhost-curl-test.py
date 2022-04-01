#!/usr/bin/env python

import subprocess
import time
import os
import signal
import inspect


class PortForwardLocalHostCurlTest(object):
    def __init__(self):
        print('# **** Forward port 80 to localhost:8080 then GET-check localhost:8080 **** #')
        result = subprocess.run([
            'kubectl', 'get', 'pods',
            '--selector', 'app=nginx',
            '--output', 'jsonpath={.items[0].metadata.name}'
        ], stdout=subprocess.PIPE)

        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        pod_name = result.stdout.decode('utf-8')

        # Delay because "error: unable to forward port because pod is not running. Current status=Pending"
        time.sleep(4)

        port_forward_proc = subprocess.Popen(['kubectl', 'port-forward', pod_name, '8080:80'])
        print("... port forward process '{}'...".format(port_forward_proc.pid))
        print(port_forward_proc)
        time.sleep(2)

        if port_forward_proc.returncode and port_forward_proc.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(port_forward_proc.returncode))

        result = subprocess.run(['curl', '--head', 'http://127.0.0.1:8080'])
        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        print('... expected output...')
        print(inspect.cleandoc(
            '''
                HTTP/1.1 200 OK
                Server: nginx/1.19.10
                Date: Sun, 02 May 2021 05:29:25 GMT
                Content-Type: text/html
                Content-Length: 612
                Last-Modified: Tue, 13 Apr 2021 15:13:59 GMT
                Connection: keep-alive
                ETag: "6075b537-264"
                Accept-Ranges: bytes
            '''
        ))

        os.kill(port_forward_proc.pid, signal.SIGTERM)  # Or signal.SIGKILL


PortForwardLocalHostCurlTest()
