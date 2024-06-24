---
tags:
  - ssh
  - windows
---

# Windows Subsystem for Linux

## Introduction

!!! quote "What is the Windows Subsystem for Linux?"

    Windows Subsystem for Linux (WSL) is a feature of Windows that allows you to run a Linux
    environment on your Windows machine, without the need for a separate virtual machine or dual
    booting. WSL is designed to provide a seamless and productive experience for developers who want
    to use both Windows and Linux at the same time.

    * Use WSL to install and run various Linux distributions, such as Ubuntu, Debian, Kali, and
      more. [Install Linux distributions](https://learn.microsoft.com/en-us/windows/wsl/install) and
      receive automatic updates from the
      [Microsoft Store](https://learn.microsoft.com/en-us/windows/wsl/compare-versions#wsl-in-the-microsoft-store),
      [import Linux distributions not available in the Microsoft Store](https://learn.microsoft.com/en-us/windows/wsl/use-custom-distro),
      or [build your own customer Linux
      distribution](https://learn.microsoft.com/en-us/windows/wsl/build-custom-distro).

    * Store files in an isolated Linux file system, specific to the installed distribution.

    * Run command-line tools, such as BASH.

    * Run common BASH command-line tools such as grep, sed, awk, or other ELF-64 binaries.

    * Run Bash scripts and GNU/Linux command-line applications including:

        * Tools: vim, emacs, tmux

        * Languages: [NodeJS](https://learn.microsoft.com/en-us/windows/nodejs/setup-on-wsl2),
          JavaScript, [Python](https://learn.microsoft.com/en-us/windows/python/web-frameworks),
          Ruby, C/C++, C# & F#, Rust, Go, etc.

        * Services: SSHD,
          [MySQL](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-database), Apache,
          lighttpd, [MongoDB](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-database),
          [PostgreSQL](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-database).

    * Install additional software using your own GNU/Linux distribution package manager.

    * Invoke Windows applications using a Unix-like command-line shell.

    * Invoke GNU/Linux applications on Windows.

    * [Run GNU/Linux graphical
      applications](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps) integrated
      directly to your Windows desktop

    * Use your device [GPU to accelerate Machine Learning workloads running on
      Linux](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gpu-compute).

([source](https://learn.microsoft.com/en-us/windows/wsl/about))

## Installation

* [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

## Tutorials

* [Best practices for set up](https://learn.microsoft.com/en-us/windows/wsl/setup/environment)

* [Get started with Linux and Bash](https://learn.microsoft.com/en-us/windows/wsl/tutorials/linux)

* [Get started with Git](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-git)

* [Get started with VS Code](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-vscode)

* [Get started with Docker remote
  containers](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers)

* [Set up GPU acceleration (NVIDIA CUDA /
  DirectML)](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gpu-compute)

## Concepts

* [Working across file systems](https://learn.microsoft.com/en-us/windows/wsl/filesystems)

* [Advanced settings configuration](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)

* [File access and permissions](https://learn.microsoft.com/en-us/windows/wsl/file-permissions)

* [Networking considerations](https://learn.microsoft.com/en-us/windows/wsl/networking)

## Configuration

### VPN

To make WSL compatible with Cisco AnyConnect VPN, enable [mirrored mode
networking](https://learn.microsoft.com/en-us/windows/wsl/networking#mirrored-mode-networking) and
[DNS tunneling](https://learn.microsoft.com/en-us/windows/wsl/networking#dns-tunneling) by adding
the following to [`.wslconfig`](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#wslconfig)
within the
[`%USERPROFILE%`](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables) directory:

``` ini title="%USERPROFILE%\.wslconfig"
[wsl2]
networkingMode=mirrored
dnsTunneling=true
```

Learn more about `networkingMode` and `dnsTunneling`
[here](https://devblogs.microsoft.com/commandline/windows-subsystem-for-linux-september-2023-update/).

!!! note

    `networkingMode=mirrored` and `dnsTunneling=true` require [Windows 11 version
    22H2](https://blogs.windows.com/windows-insider/2023/09/14/releasing-windows-11-build-22621-2359-to-the-release-preview-channel/)
    or higher.

### VS Code

Here we configure VS Code to use the SSH binary provided by WSL, along with the aforementioned SSH
config, to have a single SSH config shared by WSL and VS Code.

First, [install VS
Code](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-vscode#install-vs-code-and-the-wsl-extension)
for your [user (not
system-wide)](https://code.visualstudio.com/docs/setup/windows#_user-setup-versus-system-setup).
When prompted to **Select Additional Tasks** during installation, be sure to check the **Add to
PATH** option so you can easily open a folder in WSL using the `code` command. Also, install the
[Remote Development extension pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack).

Create a Windows batch file to passthrough SSH invocations to the WSL-provided SSH:

``` bat title="%USERPROFILE%\.ssh\ssh.bat"
C:\Windows\system32\wsl.exe ssh %*
```

Add the following to VS Code's `settings.json` within the `%APPDATA%\Code\User` directory:

``` { .json .annotate title="%APPDATA%\Code\User\settings.json" }
{
    "remote.SSH.path": "C:\\Users\\manselmi\\.ssh\\ssh.bat(1)",
    "remote.SSH.remotePlatform": {
        "jump": "linux",
        "vps": "linux"
    },
    "security.allowedUNCHosts": ["wsl$", "wsl.localhost"]
}
```

1. Replace with the expansion of `%USERPROFILE%\.ssh\ssh.bat` for your user, escaping backslashes as
   shown here.

Start or restart VS Code. Click the blue Remote Development icon in the lower-left corner, then
click **Connect Current Window to Host…**.

<figure markdown>
  ![](/assets/wsl/vscode-remote-ssh-01.png)
</figure>

Type the name of a SSH host alias defined in the SSH config file, such as `jump`, then press Enter.

<figure markdown>
  ![](/assets/wsl/vscode-remote-ssh-02.png)
</figure>

VS Code will then connect and launch a remote session. If you were to select the **TERMINAL** tab,
VS Code would launch a remote shell session.

<figure markdown>
  ![](/assets/wsl/vscode-remote-ssh-03.png)
</figure>

Learn more about [VS Code Remote
Development](https://code.visualstudio.com/docs/remote/remote-overview).


<!-- vim: set ft=markdown : -->
