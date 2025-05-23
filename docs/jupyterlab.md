---
tags:
  - launchd
  - python
  - taskfile
---

# JupyterLab

## Project URL

[JupyterLab](https://jupyterlab.readthedocs.io/en/latest/index.html)

## Project description

JupyterLab is a highly extensible, feature-rich notebook authoring application and editing
environment, and is a part of [Project Jupyter](https://docs.jupyter.org/en/latest/),
a large umbrella project centered around the goal of providing tools (and
[standards](https://docs.jupyter.org/en/latest/#sub-project-documentation)) for interactive
computing with [computational notebooks](https://docs.jupyter.org/en/latest/#what-is-a-notebook).

A computational notebook is a shareable document that combines computer code, plain language
descriptions, data, rich visualizations like 3D models, charts, graphs and figures, and interactive
controls. A notebook, along with an editor like JupyterLab, provides a fast interactive environment
for prototyping and explaining code, exploring and visualizing data, and sharing ideas with others.

JupyterLab is a sibling to other notebook authoring applications under the Project Jupyter
umbrella, like [Jupyter Notebook](https://jupyter-notebook.readthedocs.io/en/latest/) and [Jupyter
Desktop](https://github.com/jupyterlab/jupyterlab-desktop). JupyterLab offers a more advanced,
feature rich, customizable experience compared to Jupyter Notebook.

## Installation instructions

First, install [Pixi](https://pixi.sh). Please note that Pixi installation and configuration
instructions are outside of the scope of this document, although if you use Homebrew, you may use it
to quickly install Pixi:

``` shell
brew install -- pixi
```

Ensure that the following directories exist:

``` shell
mkdir -p -- \
  "${HOME}/.jupyterlab" \
  "${HOME}/.taskfile/jupyterlab" \
  "${HOME}/Documents/Jupyter" \
  "${HOME}/Library/LaunchAgents"
```

Place the Pixi manifest file for an isolated JupyterLab environment in the `~/.taskfile/jupyterlab`
directory:

``` toml title="pixi.toml"
--8<-- "docs/assets/jupyterlab/pixi-jupyterlab.toml"
```

Create the JupyterLab environment, then remove JupyterLab's default kernels:

``` shell
pushd -q -- "${HOME}/.taskfile/jupyterlab"
pixi update
pixi install
find -- .pixi/envs/default/share/jupyter/kernels -mindepth 1 -delete
popd -q
```

Add this JupyterLab configuration file to the `~/.jupyter` directory:

``` python title="jupyter_lab_config.py"
--8<-- "docs/assets/jupyterlab/jupyter_lab_config.py"
```

Now let's create a launchd service that will make it easy to automatically start and stop
JupyterLab. Add this JupyterLab launchd service definition to the `~/Library/LaunchAgents`
directory, editing usernames, pathnames and the `PATH` and `TZ` environment variables as needed:

``` xml title="org.jupyter.jupyterlab.server.plist"
--8<-- "docs/assets/jupyterlab/org.jupyter.jupyterlab.server.plist"
```

If you would like to learn more about launchd, please see [Creating Launch Daemons and
Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html).

The launchd service we created will run when loaded, so let's load the service:

``` shell
launchctl bootstrap "gui/$(id -u)/" ~/Library/LaunchAgents/org.jupyter.jupyterlab.server.plist
```

Please note that upon future logins, the service will automatically be loaded and hence
automatically started.

Now let's confirm that JupyterLab is up and running. Navigate your browser to
[http://localhost:8888](http://localhost:8888). If you see a JupyterLab page, then so far so good.

## Register Python environment with JupyterLab

Let's create a Python environment specific to the `foo` project. In addition to Python, the
environment must contain [`ipykernel`](https://ipykernel.readthedocs.io).

Create this project-specific Pixi manifest file:

``` toml title="pixi.toml"
--8<-- "docs/assets/jupyterlab/pixi-foo.toml"
```

Create the Python environment:

``` shell
pixi upgrade
pixi install
```

Create a kernel to register the environment with JupyterLab:

``` { .shell .annotate }
pixi run -- python -m ipykernel install --user \
  --name foo \  # (1)!
  --display-name Foo  # (2)!
```

1. The kernel name is set to `foo`.

2. The kernel display name is set to `Foo`.

Now let's confirm that we can start a notebook using our new kernel. Navigate your browser to
[http://localhost:8888](http://localhost:8888). You should see a screen like this with the `Foo`
kernel available.

<figure markdown>
  ![](/assets/jupyterlab/landing-page.png)
</figure>

Create a new notebook with the `Foo` kernel and run something simple like `1+1`.

<figure markdown>
  ![](/assets/jupyterlab/notebook.png)
</figure>

Congratulations! 🥳

## Maintenance

Routine maintenance tasks may be automated with [Task](https://taskfile.dev). Please install it.
Please note that Task installation and configuration instructions are outside of the scope of this
document, although if you use Homebrew, you may use it to quickly install Task:

``` shell
brew install -- go-task/tap/go-task
```

Place [these taskfile directories](https://github.com/manselmi/taskfile-library/tree/main/include)
in the `~/.taskfile/include` directory (create it if necessary), and ensure that the environment
variable `TASKFILE_INCLUDE_ROOT_DIR` is set to the same directory, as in the example
[`~/.zshrc`]({{ prefix_repo_url("assets/.zshrc") }}) configuration file.

Additionally, place this JupyterLab taskfile in the `~/.taskfile/jupyterlab` directory:

``` yaml title="taskfile.yaml"
--8<-- "docs/assets/jupyterlab/taskfile.yaml"
```

Here are some common tasks:

To stop the JupyterLab service, run:

``` shell
task -d "${HOME}/.taskfile/jupyterlab" launchctl:bootout
```

To start the JupyterLab service (if not already running), run:

``` shell
task -d "${HOME}/.taskfile/jupyterlab" launchctl:bootstrap
```

To upgrade the JupyterLab environment and remove any default kernel, run:

``` shell
pushd -q -- "${HOME}/.taskfile/jupyterlab"
task launchctl:bootout
task pixi:update
task pixi:install
task remove-default-kernels
task launchctl:bootstrap
popd -q
```

To perform the previous operations with a single command, run:

``` shell
task -d "${HOME}/.taskfile/jupyterlab" upgrade
```

To disable JupyterLab, within `~/Library/LaunchAgents/org.jupyter.jupyterlab.server.plist` change

``` xml
	<key>Disabled</key>
	<false/>
```

to

``` xml
	<key>Disabled</key>
	<true/>
```

then run:

``` shell
task -d "${HOME}/.taskfile/jupyterlab" launchctl:bootout
```

To uninstall JupyterLab, first disable it and then run:

``` shell
task -d "${HOME}/.taskfile/jupyterlab" pixi:clean
```


<!-- vim: set ft=markdown : -->
