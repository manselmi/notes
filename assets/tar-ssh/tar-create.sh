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
#   awk → gawk (GNU awk)
#   find → gfind (GNU find)
#   sed → gsed (GNU sed)
#   tar → gtar (GNU tar)
#
# https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-whence
if [[ "${OSTYPE}" == darwin* ]]; then
  awk() { "$(whence -p gawk)" "${@}" ; }
  find() { "$(whence -p gfind)" "${@}" ; }
  sed() { "$(whence -p gsed)" "${@}" ; }
  tar() { "$(whence -p gtar)" --format=posix "${@}" ; }
fi

# For each input pathname such as
#
#   foo/bar/baz
#
# print
#
#   foo
#   foo/bar
#   foo/bar/baz
#
# When combined with GNU tar's `--no-recursion` option, this allows us to ensure inclusion of parent
# directories in order to, upon extraction and if necessary, create missing parent directories with
# correct ownership and permissions.
#
# https://www.gnu.org/software/tar/manual/html_section/recurse.html
# https://serverfault.com/a/877313
read -r -d '' AWK_PROG << 'EOF' || true
BEGIN {
  FS = "/"
  RS = "\0"
  ORS = "\0"
}
{
  path_component = $1
  for (i = 2; i <= NF; i++) {
    print path_component
    path_component = path_component "/" $i
  }
  print path_component
}
EOF

# 1. `sed`: Accept null-byte-terminated pathnames from stdin and strip a leading slash (`/`) from
#    each pathname.
#
# 2. `find`: Relative to ${TAR_DIRECTORY}, search the directory trees rooted at the supplied
#    pathnames and print the pathnames of directories, regular files and symlinks pointing to
#    directories or regular files. Suppress warnings regarding nonexistent files.
#
# 3. `awk`: Run the AWK program described above if ${TAR_PARENT_DIRS} is non-empty, otherwise no-op.
#
# 4. `sort`: Sort and deduplicate pathnames.
#
# 5. `tar`: Archive files with given pathnames relative to ${TAR_DIRECTORY}, suppressing warnings
#    regarding files that cannot be read. Print the archive to stdout.
typeset -a TAR_PARENT_DIRS_CMD
TAR_PARENT_DIRS_CMD=('cat')
if [[ -n "${TAR_PARENT_DIRS-}" ]]; then
  TAR_PARENT_DIRS_CMD=('awk' '--' "${AWK_PROG}")
fi
sed -z -- 's|^/||' \
  | (
      pushd -q -- "${TAR_DIRECTORY}"
      find -- -files0-from - -xtype d,f -print0 2> /dev/null
    ) \
  | "${TAR_PARENT_DIRS_CMD[@]}" \
  | env -- LC_ALL=POSIX sort -uz \
  | tar \
      -cf - \
      ${TAR_USER_MAP:+"--owner-map=${TAR_USER_MAP}"} \
      ${TAR_GROUP_MAP:+"--group-map=${TAR_GROUP_MAP}"} \
      --directory="${TAR_DIRECTORY}" \
      --format=posix \
      --ignore-failed-read \
      --warning=no-failed-read \
      --no-recursion \
      --sort=none \
      --null \
      --files-from=-
