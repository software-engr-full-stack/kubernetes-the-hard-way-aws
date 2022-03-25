# # TODO

# import sys
# import subprocess
# import json

# from lib.expected import Expected


# class TestFirewallRules(object):
#     def __init__(self, expected):
#         tag_value = expected.tag_value
#         result = subprocess.run([
#             'aws', 'ec2', 'describe-security-groups',
#             '--filters', 'Name=tag:Name,Values={}'.format(tag_value)
#         ], stdout=subprocess.PIPE)

#         got_list = json.loads(result.stdout)['SecurityGroups']

#         if len(got_list) != 1:
#             raise ValueError(
#                 "subnet count '{}' != 1 for subnets tagged as '{}'".format(len(got_list), tag_value)
#             )

#         got_obj = got_list[0]
#         sg_id = got_obj['GroupId']

#         result = subprocess.run([
#             'aws', 'ec2', 'describe-security-group-rules',
#             '--filters', 'Name=group-id,Values={}'.format(sg_id),
#             '--query', 'sort_by(SecurityGroupRules, &CidrIpv4)[].{a_Protocol:IpProtocol,b_FromPort:FromPort,c_ToPort:ToPort,d_Cidr:CidrIpv4}'
#         ], stdout=subprocess.PIPE)

#         got_list = json.loads(result.stdout)
#         exp_table = expected.data['SecurityGroupRules']

#         key = 'length'
#         got = len(got_list)
#         exp = len(exp_table)
#         if got != exp:
#             raise ValueError("'{}' failed, got != exp, '{}' != '{}'".format(key, got, exp))

#         key = 'route key'
#         for got_rte in got_list:
#             got = ':'.join([
#                 str(got_rte['a_Protocol']),
#                 str(got_rte['b_FromPort']),
#                 str(got_rte['c_ToPort']),
#                 str(got_rte['d_Cidr'])
#             ])
#             if got not in exp_table:
#                 raise ValueError(
#                     "'{}' failed, got '{}' not in exp table...\n{}".format(key, got, exp_table)
#                 )


# if __name__ == '__main__':
#     expected = Expected(sys.argv[1])
#     TestFirewallRules(expected)
