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

        self.controller_aws_hostnames = [
            host['aws_hostname'] for host in self.controllers
        ]

        self.controller_internal_ips = [
            host['internal_ip'] for host in self.controllers
        ]

        self.controller_hostnames = [host['hostname'] for host in self.controllers]
        self.worker_hostnames = [host['hostname'] for host in self.workers]

        self.all_hostnames = [*self.controller_hostnames, *self.worker_hostnames]

        self.__data = data

    def __getitem__(self, key):
        if key not in self.__data:
            raise ValueError(
                "... ERROR: config key '{}' not in config table...\n{}".format(
                    key,
                    self.__data
                )
            )
        return self.__data[key]
