# vim: set ft=python :


from pathlib import Path

c = get_config()  # noqa:F821

c.ExtensionApp.open_browser = False
c.FileContentsManager.preferred_dir = "Documents/Jupyter"
c.IdentityProvider.token = ""
c.KernelSpecManager.ensure_native_kernel = False
c.ServerApp.ip = "localhost"
c.ServerApp.local_hostnames = ["localhost"]
c.ServerApp.open_browser = False
c.ServerApp.port = 8888
c.ServerApp.port_retries = 0
c.ServerApp.root_dir = str(Path.home())
