import sys
import subprocess
import json

from lib.expected import Expected


class TestVPC(object):
    def __init__(self, expected):
        result = subprocess.run([
            'aws', 'ec2', 'describe-vpcs', '--filters', 'Name=is-default,Values=false'
        ], stdout=subprocess.PIPE)

        got_vpc_list = json.loads(result.stdout)['Vpcs']

        got_vpcs_by_tag = {vpc['Tags'][0]['Value']: vpc for vpc in got_vpc_list}

        tag_value = expected.tag_value
        if tag_value not in got_vpcs_by_tag:
            raise ValueError("test failed, unable to find VPC with tag value '{}'".format(tag_value))

        got_vpc = got_vpcs_by_tag[tag_value]

        for key in ['CidrBlock', 'State']:
            got = got_vpc[key]
            exp = expected.data[key]
            if got != exp:
                raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        dns_attributes = [
            {'attrib': {'cmd': 'enableDnsSupport', 'result': 'EnableDnsSupport'}, 'exp': True},
            {'attrib': {'cmd': 'enableDnsHostnames', 'result': 'EnableDnsHostnames'}, 'exp': True}
        ]
        vpc_id = got_vpc['VpcId']
        for dns_attrib in dns_attributes:
            result = subprocess.run([
                'aws', 'ec2', 'describe-vpc-attribute',
                '--attribute', dns_attrib['attrib']['cmd'],
                '--vpc-id', vpc_id
            ], stdout=subprocess.PIPE)

            key = dns_attrib['attrib']['result']
            got = json.loads(result.stdout)[key]['Value']
            exp = True
            if got is not exp:
                raise ValueError("'{}' failed, got is not exp, '{}' is not '{}'".format(key, got, exp))

        self.id = vpc_id


class TestSubnet(object):
    def __init__(self, expected, vpc):
        tag_value = expected.tag_value
        result = subprocess.run([
            'aws', 'ec2', 'describe-subnets',
            '--filters', 'Name=tag:Name,Values={}'.format(tag_value)
        ], stdout=subprocess.PIPE)

        got_list = json.loads(result.stdout)['Subnets']

        if len(got_list) != 1:
            raise ValueError(
                "subnet count '{}' != 1 for subnets tagged as '{}'".format(len(got_list), tag_value)
            )

        got_obj = got_list[0]
        for test in [
            {'key': 'CidrBlock',           'exp': expected.data['CidrBlock']},
            {'key': 'MapPublicIpOnLaunch', 'exp': False},
            {'key': 'AvailabilityZone',    'exp': 'us-west-1a'}
        ]:
            key = test['key']
            got = got_obj[key]
            exp = test['exp']
            if got != exp:
                raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        tests = [
            {'key': 'VpcId', 'exp': vpc.id}
        ]

        for test in tests:
            key = test['key']
            got = got_obj[key]
            exp = test['exp']
            if got != exp:
                raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        self.id = got_obj['SubnetId']


class TestIG(object):
    def __init__(self, expected, vpc):
        tag_value = expected.tag_value
        result = subprocess.run([
            'aws', 'ec2', 'describe-internet-gateways',
            '--filters', 'Name=tag:Name,Values={}'.format(tag_value)
        ], stdout=subprocess.PIPE)

        got_list = json.loads(result.stdout)['InternetGateways']

        if len(got_list) != 1:
            raise ValueError(
                "subnet count '{}' != 1 for subnets tagged as '{}'".format(len(got_list), tag_value)
            )

        tests = [
            {'key': 'VpcId', 'exp': vpc.id}
        ]

        got_obj = got_list[0]
        for test in tests:
            key = test['key']
            got = got_obj['Attachments'][0][key]
            exp = test['exp']
            if got != exp:
                raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        self.id = got_obj['InternetGatewayId']


class TestRouteSetup(object):
    def __init__(self, expected, vpc, subnet, igw):
        tag_value = expected.tag_value
        result = subprocess.run([
            'aws', 'ec2', 'describe-route-tables',
            '--filters', 'Name=tag:Name,Values={}'.format(tag_value)
        ], stdout=subprocess.PIPE)

        got_list = json.loads(result.stdout)['RouteTables']

        if len(got_list) != 1:
            raise ValueError(
                "subnet count '{}' != 1 for subnets tagged as '{}'".format(len(got_list), tag_value)
            )

        got_obj = got_list[0]

        key = 'VpcId'
        got = got_obj[key]
        exp = vpc.id
        if got != exp:
            raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        key = 'SubnetId'
        got = got_obj['Associations'][0][key]
        exp = subnet.id
        if got != exp:
            raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        expected_routes_table = {
            '10.240.0.0/24': {'GatewayId': 'local'},
            '0.0.0.0/0':     {'GatewayId': igw.id}
        }

        for route in got_obj['Routes']:
            key = 'DestinationCidrBlock'
            got_dest_cidr_block = route[key]
            if got_dest_cidr_block not in expected_routes_table:
                raise ValueError(
                    "destination CIDR block '{}' not found in route table".format(got_dest_cidr_block)
                )

            key = 'GatewayId'
            got = route[key]
            exp = expected_routes_table[got_dest_cidr_block][key]
            if got != exp:
                raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))


if __name__ == '__main__':
    expected = Expected(sys.argv[1])
    vpc = TestVPC(expected)
    subnet = TestSubnet(expected, vpc)
    igw = TestIG(expected, vpc)
    TestRouteSetup(expected, vpc, subnet, igw)
