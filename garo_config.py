import os
import sys
from enum import Enum


class SystemPlatform(Enum):
    # values are those of sys.platform on respective platforms
    WINDOWS = 'win32'
    LINUX = 'linux'
    MACOS = 'darwin'


class GaroConfig(object):
    def __init__(self) -> None:
        work_folder = '.garo_files'
        current_folder = os.path.dirname(sys.argv[0])
        self.platform = SystemPlatform(sys.platform)
        self.app_name = 'Garo'
        if getattr(sys, 'frozen', False):
            # this check does not work if windows exe compiled using Nuitka
            # for that, manually check sys.argv[0] extension
            if self.platform == SystemPlatform.WINDOWS:
                self.work_dir = os.path.join(
                    os.getenv('APPDATA', current_folder), work_folder)
            # elif self.platform == SystemPlatform.MACOS:
            # elif self.platform == SystemPlatform.LINUX:
            #     self.work_dir = {
            #     SystemPlatform.WINDOWS: os.path.join(os.getenv('APPDATA', current_folder), work_folder),
            #     SystemPlatform.LINUX: os.path.join(os.getenv('HOME', current_folder), '.local', 'share', work_folder),
            #     SystemPlatform.WINDOWS: os.path.join(os.getenv(
            #         'APPDATA', current_folder), 'Library', 'Application Support', work_folder)
            # }.get(self.platform)

            # self.pictures_folder = {
            #     SystemPlatform.WINDOWS: os.path.join(os.getenv('userprofile', current_folder), work_folder),
            #     SystemPlatform.LINUX: os.path.join(os.getenv('HOME', current_folder), '.local', 'share', work_folder),
            #     SystemPlatform.WINDOWS: os.path.join(os.getenv(
            #         'HOME', current_folder), 'Library', 'Application Support', work_folder)
            # }.get(self.platform)
        elif __file__:
            self.work_dir = os.path.join(current_folder, work_folder)

        # TODO: fetch from a user config
        self.gallery_paths = [
            os.path.join(os.getenv('userprofile'),
                         'Onedrive', 'Pictures')
        ]

        if not os.path.exists(self.work_dir):
            os.makedirs(self.work_dir, exist_ok=True)

        self.image_paths = {
            'folder': os.path.join(current_folder, 'res', 'common', 'folder.png')
        }

        # log_format = '%(asctime)s %(levelname)s %(process)d %(filename)s:%(lineno)d %(message)s'
