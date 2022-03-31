#!/usr/bin/env python

import subprocess
import time


class CreateNginxService(object):
    def __init__(self):
        print('# **** Create Nginx Service **** #')

        svc_name = 'nginx'
        port = 80
        if not self.__service_exists(svc_name):
            result = subprocess.run([
                'kubectl', 'expose', 'deployment', svc_name, '--port', str(port), '--type', 'NodePort'
            ])

            time.sleep(2)

            if result.returncode != 0:
                raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

    def __service_exists(self, name):
        result = subprocess.run(['kubectl', 'get', 'service', name])
        returncode = result.returncode

        if returncode == 0:
            return True

        if returncode == 1:
            return False

        raise ValueError("... ERROR: sub process return code '{}' not == to 0 or 1".format(returncode))


CreateNginxService()
