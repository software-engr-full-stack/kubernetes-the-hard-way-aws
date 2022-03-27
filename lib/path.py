import pathlib
import inspect


class Path(object):
    def __init__(self):
        this_file = pathlib.Path((inspect.getfile(inspect.currentframe())))
        app_dir = this_file.joinpath('..', '..').resolve()

        self.app = app_dir
        self.secrets = app_dir.joinpath('secrets')

        self.certs = self.secrets.joinpath('test-certs')
        self.config_auto_gen = self.secrets.joinpath('test-config-auto-gen')
