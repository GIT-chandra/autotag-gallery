from garo_config import GaroConfig
from garo_ui import GaroApp
from garo_core import GaroCoreDummy

cfg = GaroConfig()
core = GaroCoreDummy(cfg.gallery_paths[0])
print(vars(cfg))
app = GaroApp(core, cfg)
app.run()
