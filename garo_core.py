
import os
from abc import ABC, abstractmethod


class GaroCoreBase(ABC):
    def __init__(self, root_dir: str) -> None:
        self.root_dir = root_dir
        self.current_location = root_dir
        super().__init__()

    def get_contents(self):
        if not os.path.exists(self.current_location):
            return []
        return [os.path.join(self.current_location, x) for x in os.listdir(self.current_location)]


class GaroCoreDummy(GaroCoreBase):
    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
