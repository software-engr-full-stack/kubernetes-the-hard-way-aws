import sys
import subprocess
import json
import inspect

from lib.expected import Expected


class TestFirewallRules(object):
    def __init__(self, expected):
        tag_value = expected.tag_value
        result = subprocess.run([
            'aws', 'ec2', 'describe-security-groups',
            '--filters', 'Name=tag:Name,Values={}'.format(tag_value)
        ], stdout=subprocess.PIPE)

        got_list = json.loads(result.stdout)['SecurityGroups']

        if len(got_list) != 1:
            raise ValueError(
                "subnet count '{}' != 1 for subnets tagged as '{}'".format(len(got_list), tag_value)
            )

        got_obj = got_list[0]
        sg_id = got_obj['GroupId']

        # TODO: if table ordering is inconsistent, do it the hard way.
        result = subprocess.run([
            'aws', 'ec2', 'describe-security-group-rules',
            '--filters', 'Name=group-id,Values={}'.format(sg_id),
            '--query', 'sort_by(SecurityGroupRules, &CidrIpv4)[].{a_Protocol:IpProtocol,b_FromPort:FromPort,c_ToPort:ToPort,d_Cidr:CidrIpv4}',
            '--output', 'table'

            # 'aws', 'ec2', 'describe-security-groups',
            # '--filters', 'Name=tag:Name,Values={}'.format(tag_value)
        ], stdout=subprocess.PIPE)

        exp = inspect.cleandoc('''
            -----------------------------------------------------------
            |               DescribeSecurityGroupRules                |
            +------------+-------------+-----------+------------------+
            | a_Protocol | b_FromPort  | c_ToPort  |     d_Cidr       |
            +------------+-------------+-----------+------------------+
            |  -1        |  -1         |  -1       |  0.0.0.0/0       |
            |  icmp      |  -1         |  -1       |  0.0.0.0/0       |
            |  tcp       |  22         |  22       |  0.0.0.0/0       |
            |  tcp       |  6443       |  6443     |  0.0.0.0/0       |
            |  -1        |  -1         |  -1       |  10.200.0.0/16   |
            |  -1        |  -1         |  -1       |  10.240.0.0/24   |
            +------------+-------------+-----------+------------------+''').strip()

        got = result.stdout.decode('utf-8').strip()

        if got != exp:
            raise ValueError("route table test failed, got != exp, '{}' != '{}'".format(got, exp))


if __name__ == '__main__':
    expected = Expected(sys.argv[1])
    TestFirewallRules(expected)
