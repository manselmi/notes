#!/usr/bin/env sh
# vim: set ft=sh :

# Stop at any error, treat unset vars as errors and make pipelines exit with a non-zero exit code if
# any command in the pipeline exits with a non-zero exit code.
set -o errexit
set -o nounset


INSTALL_PREFIX='/usr/local'
INSTALLER='/tmp/installer'


curl() {
  /usr/bin/curl --fail --location --max-time 10 --no-progress-meter --retry 2 "${@}"
}


export \
  MISE_INSTALL_PATH="${INSTALL_PREFIX}/bin/mise" \
  MISE_QUIET=1 \
  PIXI_BIN_DIR="${INSTALL_PREFIX}/bin" \
  PIXI_NO_PATH_UPDATE=1
for URL in \
  'https://mise.jdx.dev/install.sh' \
  'https://pixi.prefix.dev/install.sh'
do
  curl --output "${INSTALLER}" -- "${URL}"
  chmod -- +x "${INSTALLER}"
  "${INSTALLER}"
  rm -- "${INSTALLER}"
done

exec renovate
