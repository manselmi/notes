# vim: set ft=zsh :


###################
# Shell variables #
###################

# Keymaps
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Keymaps
#
# Parameters Used By The Shell
# https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
#
# Prompt Expansion
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

INSTALL_DIR="${HOME}/.prefix"
INSTALL_SW_DIR="${INSTALL_DIR}/sw"

HISTFILE="${HOME}/.zhistory"
HISTSIZE=1000
HOMEBREW_INSTALL_DIR="${INSTALL_SW_DIR}/homebrew"
JAVA_HOME="$(/usr/libexec/java_home --version 21)"
KEYTIMEOUT=1
LANG=en_US.UTF-8
MAMBA_ROOT_PREFIX="${INSTALL_SW_DIR}/mamba"
SAVEHIST=2000
TASKFILE_LIBRARY_ROOT_DIR="${HOME}/.taskfile"
TASKFILE_INCLUDE_ROOT_DIR="${TASKFILE_LIBRARY_ROOT_DIR}/include"
VISUAL=vim
ZSH_COMPLETION_DIR="${HOME}/.zcompletion"

PS1='[%n@%m] '
PS1+='%~'
PS1+='${vcs_info_msg_0_} '
PS1+='%# '

RPS1='${${${KEYMAP-}/vicmd/[NORMAL]}/(main|viins)/[INSERT]}'
RPS2="${RPS1}"

#########################
# Environment variables #
#########################

# export
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-export-1

export JAVA_HOME
export LANG
export MAMBA_ROOT_PREFIX
export TASKFILE_LIBRARY_ROOT_DIR
export TASKFILE_INCLUDE_ROOT_DIR
export VISUAL
export ZSH_COMPLETION_DIR

#############
# Functions #
#############

conda() {
  mamba "${@}"
}

mamba() {
  micromamba "${@}"
}

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

zkbd_bind_key() {
  local KEY="${1}"
  local ACTION="${2}"

  if [[ -n "${key[${KEY}]}" ]]; then
    bindkey -- "${key[${KEY}]}" "${ACTION}"
  fi
}

zkbd_setup() {
  # https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Keyboard-Definition

  local ZKBD_CONF="${HOME}/.zkbd/${1}"

  if [[ -f "${ZKBD_CONF}" ]]; then
    source -- "${ZKBD_CONF}"
    zkbd_bind_key Backspace backward-delete-char
    zkbd_bind_key Insert    overwrite-mode
    zkbd_bind_key Home      beginning-of-line
    zkbd_bind_key PageUp    history-beginning-search-backward
    zkbd_bind_key Delete    delete-char
    zkbd_bind_key End       end-of-line
    zkbd_bind_key PageDown  history-beginning-search-forward
    zkbd_bind_key Up        up-line-or-search
    zkbd_bind_key Down      down-line-or-search
  fi
}

###########
# Aliases #
###########

# alias
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-alias

alias tma='tmux attach-session -d -t'
alias tml='tmux list-sessions'
alias zcp='zmv -C'
alias zln='zmv -L'

################
# fpath & path #
################

# fpath
# https://zsh.sourceforge.io/Doc/Release/Parameters.html#index-fpath
#
# hash
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-hash-1
#
# path
# https://zsh.sourceforge.io/Doc/Release/Parameters.html#index-path
#
# typeset
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-typeset

typeset -U -- fpath path
fpath=(
  "${ZSH_COMPLETION_DIR}"
  "${fpath[@]}"
)
path=(
  "${INSTALL_DIR}/bin"
  "${HOMEBREW_INSTALL_DIR}/bin"
  '/usr/local/bin'
  "${path[@]}"
)
hash -r

########################
# Autoloaded functions #
########################

# autoload
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-autoload
#
# Autoloading Functions
# https://zsh.sourceforge.io/Doc/Release/Functions.html#index-autoloading-functions
#
# bashcompinit, compinit
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#index-compinit
#
# colors
# https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#index-colors
#
# vcs_info
# https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Version-Control-Information
#
# zargs
# https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#index-zargs
#
# zmv
# https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#index-zmv

autoload -Uz -- bashcompinit colors compinit vcs_info zargs zmv
bashcompinit; colors; compinit; vcs_info

##################
# Autocompletion #
##################

# complete
# https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html#index-complete
#
# eval
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-eval
#
# whence
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-whence

DIRENV_EXE="$(whence -p -- direnv || true)"
if [[ -n "${DIRENV_EXE}" ]]; then
  eval -- "$("${DIRENV_EXE}" hook zsh)"
fi
unset -- DIRENV_EXE

MICROMAMBA_EXE="$(whence -p -- micromamba || true)"
if [[ -n "${MICROMAMBA_EXE}" ]]; then
  eval -- "$("${MICROMAMBA_EXE}" shell hook -s zsh)"
fi
unset -- MICROMAMBA_EXE

RCLONE_EXE="$(whence -p -- rclone || true)"
if [[ -n "${RCLONE_EXE}" ]]; then
  eval -- "$("${RCLONE_EXE}" completion zsh -)"
fi
unset -- RCLONE_EXE

##############################
# Activate Mamba environment #
##############################

# MAMBA_ENV=default
# if [[
#   -d "${MAMBA_ROOT_PREFIX}/envs/${MAMBA_ENV}" &&
#   "$({ whence -w -- micromamba || true ; } | awk -- '{ print $NF }')" == 'function'
# ]]; then
#   micromamba activate "${MAMBA_ENV}"
# fi
# unset -- MAMBA_ENV

#################
# Finalize path #
#################

path=(
  "${INSTALL_DIR}/bin"
  "${path[@]}"
)
hash -r

###########
# Options #
###########

# Description of Options
# https://zsh.sourceforge.io/Doc/Release/Options.html#Description-of-Options
#
# set
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-set

set -o COMPLETE_IN_WORD
set -o HIST_IGNORE_DUPS
set -o HIST_IGNORE_SPACE
set -o HIST_REDUCE_BLANKS
set -o INTERACTIVECOMMENTS
set -o PROMPT_SUBST
set -o SHARE_HISTORY

##########
# Prompt #
##########

# bindkey
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#index-bindkey
#
# Parameters Used By The Shell
# https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
#
# precmd
# https://zsh.sourceforge.io/Doc/Release/Functions.html#index-precmd
#
# preexec
# https://zsh.sourceforge.io/Doc/Release/Functions.html#index-preexec
#
# zle
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#index-zle
#
# Zsh Line Editor
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
#
# zstyle
# https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#index-zstyle

zstyle -- ':completion:*:*:*:*:descriptions' format '%F{green}%d%f'

zstyle -- ':vcs_info:*' enable git hg svn
zstyle -- ':vcs_info:*' check-for-changes true
# disable-patterns bug:
# http://www.zsh.org/mla/workers/2014/msg01186.html
# zstyle -- ':vcs_info:*' disable-patterns "${VCS_INFO_DISABLE_PATTERNS[@]}"
zstyle -- ':vcs_info:*' stagedstr S
zstyle -- ':vcs_info:*' unstagedstr U
zstyle -- ':vcs_info:*' actionformats \
  " [%{$fg_bold[blue]%}%s%{%f%%b%} %{$fg_bold[cyan]%}%b%{%f%%b%} %{$fg_bold[magenta]%}%a%{%f%%b%} %{$fg_bold[green]%}%c%{%f%%b%}%{$fg_bold[yellow]%}%u%{%f%%b%}]"
zstyle -- ':vcs_info:*' formats \
  " [%{$fg_bold[blue]%}%s%{%f%%b%} %{$fg_bold[cyan]%}%b%{%f%%b%} %{$fg_bold[green]%}%c%{%f%%b%}%{$fg_bold[yellow]%}%u%{%f%%b%}]"
zstyle -- ':vcs_info:git*+set-message:*' hooks git-untracked
+vi-git-untracked() {
  if [[ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" == 'true' ]] && \
    git status --porcelain | grep '^??' &> /dev/null ; then
    hook_com[unstaged]+="%{$fg_bold[red]%}?%{%f%}"
  fi
}

function zle-line-init zle-keymap-select {
  zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select

bindkey -v
zkbd_setup "${TERM}"

precmd() {
  vcs_info
}

preexec() {
  tmux_update_environment
}

################
# Flow control #
################

if [[ -t 0 ]]; then
  stty start undef
  stty stop undef
  stty ixany
  stty -ixon
  stty ixoff
fi
