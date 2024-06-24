---
tags:
  - launchd
  - mermaid
  - python
---

# devpi

## Project URL

[devpi](https://devpi.net/docs/devpi/devpi/stable/%2Bd/index.html)

## Introduction

devpi lets you host one or more Python package indexes locally. The following diagram and examples
demonstrate how pip will work after following the instructions on this page.

``` mermaid
flowchart TB

  subgraph internet ["Internet"]
    pypi-pub[("PyPI\n(Python Package Index)")]
  end

  subgraph intranet ["Intranet"]
    internal-art[("python-local\n(Artifactory repo)")]
  end

  subgraph devpi ["devpi"]
    pypi-devpi[\"pypi\n(pass-through)"/]
    internal-devpi[("python-local\n(cache)")]
    local[("local")]

    pypi-devpi & internal-devpi --> local
  end

  pypi-pub --> pypi-devpi
  internal-art --> internal-devpi

  local --> pip
```

Two examples of how this will work:

* `pip install -- numpy`

    1. pip searches devpi's `local` index for a package named `numpy`.

    1. devpi doesn't find `numpy` in the `local` devpi index, so devpi searches the `pypi` and
       `python-local` devpi indexes.

    1. The `pypi` devpi index searches the PyPI index on the Internet. `numpy` is found but is not
       cached locally.

    1. The `python-local` devpi index searches the `python-local` Artifactory index within the
       intranet. `numpy` is not found.

         * Even if the intranet is not available, the result is the same: `numpy` is not found.

    1. The `numpy` found via the `pypi` devpi index has a greater version string than the `numpy`
       found via the `python-local` devpi index (vacuously true since the `python-local`
       devpi index could not find _any_ version of `numpy`), so the `numpy` found via the `pypi`
       devpi index is served to the `local` devpi index.

    1. devpi's `local` index serves `numpy` to pip.

* `pip install -- private-package`

    1. pip searches devpi's `local` index for a package named `private-package`.

    1. devpi doesn't find `private-package` in the `local` devpi index, so devpi searches the `pypi`
       and `python-local` devpi indexes.

    1. The `pypi` devpi index searches the the PyPI index on the Internet. `private-package` is not
       found.

    1. The `python-local` devpi index searches the `python-local` Artifactory index within the
       intranet.

        * If the intranet is available, the latest version of `private-package` is found and is
          cached locally.

        * If the intranet is not available, a cached copy of the latest version of `private-package`
          previously downloaded is found.

            * If `private-package` has never been downloaded before, then `private-package` is not
              found and we stop here, with pip reporting that `private-package` could not be found.

    1. The `private-package` found via the `python-local` devpi index has a greater version string
       than the `private-package` found via the `pypi` devpi index (vacuously true since the `pypi`
       devpi index could not find _any_ version of `private-package`), so the `private-package`
       found via the `python-local` devpi index is served to the `local` devpi index.

    1. devpi's `local` index serves `private-package` to pip.

Please note that if both PyPI and the `python-local` Artifactory repo both have a package with the
same name, then devpi will fetch the package with the greatest version string.

For this reason, internal Python package names should have an org-specific prefix such as `foo.` to
reduce the likelihood of name collisions with public Python package names. Please see my [Python
library template](https://github.com/manselmi/python-library-template#readme) for a project template
that enforces such a prefix.

## Installation instructions

First, install Micromamba or Miniconda. I use Micromamba so you'll see it referenced in upcoming
code snippets, and to make writing this page easier, I'm going to assume you've installed
Micromamba. Please note that Micromamba/Miniconda installation and configuration instructions are
outside of the scope of this document.

Let's create an isolated environment in which we'll install devpi. I suggest running these specific
commands one at a time.

``` shell
micromamba create --name devpi -- devpi-client devpi-server python
micromamba activate devpi
mkdir -p -- "${HOME}/.devpi"
devpi-init \
  --role standalone \
  --root-passwd root \
  --serverdir "${HOME}/.devpi/server" \
  --storage sqlite
DEVPI_PREFIX="$(python -c 'import sys; print(sys.prefix)')"
micromamba deactivate
```

Now let's create two files that will make it easy to automatically start and stop devpi.

First, let's create a launchd service. The following code snippet does this for us, but assumes that
the `DEVPI_PREFIX` shell variable is still set from the previous step. You may run the entire code
snippet by copy-pasting it all at once.

``` shell
mkdir -p -- "${HOME}/Library/LaunchAgents"
cat > "${HOME}/Library/LaunchAgents/com.manselmi.devpi.server.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Disabled</key>
    <false/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>Label</key>
    <string>com.manselmi.devpi.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/.devpi/devpi-server</string>
        <string>${DEVPI_PREFIX}/bin/devpi-server</string>
        <string>--port</string>
        <string>3141</string>
        <string>--serverdir</string>
        <string>${HOME}/.devpi/server</string>
    </array>
</dict>
</plist>
EOF
```

If you would like to learn more about launchd, please see [Creating Launch Daemons and
Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html).

Second, let's create the `${HOME}/.devpi/devpi-server` file invoked by the launchd service. The
following code snippet does this for us, but assumes that the `DEVPI_PREFIX` shell variable is still
set from a previous step. You may run the entire code snippet by copy-pasting it all at once.

``` shell
mkdir -p -- "${HOME}/.devpi"
cat > "${HOME}/.devpi/devpi-server" << EOF
#!${DEVPI_PREFIX}/bin/python
# vim: set ft=python :

import signal
import subprocess
import sys


def main():
    process = None

    def handler(signum, frame):
        if process is not None:
            process.send_signal(signal.SIGINT)

    signal.signal(signal.SIGINT, handler)
    signal.signal(signal.SIGTERM, handler)

    process = subprocess.Popen(sys.argv[1:], start_new_session=True)
    process.wait()

    sys.exit(process.returncode)


if __name__ == '__main__':
    main()
EOF
chmod +x "${HOME}/.devpi/devpi-server"
```

The launchd service we created will run when loaded, so let's load the service:

``` shell
launchctl bootstrap "gui/$(id -u)/" ~/Library/LaunchAgents/com.manselmi.devpi.server.plist
```

Please note that upon future logins, the service will automatically be loaded and hence
automatically started.

Now let's confirm that devpi is up and running. Navigate your browser to
[localhost:3141](http://localhost:3141/). If you see a devpi page, then so far so good.

## Configuration instructions

In this section we'll configure devpi to behave as described in the introduction, and then we'll
configure pip to use devpi.

These commands configure devpi. I suggest running these specific commands one at a time.

``` shell
micromamba activate devpi
unset DEVPI_INDEX
devpi use --always-set-cfg no http://localhost:3141/  # this might complain; no worries
devpi login --password root root
devpi index pypi mirror_use_external_urls=True  # don't cache PyPI packages
devpi index -c python-local \
  mirror_url='https://artifactory.example.com/artifactory/api/pypi/python-local/simple/' \
  title='Intranet: python-local' \
  type=mirror \
  volatile=False
devpi index -c local \
  bases='root/python-local,root/pypi' \
  title='Local: personal index'
devpi use --venv - root/local
micromamba deactivate
```

!!! note

    If you would like to cache _all_ packages (including those from PyPI), run the following command
    before running `micromamba deactivate`:

    ``` shell
    devpi index pypi mirror_use_external_urls=False
    ```

    However, be aware that devpi will consume more disk space.

This configures pip, distutils and buildout to use devpi. You may run the entire code snippet by
copy-pasting it all at once.

``` shell
mkdir -p -- "${HOME}/Library/Application Support/pip"
cat > "${HOME}/Library/Application Support/pip/pip.conf" << 'EOF'
[global]
index-url = http://localhost:3141/root/local/+simple/
trusted-host = localhost
[search]
index = http://localhost:3141/root/local/
EOF

cat > "${HOME}/.pydistutils.cfg" << 'EOF'
[easy_install]
index_url = http://localhost:3141/root/local/+simple/
EOF

mkdir -p -- "${HOME}/.buildout"
cat > "${HOME}/.buildout/default.cfg" << 'EOF'
[buildout]
index = http://localhost:3141/root/local/+simple/
EOF
```

## Validation

Let's confirm that pip and devpi are working as expected.

First, let's try downloading `numpy`:

``` shell
rm -f -- numpy-*.whl
python -m pip --no-cache-dir download --no-deps --prefer-binary -- numpy
# Looking in indexes: http://localhost:3141/root/local/+simple/
# Collecting numpy
#   Downloading http://localhost:3141/root/pypi/%2Bf/afd/5ced4e5a96dac/numpy-1.26.1-cp312-cp312-macosx_11_0_arm64.whl (13.7 MB)
#      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 13.7/13.7 MB 14.8 MB/s eta 0:00:00
# Saved ./numpy-1.26.1-cp312-cp312-macosx_11_0_arm64.whl
# Successfully downloaded numpy
```

Finally, let's try downloading `private-package` while connected to the intranet:

``` shell
rm -f -- private-package-*.tar.gz
python -m pip --no-cache-dir download --no-deps -- private-package
# Looking in indexes: http://localhost:3141/root/local/+simple/
# Collecting private-package
#   Downloading http://localhost:3141/root/python-local/%2Bf/77b/253cc0ae627fb/private-package-2.0.0.tar.gz (208 kB)
#      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 208.8/208.8 kB 675.9 MB/s eta 0:00:00
#   Preparing metadata (setup.py) ... done
# Saved ./private-package-2.0.0.tar.gz
# Successfully downloaded private-package
```

We're seeing a fast download speed because my `devpi` instance already has the latest version of
`private-package` in its cache. devpi checked with Artifactory and determined that I already had the latest
version cached, so devpi served the cached copy… very quickly.

Now let's try while _not_ connected to the intranet.

``` shell
rm -f -- private-package-*.tar.gz
python -m pip --no-cache-dir download --no-deps -- private-package
# Looking in indexes: http://localhost:3141/root/local/+simple/
# Collecting private-package
#   Downloading http://localhost:3141/root/python-local/%2Bf/77b/253cc0ae627fb/private-package-2.0.0.tar.gz (208 kB)
#      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 208.8/208.8 kB 573.3 MB/s eta 0:00:00
#   Preparing metadata (setup.py) ... done
# Saved ./private-package-2.0.0.tar.gz
# Successfully downloaded private-package
```

Same result.

## Rancher Desktop

A nice bonus is that we can also instruct pip _within a container_ to leverage devpi. This makes it
easier to work with Python within a container regardless of whether or not we're connected to the
intranet.

Ensure you're not connected to the intranet before running the following command:

``` shell
nerdctl container run \
  --env PIP_INDEX_URL=http://host.lima.internal:3141/root/local/+simple/ \
  --env PIP_TRUSTED_HOST=host.lima.internal \
  --rm \
  -- \
  docker.io/library/python:3.12.0-bookworm \
  pip download --no-deps -- private-package numpy
# Looking in indexes: http://host.lima.internal:3141/root/local/+simple/
# Collecting private-package
#   Downloading http://host.lima.internal:3141/root/python-local/%2Bf/77b/253cc0ae627fb/private-package-2.0.0.tar.gz (208 kB)
#      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 208.8/208.8 kB 19.1 MB/s eta 0:00:00
#   Preparing metadata (setup.py): started
#   Preparing metadata (setup.py): finished with status 'done'
# Collecting numpy
#   Downloading http://host.lima.internal:3141/root/pypi/%2Bf/a03/fb25610ef560a/numpy-1.26.1-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl (13.9 MB)
#      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 13.9/13.9 MB 15.4 MB/s eta 0:00:00
# Saved /private-package-2.0.0.tar.gz
# Saved /numpy-1.26.1-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
# Successfully downloaded private-package numpy
```

## Maintenance

To stop the devpi service:

``` shell
launchctl bootout "gui/$(id -u)/com.manselmi.devpi.server"
```

To start the devpi service (if not already running):

``` shell
launchctl bootstrap "gui/$(id -u)/" ~/Library/LaunchAgents/com.manselmi.devpi.server.plist
```

To upgrade devpi:

``` shell
launchctl bootout "gui/$(id -u)/com.manselmi.devpi.server"
micromamba update --name devpi --all
launchctl bootstrap "gui/$(id -u)/" ~/Library/LaunchAgents/com.manselmi.devpi.server.plist
```

To uninstall devpi, run:

``` shell
launchctl bootout "gui/$(id -u)/com.manselmi.devpi.server"
rm -r -- \
  "${HOME}/.buildout" \
  "${HOME}/.devpi" \
  "${HOME}/.pydistutils.cfg" \
  "${HOME}/Library/Application Support/pip/pip.conf" \
  "${HOME}/Library/LaunchAgents/com.manselmi.devpi.server.plist"
micromamba env remove --name devpi
```


<!-- vim: set ft=markdown : -->
