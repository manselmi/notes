#!/usr/bin/env sh
# vim: set ft=sh :

# Stop at any error, treat unset vars as errors and make pipelines exit with a non-zero exit code if
# any command in the pipeline exits with a non-zero exit code.
set -o errexit
set -o nounset
set -o pipefail


BIN_DIR='/usr/local/bin'


curl() {
  "$(command -v curl)" -v --fail --max-time 10 --no-progress-meter --retry 2 "${@}"
}


curl -- 'https://mise.jdx.dev/install.sh' | env -- MISE_INSTALL_PATH="${BIN_DIR}/mise" sh
curl -- 'https://pixi.sh/install.sh' | env -- PIXI_BIN_DIR="${BIN_DIR}" sh
