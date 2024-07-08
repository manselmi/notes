# vim: set ft=zsh :


typeset -U path
path=(
  "${HOME}/.prefix/bin"
  "${path[@]}"
)


# Run resticprofile with our config file.
rp() {
  exec-resticprofile "${@}"
}

_rp-profile() {
  PROFILE="${1-"vps"}"
}

# Manually start backup (default profile "vps") and tail the backup log.
bk() {
  local PROFILE
  _rp-profile "${@}"

  sudo -n -- systemctl start "resticprofile-backup@${PROFILE}.service" && bkl "${PROFILE}"
}

# Tail the backup log (default profile "vps").
bkl() {
  local PROFILE
  _rp-profile "${@}"

  less +F --follow-name -- "${HOME}/.config/resticprofile/log/${PROFILE}/backup.log"
}

# Log current backup progress.
# https://restic.readthedocs.io/en/latest/manual_rest.html?highlight=SIGUSR1
bkp() {
  bksig USR1
}

# Pretty-print backup status file (default profile "vps").
bks() {
  local PROFILE
  _rp-profile "${@}"

  jq \
    --arg PROFILE "${PROFILE}" \
    '.profiles[$PROFILE]' \
    -- \
    "${HOME}/.config/resticprofile/status/${PROFILE}.json"
}

# Signal restic processes with the specified signal.
bksig() {
  local SIGNAL

  if [[ -z "${1-}" ]]; then
    printf '%s\n' 'ERROR: bksig expects the name of a signal to send to restic processes' >&2
    return 1
  fi
  SIGNAL="${1}"

  sudo -n -- /usr/bin/pkill -"${SIGNAL}" -xu "$(id -u)" -- restic
}
