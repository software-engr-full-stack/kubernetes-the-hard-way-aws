import yaml


class Expected(object):
    def __init__(self, exp_file):
        with open(exp_file, 'r') as stream:
            try:
                data = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                raise yaml.YAMLError('YAML error: {}'.format(exc))

        self.data = data
        self.tag_value = data['Tag']['Value']
