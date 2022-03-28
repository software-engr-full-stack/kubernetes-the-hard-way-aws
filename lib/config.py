import yaml


class Config(object):
    def __init__(self, config_file):
        with open(config_file, 'r') as stream:
            try:
                data = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                raise yaml.YAMLError('YAML error: {}'.format(exc))

        self.organization = data['organization']
        self.controllers = data['controllers']
        self.workers = data['workers']

        self.all_hostnames = [
            host['hostname'] for host in [*self.controllers, *self.workers]
        ]

        self.controller_aws_hostnames = [
            host['aws_hostname'] for host in self.controllers
        ]
