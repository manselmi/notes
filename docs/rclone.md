---
tags:
  - rclone
  - security
  - ssh
---

# Rclone

## Introduction

The following introduction is sourced directly from [rclone.org](https://rclone.org).

### About Rclone

Rclone is a command-line program to manage files on cloud storage. It is a feature-rich
alternative to cloud vendors' web storage interfaces. [Over 70 cloud storage
products](https://rclone.org/#providers) support rclone including S3 object stores, business &
consumer file storage services, as well as standard transfer protocols.

Rclone has powerful cloud equivalents to the unix commands rsync, cp, mv, mount, ls, ncdu, tree, rm,
and cat. Rclone's familiar syntax includes shell pipeline support, and `--dry-run` protection. It is
used at the command line, in scripts or via its [API](https://rclone.org/rc).

Users call rclone _"The Swiss army knife of cloud storage"_, and _"Technology indistinguishable from
magic"_.

Rclone really looks after your data. It preserves timestamps and verifies checksums at all times.
Transfers over limited bandwidth; intermittent connections, or subject to quota can be restarted,
from the last good file transferred. You can [check](https://rclone.org/commands/rclone_check/) the
integrity of your files. Where possible, rclone employs server-side transfers to minimise local
bandwidth use and transfers from one provider to another without using local disk.

Virtual backends wrap local and cloud file systems to apply [encryption](https://rclone.org/crypt/),
[compression](https://rclone.org/compress/), [chunking](https://rclone.org/chunker/),
[hashing](https://rclone.org/hasher/) and [joining](https://rclone.org/union/).

Rclone [mounts](https://rclone.org/commands/rclone_mount/) any local, cloud or
virtual filesystem as a disk on Windows, macOS, linux and FreeBSD, and also
serves these over [SFTP](https://rclone.org/commands/rclone_serve_sftp/),
[HTTP](https://rclone.org/commands/rclone_serve_http/),
[WebDAV](https://rclone.org/commands/rclone_serve_webdav/),
[FTP](https://rclone.org/commands/rclone_serve_ftp/) and
[DLNA](https://rclone.org/commands/rclone_serve_dlna/).

Rclone is mature, open-source software originally inspired by rsync and written in
[Go](https://golang.org/). The friendly support community is familiar with varied use cases.
Official Ubuntu, Debian, Fedora, Brew and Chocolatey repos. include rclone. For the latest version
[downloading from rclone.org](https://rclone.org/downloads/) is recommended.

Rclone is widely used on Linux, Windows and Mac. Third-party developers create innovative backup,
restore, GUI and business process solutions using the rclone command line or API.

Rclone does the heavy lifting of communicating with cloud storage.

### What can rclone do for you?

Rclone helps you:

* Backup (and encrypt) files to cloud storage

* Restore (and decrypt) files from cloud storage

* Mirror cloud data to other cloud services or locally

* Migrate data to the cloud, or between cloud storage vendors

* Mount multiple, encrypted, cached or diverse cloud storage as a disk

* Analyse and account for data held on cloud storage
  using [lsf](https://rclone.org/commands/rclone_lsf/),
  [ljson](https://rclone.org/commands/rclone_lsjson/),
  [size](https://rclone.org/commands/rclone_size/), [ncdu](https://rclone.org/commands/rclone_ncdu/)

* [Union](https://rclone.org/union/) file systems together to present multiple local and/or cloud
  file systems as one

### Features

* Transfers

    * MD5, SHA1 hashes are checked at all times for file integrity

    * Timestamps are preserved on files

    * Operations can be restarted at any time

    * Can be to and from network, e.g. two different cloud providers

    * Can use multi-threaded downloads to local disk

* [Copy](https://rclone.org/commands/rclone_copy/) new or changed files to cloud storage

* [Sync](https://rclone.org/commands/rclone_sync/) (one way) to make a directory identical

* [Bisync](https://rclone.org/commands/rclone_bisync/) (two way) to keep two directories in sync
  bidirectionally

* [Move](https://rclone.org/commands/rclone_move/) files to cloud storage deleting the local after
  verification

* [Check](https://rclone.org/commands/rclone_check/) hashes and for missing/extra files

* [Mount](https://rclone.org/commands/rclone_mount/) your cloud storage as a network disk

* [Serve](https://rclone.org/commands/rclone_serve/) local or remote
  files over [HTTP](https://rclone.org/commands/rclone_serve_http/)
  / [WebDav](https://rclone.org/commands/rclone_serve_webdav/)
  / [FTP](https://rclone.org/commands/rclone_serve_ftp/) /
  [SFTP](https://rclone.org/commands/rclone_serve_sftp/) /
  [DLNA](https://rclone.org/commands/rclone_serve_dlna/)

* Experimental [Web based GUI](https://rclone.org/gui/)

## Installation

### Rclone

Rclone's macOS installation options are [here](https://rclone.org/install/#macos), but please
[avoid installing via Homebrew](https://github.com/rclone/rclone/issues/5373) and instead follow
the instructions to install a [pre-compiled binary](https://rclone.org/install/#macos-precompiled).
At this time, skip any step involving running `rclone config`, as that's covered later on this
page, and also replace the Rclone download URL with the one corresponding to your CPU architecture
[here](https://rclone.org/downloads/#downloads-for-scripting).

On macOS, depending on the installation method, the `rclone` binary may have the
[`com.apple.quarantine`][1] extended attribute, which needs to be deleted. Delete the extended
attribute by running

``` { .shell .annotate }
xattr -d com.apple.quarantine rclone  # (1)!
```

1. If the `rclone` binary is not in the current directory, replace `rclone` with its actual
   location.

Also, on macOS, grant the `rclone` binary and your terminal app(s) [Full Disk Access][2]. Confirm
Full Disk Access by running the following:

``` shell
sqlite3 \
    '/Library/Application Support/com.apple.TCC/TCC.db' \
    'SELECT client FROM access WHERE auth_value AND service = "kTCCServiceSystemPolicyAllFiles"' \
  | grep -Ei 'rclone|term' \
  | sort -f
```

The output should look similar to this:

``` text
/Users/manselmi/.prefix/bin/rclone
com.apple.Terminal
com.googlecode.iterm2
```

### FUSE-T

On macOS, Rclone leverages [FUSE-T](https://www.fuse-t.org/) to locally mount a remote location.

Please review FUSE-T's installation options [here](https://github.com/macos-fuse-t/fuse-t#readme).

## Example usage and configuration

Suppose you would like to locally mount your VPS home directory (e.g. `/home/ubuntu/`). In this
example you will configure Rclone such that after running a command like

``` shell
rclone mount vps-home: ~/mnt/vps-home/ …
```

any changes within the local directory `~/mnt/vps-home/` will be propagated to the remote directory
`/home/ubuntu/` and vice versa.

### Create SSH key pair

First, create an SSH key pair so that Rclone may SSH to the VPS without requiring user input after
Rclone has been started.

``` shell
ssh-keygen \
  -t ed25519 \
  -C 'Rclone authentication key (Ed25519)' \
  -f ~/.ssh/keys/rclone-auth-ed25519
```

Do not set a passphrase for the private key. The private key will reside within Rclone's
configuration file `~/.config/rclone/rclone.conf`, the entirety of which will be encrypted.

### Append public key to remote `~/.ssh/authorized_keys`

This key pair will be used only by Rclone to run commands remotely, so we can enable all
restrictions (e.g. disable port, agent and X11 forwarding; disable PTY allocation; disable execution
of `~/.ssh/rc`) as described in the [SSH authorized keys file format][3].

Run the following to append the restricted public key to the file `~/.ssh/authorized_keys` within
your VPS home directory.

``` { .shell .annotate }
read -r -d '' SHELL_PROG << 'EOF' || true
# Stop at any error.
set -o errexit

# Create ~/.ssh directory if it doesn't exist.
mkdir -p ~/.ssh

# Append stdin to ~/.ssh/authorized_keys.
cat >> ~/.ssh/authorized_keys

# Restrict ~/.ssh directory permissions.
chmod -R go= ~/.ssh
EOF

printf '%s %s\n' restrict "$(cat ~/.ssh/keys/rclone-auth-ed25519.pub)" \
  | ssh -o RequestTTY=no vps "${SHELL_PROG}"  # (1)!
```

1. Replace `vps` with the actual SSH destination.

### Create Rclone configuration file

First, create an empty Rclone configuration file.

``` shell
mkdir -p ~/.config/rclone
touch ~/.config/rclone/rclone.conf
```

Add the following to `~/.config/rclone/rclone.conf`:

``` { .ini .annotate }
[vps]
type = sftp
host = vps.manselmi.com
user = manselmi
key_pem = XXX  # (1)!
known_hosts_file = ~/.ssh/known_hosts
shell_type = unix
md5sum_command = md5sum
sha1sum_command = sha1sum
chunk_size = 255Ki
concurrency = 1

[vps-home]
type = alias
remote = vps:/home/ubuntu/
```

1. Replace `XXX` with the output of `< ~/.ssh/keys/rclone-auth-ed25519 awk '{printf "%s\\n", $0}'`

Please see the following sections of the Rclone documentation to learn more:

* [rclone config](https://rclone.org/commands/rclone_config/)

* [SFTP](https://rclone.org/sftp/)

* [Alias](https://rclone.org/alias/)

### Encrypt Rclone configuration file

First, generate a random password, which will be printed to standard output.

``` shell
read -r -d '' PYTHON_PROG << 'EOF' || true
import secrets
import string
alphabet = string.ascii_letters + string.digits + string.punctuation
print("".join(secrets.choice(alphabet) for _ in range(64)))
EOF

python -c "${PYTHON_PROG}"
```

Copy the password, then store it in your macOS user's default [keychain][4] by running the following
command and pasting the password when prompted.

``` shell
/usr/bin/security add-generic-password \
  -s rclone \
  -a rclone.conf \
  -w
```

Before moving on, confirm you can retrieve the password from the default keychain.

``` shell
/usr/bin/security find-generic-password \
  -s rclone \
  -a rclone.conf \
  -w
```

### Update shell configuration file

Include the following Rclone password command and helper functions in your shell configuration file,
which on macOS is likely `~/.zshrc`. Afterwards, re-execute the shell configuration file by running
`source ~/.zshrc`.

``` { .shell .annotate }
# https://rclone.org/docs/#configuration-encryption
export RCLONE_PASSWORD_COMMAND='/usr/bin/security find-generic-password -s rclone -a rclone.conf -w'

_rclone-mount() {
  local REMOTE

  if [[ -z "${1-}" ]]; then
    printf '%s\n' 'ERROR: _rclone-mount expects the name of an rclone remote' >&2
    return 1
  fi
  REMOTE="${1}"

  # https://rclone.org/commands/rclone_mount/#fuse-t-limitations-caveats-and-notes
  rclone mount "${REMOTE}:" "${HOME}/mnt/${REMOTE}/" \
    --vfs-cache-mode=full \
    --vfs-write-back=5s \  # (1)!
    --volname="${REMOTE}"
}

# Mount rclone remote "vps-home" to ~/mnt/vps-home/
mnt-vps-home() {
  _rclone-mount vps-home
}
```

1. Time to writeback files after last use when using cache (default `5s`) - adjust as desired

### Encrypt Rclone configuration file

Run `rclone config` to launch the interactive configuration editor, then press `s` to set
configuration password, then press `a` to add password. Provide the password from earlier when
prompted. Press `q` to quit to main menu, then press `q` again to quit the configuration editor.

Confirm that the file has been encrypted by running `less ~/.config/rclone/rclone.conf`. The output
should begin with this:

``` text
# Encrypted rclone configuration File

RCLONE_ENCRYPT_V0:
```

Also, confirm that the file may be decrypted on-demand by running `rclone config redacted`.
Sensitive values will automatically be redacted.

### Delete SSH private key

It's now safe to ~~turn off your computer~~ delete your private key.

``` shell
rm ~/.ssh/keys/rclone-auth-ed25519
```

### Create mount point

Create the local directory to which the remote directory will be mounted.

``` shell
mkdir -p ~/mnt/vps-home
chmod -R go= ~/mnt
```

### Mount remote directory

Run the following:

``` shell
mnt-vps-home
```

In a separate terminal, confirm a successful mount by running this:

``` shell
mount | grep -F vps-home
```

The output should look similar to this:

``` text
fuse-t:/vps-home on /Users/manselmi/mnt/vps-home (nfs, nodev, nosuid, mounted by manselmi)
```

## Additional usage

<!-- material/tags { include: [rclone], toc: false } -->

[1]: https://eclecticlight.co/2023/03/13/ventura-has-changed-app-quarantine-with-a-new-xattr/
[2]: http://kb.mit.edu/confluence/x/oQ6VCQ
[3]: https://man.openbsd.org/sshd#AUTHORIZED_KEYS_FILE_FORMAT
[4]: https://support.apple.com/guide/mac-help/use-keychains-to-store-passwords-mchlf375f392/mac#mchl7e534cc3


<!-- vim: set ft=markdown : -->
