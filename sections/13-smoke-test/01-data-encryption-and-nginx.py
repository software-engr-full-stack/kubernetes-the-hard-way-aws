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
from lib.path import Path  # noqa: E402


class Run(object):
    def __init__(self, name, config_file, id_file):
        DataEncryption(name, config_file, id_file)
        Deployments()


class DataEncryption(object):
    def __init__(self, name, config_file, id_file):
        print('**** Data Encryption ****')

        if not self.__secret_exists(name):
            self.__create_secret(name)
            result = subprocess.run([
                'kubectl', 'create', 'secret', 'generic', name,
                '--from-literal=mykey=mydata'
            ])

            if result.returncode != 0:
                raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        config = Config(config_file)

        public_addresses = PublicAddresses(config.all_hostnames, name=name)

        host = config.controllers[0]
        instance_name = host['hostname']
        result = subprocess.run([
            'ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null',
            '-i', id_file, '{}@{}'.format(config['remote_user'], public_addresses[instance_name]),
            inspect.cleandoc(
                '''
                    sudo ETCDCTL_API=3 etcdctl get \
                    --endpoints=https://127.0.0.1:2379 \
                    --cacert=/etc/etcd/ca.pem \
                    --cert=/etc/etcd/kubernetes.pem \
                    --key=/etc/etcd/kubernetes-key.pem\
                    /registry/secrets/default/{} | hexdump -C
                '''.format(name)
            )
        ])
        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        print()
        print('... expected output...')
        print(inspect.cleandoc(
            '''
                00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
                00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
                00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
                00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
                00000040  3a 76 31 3a 6b 65 79 31  3a 97 d1 2c cd 89 0d 08  |:v1:key1:..,....|
                00000050  29 3c 7d 19 41 cb ea d7  3d 50 45 88 82 a3 1f 11  |)<}.A...=PE.....|
                00000060  26 cb 43 2e c8 cf 73 7d  34 7e b1 7f 9f 71 d2 51  |&.C...s}4~...q.Q|
                00000070  45 05 16 e9 07 d4 62 af  f8 2e 6d 4a cf c8 e8 75  |E.....b...mJ...u|
                00000080  6b 75 1e b7 64 db 7d 7f  fd f3 96 62 e2 a7 ce 22  |ku..d.}....b..."|
                00000090  2b 2a 82 01 c3 f5 83 ae  12 8b d5 1d 2e e6 a9 90  |+*..............|
                000000a0  bd f0 23 6c 0c 55 e2 52  18 78 fe bf 6d 76 ea 98  |..#l.U.R.x..mv..|
                000000b0  fc 2c 17 36 e3 40 87 15  25 13 be d6 04 88 68 5b  |.,.6.@..%.....h[|
                000000c0  a4 16 81 f6 8e 3b 10 46  cb 2c ba 21 35 0c 5b 49  |.....;.F.,.!5.[
            '''
        ))

    def __secret_exists(self, name):
        result = subprocess.run(['kubectl', 'get', 'secrets', name])
        returncode = result.returncode

        if returncode == 0:
            return True

        if returncode == 1:
            return False

        raise ValueError("... ERROR: sub process return code '{}' not == to 0 or 1".format(returncode))


class Deployments(object):
    def __init__(self):
        print()
        print('# **** Deployments **** #')

        dep_name = 'nginx'

        if not self.__deployment_exists(dep_name):
            result = subprocess.run(['kubectl', 'create', 'deployment', dep_name, '--image={}'.format(dep_name)])
            if result.returncode != 0:
                raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

            delay = 5
            print("... sleeping for '{}' seconds...".format(delay))
            time.sleep(delay)

        result = subprocess.run(['kubectl', 'get', 'pods', '--selector', 'app={}'.format(dep_name)])
        if result.returncode != 0:
            raise ValueError("... ERROR: sub process return code '{}' != 0".format(result.returncode))

        print()
        print('... expected output...')
        print(inspect.cleandoc(
            '''
                NAME                    READY   STATUS    RESTARTS   AGE
                nginx-f89759699-kpn5m   1/1     Running   0          10s
            '''
        ))

    def __deployment_exists(self, name):
        result = subprocess.run(['kubectl', 'get', 'deployments', name], stdout=subprocess.DEVNULL)
        returncode = result.returncode

        if returncode == 0:
            return True

        if returncode == 1:
            return False

        raise ValueError("... ERROR: sub process return code '{}' not == to 0 or 1".format(returncode))


Run(*sys.argv[1:])
