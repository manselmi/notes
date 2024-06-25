# vim: set ft=python :
#
# https://mkdocs-macros-plugin.readthedocs.io/en/stable/macros/


def define_env(env):
    """
    https://mkdocs-macros-plugin.readthedocs.io/en/stable/macros/#the-define_env-function
    """

    @env.macro
    def prefix_repo_url(s):
        url = [env.conf["repo_url"]]
        if s.endswith("/"):
            url.append("tree")
        else:
            url.append("blob")
        url.extend(["main", s])
        return "/".join(url)
