#!/usr/bin/env -S -- zsh -f
# vim: set ft=zsh :

# Stop at any error, treat unset vars as errors and make pipelines exit with a non-zero exit code if
# any command in the pipeline exits with a non-zero exit code.
set -o ERR_EXIT
set -o NO_UNSET
set -o PIPE_FAIL


# If macOS, define the following shell functions as aliases of the following programs (available via
# Homebrew):
#
#   tar → gtar (GNU tar)
#
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-whence
if [[ "${OSTYPE}" == darwin* ]]; then
  tar() { "$(whence -p gtar)" --format=posix "${@}" ; }
fi

# Accept TAR from stdin and extract relative to ${TAR_DIRECTORY}, preserving ownership and
# permissions.
tar \
  -xf - \
  --directory="${TAR_DIRECTORY}" \
  --same-owner \
  --same-permissions
