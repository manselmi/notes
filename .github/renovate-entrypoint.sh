#!/usr/bin/env sh
# vim: set ft=sh :

# Stop at any error, treat unset vars as errors and make pipelines exit with a non-zero exit code if
# any command in the pipeline exits with a non-zero exit code.
set -o errexit
set -o nounset


BIN_DIR='/usr/local/bin'
INSTALLER='/tmp/installer'


curl() {
  /usr/bin/curl --fail --location --max-time 10 --no-progress-meter --retry 2 "${@}"
}


export MISE_INSTALL_PATH="${BIN_DIR}/mise" PIXI_BIN_DIR="${BIN_DIR}"
for URL in 'https://mise.jdx.dev/install.sh' 'https://pixi.prefix.dev/install.sh'
do
  curl --output "${INSTALLER}" -- "${URL}"
  chmod -- +x "${INSTALLER}"
  "${INSTALLER}"
  rm -- "${INSTALLER}"
done
