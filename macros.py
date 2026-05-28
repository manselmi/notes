# vim: set ft=python :
#
# https://mkdocs-macros-plugin.readthedocs.io/en/stable/macros/


import tomllib
from pathlib import Path


PATH_SEP = "/"
with Path(__file__).with_name("zensical.toml").open(mode="rb") as file:
    ZENSICAL_CONFIG = tomllib.load(file)


def define_env(env):
    """
    https://mkdocs-macros-plugin.readthedocs.io/en/stable/macros/#the-define_env-function
    """

    @env.macro
    def prefix_repo_url(s):
        url = [ZENSICAL_CONFIG["project"]["repo_url"].rstrip(PATH_SEP)]
        if s.endswith(PATH_SEP):
            url.append("tree")
        else:
            url.append("blob")
        url.extend(["main", s])
        return PATH_SEP.join(url)
