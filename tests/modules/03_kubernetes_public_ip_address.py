import sys
import subprocess
import json

from lib.expected import Expected


class TestK9PublicIPAddresses(object):
    def __init__(self, expected):
        tag_value = expected.tag_value
        result = subprocess.run([
            'aws', 'ec2', 'describe-addresses',
            '--filters', 'Name=tag:Name,Values={}'.format(tag_value)
        ], stdout=subprocess.PIPE)

        got_list = json.loads(result.stdout)['Addresses']

        if len(got_list) != 1:
            raise ValueError(
                "subnet count '{}' != 1 for subnets tagged as '{}'".format(len(got_list), tag_value)
            )

        got_obj = got_list[0]

        key = 'Domain'
        got = got_obj[key]
        exp = 'vpc'

        if got != exp:
            raise ValueError("route table test failed, got != exp, '{}' != '{}'".format(got, exp))


if __name__ == '__main__':
    expected = Expected(sys.argv[1])
    TestK9PublicIPAddresses(expected)
