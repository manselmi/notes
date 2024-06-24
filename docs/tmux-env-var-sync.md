---
tags:
  - shell
  - ssh
  - tmux
---

# tmux environment variable sync

## Introduction

How to automatically (un)set environment variables when attaching a tmux session.

Whenever possible, I [avoid][1] SSH agent forwarding and instead rely on `ProxyJump` if I need to
connect to a host via a bastion host. However, sometimes I want to expose my local SSH agent to a
remote host so I can clone a Git repo directly onto that host.

This can be a pain for tmux users because the remote host looks for the (forwarded) SSH agent
via the `SSH_AUTH_SOCK` environment variable, which will not be set or updated when attaching an
existing tmux session created in a previous SSH session.

There are plenty of [workarounds][2] to be found online, but years ago I was faced with this issue
and wanted to implement a more generic solution that would suffice for any environment variable I
specify.

In short, I do the following:

1. Before attaching a tmux session, update the specified environment variables in tmux' global
   environment to reflect their state in the current shell environment.

1. After attaching a tmux session, update the specified environment variables in the current shell
   environment to reflect their state in tmux' global environment.

Here are the relevant snippets from `.tmux.conf` and `.zshrc`.

## `~/.tmux.conf`

``` text
# https://www.mankier.com/1/tmux#Options
# https://www.mankier.com/1/tmux#Global_and_Session_Environment
set-option -g update-environment \
'DISPLAY KRB5CCNAME SSH_AGENT_PID SSH_ASKPASS SSH_AUTH_SOCK SSH_CLIENT SSH_CONNECTION SSH_TTY \
SSH_USER_AUTH WINDOWID XAUTHORITY'
```

## `~/.zshrc`

``` shell
tm() {
  local SESSION_NAME

  if [[ -v 1 ]]; then
    SESSION_NAME="${1}"
  else
    SESSION_NAME=default
  fi

  tmux new-session -AD -s "${SESSION_NAME}"
}

tmux_global_update_var() {
  local VAR="${1}"
  local VALUE

  if [[ -v 2 ]]; then
    VALUE="${2}"
  elif [[ -v "${VAR}" ]]; then
    VALUE="${(P)VAR}"
  else
    tmux set-environment -gru -- "${VAR}"
    return
  fi

  tmux set-environment -g -- "${VAR}" "${VALUE}"
}

tmux_shell_update_var() {
  local VAR="${1}"
  local TMUX_OUTPUT
  local TMUX_ERROR_CODE

  TMUX_OUTPUT="$(tmux show-environment -gs -- "${VAR}" 2> /dev/null)"
  TMUX_ERROR_CODE="${?}"

  if [[ "${TMUX_ERROR_CODE}" -eq 0 ]]; then
    eval -- "${TMUX_OUTPUT}"
  else
    unset -- "${VAR}"
  fi
}

tmux_update_environment() {
  if ! whence -p -- tmux > /dev/null; then
    return
  fi

  local IFS=$'\n'
  local FUNC
  local VAR
  local VARS

  if [[ ! -v TMUX ]]; then
    if ! tmux has-session 2> /dev/null; then
      return
    fi
    FUNC=tmux_global_update_var
  else
    FUNC=tmux_shell_update_var
  fi

  VARS=($(tmux show-options -gv -- update-environment))
  for VAR in "${VARS[@]}"; do
    eval -- "${FUNC}" "${VAR}"
  done
}


# https://zsh.sourceforge.io/Doc/Release/Functions.html#index-preexec
preexec() {
  tmux_update_environment
}
```

[1]: https://www.infoworld.com/article/3619278/proxyjump-is-safer-than-ssh-agent-forwarding.html
[2]: https://gist.github.com/martijnvermaat/8070533


<!-- vim: set ft=markdown : -->
