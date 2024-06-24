---
tags:
  - shell
  - ssh
---

# tar over SSH

## Introduction

As described on my [backup](/backup.md) page, I headlessly manage backups of my family's Macs over
SSH, and occasionally I need to add or update configuration files, scripts and binaries. Instead
of dealing with files individually, I prefer to transfer all relevant files in one operation, make
changes locally, then transfer everything back in one operation, preserving file ownership and
permissions. This is possible by running tar over SSH.

What follows is an example of managing backup-related files on a family member's Mac laptop.

## Example

!!! note

    All commands are run on my own Mac, not on the remote Mac.

Set some shell variables that we'll reference throughout.

``` { .shell .annotate }
SSH_ALIAS=foo-mac  # (1)!
MANIFEST_ORIGINAL="${SSH_ALIAS}.original.manifest"  # (2)!
MANIFEST_MODIFIED="${SSH_ALIAS}.modified.manifest"  # (3)!
TAR_ORIGINAL="${SSH_ALIAS}.original.tar"  # (4)!
TAR_MODIFIED="${SSH_ALIAS}.modified.tar"  # (5)!
USER_MAP="${SSH_ALIAS}.user.map"  # (6)!
GROUP_MAP="${SSH_ALIAS}.group.map"  # (7)!
```

1. This is an SSH host alias in `~/.ssh/config` such that I can SSH to the remote Mac via `ssh
   foo-mac`.

2. This file is a manifest of remote files and directories to transfer locally.

3. This file is a manifest of local files and directories to transfer remotely.

4. This file is a TAR of the files in `${MANIFEST_ORIGINAL}`.

5. This file is a TAR of the files in `${MANIFEST_MODIFIED}` to be transferred remotely.

6. This file maps local user IDs to user names and user IDs within the TAR.

7. This file maps local group IDs to group names and group IDs within the TAR.

Before going further, define these shell functions as aliases of the following programs.

* `awk` → `gawk` (GNU awk)
* `find` → `gfind` (GNU find)
* `sed` → `gsed` (GNU sed)
* `tar` → `gtar` (GNU tar)

``` shell
awk() { "$(whence -p gawk)" "${@}" ; }
find() { "$(whence -p gfind)" "${@}" ; }
sed() { "$(whence -p gsed)" "${@}" ; }
tar() { "$(whence -p gtar)" --format=posix "${@}" ; }
```

Create a file manifest…

``` shell
touch -- "${MANIFEST_ORIGINAL}"
```

…and add resolved absolute pathnames of the files to archive. Pathnames must not have a trailing
slash.

``` text title="foo-mac.original.manifest"
# vim: set ft=cfg :


/Library/Preferences/com.soma-zone.LaunchControl.fdautil.plist
/Users/foo/.config/rclone
/Users/foo/.config/resticprofile
/Users/foo/Library/LaunchAgents/com.manselmi.resticprofile.foo_mac.backup.plist
/usr/local/bin/exec-rclone
/usr/local/bin/exec-resticprofile
/usr/local/bin/rclone
/usr/local/bin/restic
/usr/local/bin/resticprofile
```

Create this Zsh script, which accepts pathnames on stdin and emits a TAR on stdout. See comments for
details.

``` shell title="tar-create.sh"
--8<-- "docs/assets/tar-ssh/tar-create.sh"
```

Run the script remotely over SSH, optionally piping the output through [Pipe
Viewer](http://www.ivarch.com/programs/pv.shtml) to monitor throughput. Here,
[`printf`](https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-printf) is a Zsh
builtin.

``` shell
< "${MANIFEST_ORIGINAL}" \
    sed -E -- '/^[[:blank:]]*(#|$)/d' \
  | tr '\n' '\0' \
  | ssh -o RequestTTY=no -- "${SSH_ALIAS}" sudo -- env -- \
      PATH='/var/manselmi/.prefix/bin:/var/manselmi/.prefix/sw/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
      TAR_DIRECTORY=/ \
      TAR_PARENT_DIRS=1 \
      zsh -fc "$(printf '%q' "$(< tar-create.sh)")" \
  | pv -W \
  > "${TAR_ORIGINAL}"
```

We now have a TAR we can inspect. List the archive members and ensure what's needed is present.

``` shell
tar -tf "${TAR_ORIGINAL}" --verbose | less -S
```

``` text
drwxr-xr-x root/wheel        0 2024-01-06 00:10 Library/
drwxr-xr-x root/wheel        0 2024-01-20 21:25 Library/Preferences/
-rw-r--r-- root/wheel      420 2024-01-19 14:30 Library/Preferences/com.soma-zone.LaunchControl.fdautil.plist
drwxr-xr-x root/admin        0 2024-01-05 21:35 Users/
drwxr-x--- foo/staff         0 2024-01-20 21:26 Users/foo/
drwxr-xr-x foo/staff         0 2024-01-20 21:25 Users/foo/.config/
drwxr-xr-x foo/staff         0 2024-01-05 20:56 Users/foo/.config/rclone/
-rw------- foo/staff       602 2024-01-14 22:25 Users/foo/.config/rclone/rclone.conf
drwxr-xr-x foo/staff         0 2024-01-19 14:30 Users/foo/.config/resticprofile/
drwxr-xr-x foo/staff         0 2024-01-14 22:28 Users/foo/.config/resticprofile/curlrc/
-rw-r--r-- foo/staff       192 2024-01-05 20:30 Users/foo/.config/resticprofile/curlrc/foo_mac
drwxr-xr-x foo/staff         0 2024-01-14 22:28 Users/foo/.config/resticprofile/exclude/
-rw-r--r-- foo/staff       984 2023-12-18 08:22 Users/foo/.config/resticprofile/exclude/base.txt
-rw-r--r-- foo/staff       813 2024-01-06 04:03 Users/foo/.config/resticprofile/exclude/foo_mac.txt
drwxr-xr-x foo/staff         0 2024-01-14 22:28 Users/foo/.config/resticprofile/log/
drwxr-xr-x foo/staff         0 2023-08-20 18:02 Users/foo/.config/resticprofile/log/foo_mac/
-rw-r--r-- foo/staff      4695 2024-01-20 14:03 Users/foo/.config/resticprofile/log/foo_mac/backup.log
-rw-r--r-- foo/staff      2994 2024-01-19 14:30 Users/foo/.config/resticprofile/profiles.toml
drwxr-xr-x foo/staff         0 2024-01-14 22:31 Users/foo/.config/resticprofile/status/
-rw-r--r-- foo/staff      2461 2024-01-20 14:03 Users/foo/.config/resticprofile/status/foo_mac.json
drwx------ foo/staff         0 2024-01-07 16:41 Users/foo/Library/
drwx------ foo/staff         0 2024-01-14 22:30 Users/foo/Library/LaunchAgents/
-rw-r--r-- foo/staff      1005 2024-01-14 22:30 Users/foo/Library/LaunchAgents/com.manselmi.resticprofile.foo_mac.backup.plist
drwxr-xr-x root/wheel        0 2023-12-15 09:43 usr/
drwxr-xr-x root/wheel        0 2024-01-06 03:57 usr/local/
drwxr-xr-x root/wheel        0 2024-01-14 22:05 usr/local/bin/
-rwxr-xr-x root/wheel      397 2024-01-05 22:53 usr/local/bin/exec-rclone
-rwxr-xr-x root/wheel      533 2024-01-05 22:53 usr/local/bin/exec-resticprofile
-rwxr-xr-x root/wheel 73065456 2024-01-08 06:19 usr/local/bin/rclone
-rwxr-xr-x root/wheel 27146176 2024-01-14 17:43 usr/local/bin/restic
-rwxr-xr-x root/wheel 16102320 2023-10-24 11:54 usr/local/bin/resticprofile
```

Before extracting the archive, print a deduplicated table of member user IDs, group IDs, user names
and group names. We'll need this later.

``` shell
paste \
    <(
      tar -tf "${TAR_ORIGINAL}" --quoting-style=escape --verbose --numeric-owner \
        | tr -s '[[:blank:]]' '\t' \
        | cut -f 2
    ) \
    <(
      tar -tf "${TAR_ORIGINAL}" --quoting-style=escape --verbose \
        | tr -s '[[:blank:]]' '\t' \
        | cut -f 2
    ) \
  | awk -F '[[:blank:]/]' -- '{ print $1, $2, $3, $4 }' \
  | {
      printf '%s\t%s\t%s\t%s\n' UID GID UNAME GNAME
      sort -u -k 1,1n -k 2,2n
    } \
  | column -t
```

``` text
UID  GID  UNAME  GNAME
0    0    root   wheel
0    80   root   admin
501  20   foo    staff
```

Create this Zsh script. See comments for details.

``` shell title="tar-extract.sh"
--8<-- "docs/assets/tar-ssh/tar-extract.sh"
```

Create the directory `${SSH_ALIAS}` and extract the archive into it, preserving member ownership and
permission.

``` shell
sudo -- rm -fr -- "${SSH_ALIAS}"
mkdir -- "${SSH_ALIAS}"
< "${TAR_ORIGINAL}" sudo -- env -- TAR_DIRECTORY="${SSH_ALIAS}" ./tar-extract.sh
```

We're now ready to create or modify files as needed. `sudo` may be required to view or modify files
not owned by our user.

``` shell
sudo -u \#501 -g \#20 -- mkdir -- "${SSH_ALIAS}/Users/foo/.config/foo"
sudo -u \#501 -g \#20 -- touch -- "${SSH_ALIAS}/Users/foo/.config/foo/bar"
sudo -u \#501 -g \#20 -- touch -- "${SSH_ALIAS}/Users/foo/.config/foobar"
pushd -q -- "${SSH_ALIAS}/Users/foo/.config"
sudo -u \#501 -g \#20 -- ln -s foo baz
popd -q
```

Now that we've modified the necessary files, let's prepare to archive them. First, make a copy the
original manifest and add any new files to include them in the archive. Pathnames must not have a
trailing slash.

``` shell
cp -- "${MANIFEST_ORIGINAL}" "${MANIFEST_MODIFIED}"

cat >> "${MANIFEST_MODIFIED}" << 'EOF'
/Users/foo/.config/baz
/Users/foo/.config/foo
/Users/foo/.config/foobar
EOF
```

``` text title="foo-mac.modified.manifest"
# vim: set ft=cfg :


/Library/Preferences/com.soma-zone.LaunchControl.fdautil.plist
/Users/foo/.config/rclone
/Users/foo/.config/resticprofile
/Users/foo/Library/LaunchAgents/com.manselmi.resticprofile.foo_mac.backup.plist
/usr/local/bin/exec-rclone
/usr/local/bin/exec-resticprofile
/usr/local/bin/rclone
/usr/local/bin/restic
/usr/local/bin/resticprofile
/Users/foo/.config/baz
/Users/foo/.config/foo
/Users/foo/.config/foobar
```

Create files that [map](https://www.gnu.org/software/tar/manual/html_node/override.html) local user
names/IDs to remote user names and user IDs, and local group names/IDs to remote group names and
group IDs, respectively.

``` text title="foo-mac.user.map"
+0 root:0
+501 foo:501
```

``` text title="foo-mac.group.map"
+0 wheel:0
+20 staff:20
+80 admin:80
```

Ensure no executable regular file has the `com.apple.quarantine` extended attribute.

``` shell
sudo -- gfind -- "${SSH_ALIAS}" \
  -type f -perm /u=x,g=x,o=x -exec xattr -d com.apple.quarantine -- {} +
```

Create the archive.

``` shell
< "${MANIFEST_MODIFIED}" \
    sed -E -- '/^[[:blank:]]*(#|$)/d' \
  | tr '\n' '\0' \
  | sudo -- env -- \
      TAR_DIRECTORY="${SSH_ALIAS}" \
      TAR_USER_MAP="${USER_MAP}" \
      TAR_GROUP_MAP="${GROUP_MAP}" \
      ./tar-create.sh \
  > "${TAR_MODIFIED}"
```

Diff the original and modified archives as a sanity check. For example, are ownership and
permissions correct?

``` shell
tar-list() {
  tar -tf "${1}" --quoting-style=escape --verbose \
    | sed -E -- ':a; /^([^\t]*\t){5,}/ b; s/ +/\t/; ta' \
    | cut -f 1-2,6-
}

diff -u --color=always <(tar-list "${TAR_ORIGINAL}") <(tar-list "${TAR_MODIFIED}") | less -RS
```

``` diff
--- /dev/fd/11  2024-01-20 21:36:07.050059294 -0500
+++ /dev/fd/12  2024-01-20 21:36:07.050322332 -0500
@@ -1,9 +1,8 @@
-drwxr-xr-x     root/wheel      Library/
-drwxr-xr-x     root/wheel      Library/Preferences/
 -rw-r--r--     root/wheel      Library/Preferences/com.soma-zone.LaunchControl.fdautil.plist
-drwxr-xr-x     root/admin      Users/
-drwxr-x---     foo/staff       Users/foo/
-drwxr-xr-x     foo/staff       Users/foo/.config/
+lrwxr-xr-x     foo/staff       Users/foo/.config/baz -> foo
+drwxr-xr-x     foo/staff       Users/foo/.config/foo/
+-rw-r--r--     foo/staff       Users/foo/.config/foo/bar
+-rw-r--r--     foo/staff       Users/foo/.config/foobar
 drwxr-xr-x     foo/staff       Users/foo/.config/rclone/
 -rw-------     foo/staff       Users/foo/.config/rclone/rclone.conf
 drwxr-xr-x     foo/staff       Users/foo/.config/resticprofile/
@@ -18,12 +17,7 @@
 -rw-r--r--     foo/staff       Users/foo/.config/resticprofile/profiles.toml
 drwxr-xr-x     foo/staff       Users/foo/.config/resticprofile/status/
 -rw-r--r--     foo/staff       Users/foo/.config/resticprofile/status/foo_mac.json
-drwx------     foo/staff       Users/foo/Library/
-drwx------     foo/staff       Users/foo/Library/LaunchAgents/
 -rw-r--r--     foo/staff       Users/foo/Library/LaunchAgents/com.manselmi.resticprofile.foo_mac.backup.plist
-drwxr-xr-x     root/wheel      usr/
-drwxr-xr-x     root/wheel      usr/local/
-drwxr-xr-x     root/wheel      usr/local/bin/
 -rwxr-xr-x     root/wheel      usr/local/bin/exec-rclone
 -rwxr-xr-x     root/wheel      usr/local/bin/exec-resticprofile
 -rwxr-xr-x     root/wheel      usr/local/bin/rclone
```

!!! warning

    Observe that unlike when we created the original archive on the remote machine, here we choose
    not to archive the parent directories of items in our manifest. This is because we assume that
    for every TAR member the corresponding parent directories already exist on the remote system. If
    this turns out not to be the case, add the required parent directories to the manifest.

    For example, if you add a new regular file `Users/foo/a/b/c.conf`, then append all of these
    lines to the manifest:

    ``` text
    /Users/foo/a
    /Users/foo/a/b
    /Users/foo/a/b/c.conf
    ```

    `/Users` and `/Users/foo` need not be added because we know those directories already exist on
    the remote system.

Everything looks good, so delete the extracted files.

``` shell
sudo -- rm -fr -- "${SSH_ALIAS}"
```

Extract the TAR remotely over SSH.

``` shell
pv -W -- "${TAR_MODIFIED}" \
  | ssh -o RequestTTY=no -- "${SSH_ALIAS}" sudo -- env -- \
      PATH='/var/manselmi/.prefix/bin:/var/manselmi/.prefix/sw/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' \
      TAR_DIRECTORY=/ \
      zsh -fc "$(printf '%q' "$(< tar-extract.sh)")"
```


<!-- vim: set ft=markdown : -->
