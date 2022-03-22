import sys
import subprocess
import json

from lib.expected import Expected


class TestComputeInstances(object):
    def __init__(self, expected):
        tag_value = expected.tag_value
        result = subprocess.run([
            'aws', 'ec2', 'describe-vpcs',
            '--filters', 'Name=tag:Name,Values={}'.format(tag_value),
        ], stdout=subprocess.PIPE)

        got_list = json.loads(result.stdout)['Vpcs']

        key = 'length'
        got = len(got_list)
        exp = 1
        if got != exp:
            raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        sort_by_query = 'sort_by(Reservations[].Instances[],&PrivateIpAddress)'
        before_or = 'd_INTERNAL_IP:PrivateIpAddress,e_EXTERNAL_IP:PublicIpAddress,a_NAME:Tags[?Key==`Name`].Value'
        result = subprocess.run([
            'aws', 'ec2', 'describe-instances',
            '--filters', 'Name=vpc-id,Values={}'.format(got_list[0]['VpcId']),
            '--query',
            '{}[].{{{} | [0],b_ZONE:Placement.AvailabilityZone,c_MACHINE_TYPE:InstanceType,f_STATUS:State.Name}}'.format(sort_by_query, before_or)
        ], stdout=subprocess.PIPE)

        got_list = json.loads(result.stdout)

        exp_instances = expected.data['Instances']
        exp_table_controllers = {
            ''.join([exp_instances['Controller']['Basename'], str(ix)]): exp_instances['Controller']
            for ix in range(exp_instances['Controller']['Count'])
        }

        exp_table_workers = {
            ''.join([exp_instances['Worker']['Basename'], str(ix)]): exp_instances['Worker']
            for ix in range(exp_instances['Worker']['Count'])
        }

        exp_table = {**exp_table_controllers, **exp_table_workers}

        key = 'length'
        got = len(got_list)
        exp = len(exp_table)
        if got != exp:
            raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

        for inst in got_list:
            key = 'a_NAME'
            got = inst[key]
            if got not in exp_table:
                raise ValueError(
                    "'{}' failed, got '{}' not in exp table...\n{}".format(key, got, exp_table)
                )

            exp_type = exp_table[got]

            key = 'c_MACHINE_TYPE'
            got = inst[key]
            exp = exp_type[key]
            if got != exp:
                raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

            for key in ['b_ZONE', 'f_STATUS']:
                got = inst[key]
                exp = exp_instances[key]
                if got != exp:
                    raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

            for key in ['d_INTERNAL_IP', 'e_EXTERNAL_IP']:
                got = inst[key].strip()
                if got == '':
                    raise ValueError("'{}' failed, IP should not be blank".format(key))


if __name__ == '__main__':
    expected = Expected(sys.argv[1])
    vpc = TestComputeInstances(expected)
