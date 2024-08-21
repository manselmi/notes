---
tags:
  - git
  - shell
---

# Git

## Configuration

### Global

* [`~/.gitconfig`]({{ prefix_repo_url("assets/git/.gitconfig") }})

## Tips & tricks

### Identify distinct file extensions

The following command pipeline prints all distinct file extensions, or filenames if the filename has
no extension:

``` shell
find -- . -type d -name .git -prune -o \! -type d -print0 \
  | gawk -v RS='\0' -v ORS='\0' -- '{ match($0, /\/([^\/]+)$/, a); s = a[1]; print match(s, /(\.[^.]+)$/, a) ? a[1] : s }' \
  | sort -fuz \
  | gawk -v RS='\0' -v ORS='\n' -- '{ print gensub(/[^[:print:]]+/, "�", "g") }'
```

This helps with creating gitignore and gitattributes files.

### Debug gitignore patterns

The following command pipeline prints a four-column table that may be useful for debugging gitignore
patterns:

``` shell
find -- . -type d -name .git -prune -o \! -type d -print0 \
  | sort -fz \
  | git check-ignore -nvz --no-index --stdin \
  | gawk -v RS='\0' -v ORS='\n' -- '{ print gensub(/[^[:print:]]+/, "�", "g") }' \
  | paste -s -d '\t\t\t\n' -- - \
  | awk -v FS='\t' -v OFS='\t' -- '{ print $4, $1, $2, $3 }' \
  | column -t -s $'\t'
```

The four columns:

1. path of a file being queried
1. pattern's source file
1. line number of the pattern within that source
1. matching pattern

If some file does not match a gitignore pattern, then all columns except (1) will be empty.

### Debug `text` and `eol` attributes

The following command pipeline prints a four-column table that may be helpful for debugging the
`text` and `eol` attributes. Among other things, it prints the file content identification used by
Git when the `text` attribute is `auto` (or not set and the `core.autocrlf` config option is not
false).

``` shell
read -r -d '' GAWK_PROG << 'EOF' || true
BEGIN {
  RS = "\0"
  OFS = "\t"
  ORS = "\n"
}
{
  match($0, /^([^ ]+) +([^ ]+) +([^\t]+)\t(.+)$/, a)
  a[3] = gensub(/ +$/, "", "g", a[3])
  a[4] = gensub(/[^[:print:]]+/, "�", "g", a[4])
  print a[1], a[2], a[3], a[4]
}
EOF

git ls-files -coz --eol --exclude-standard \
  | gawk -- "${GAWK_PROG}" \
  | sort -f -t $'\t' -k 1,1 -k 2,2 -k 3,3 -k 4,4 \
  | column -t -s $'\t'
```

The four columns:

1. `eolinfo` of the contents in the index for the path. Possible values:

    ``` text
    i/
    i/-text
    i/crlf
    i/lf
    i/mixed
    i/none
    ```

1. `eolinfo` of the contents in the worktree for the path. Possible values:

    ``` text
    w/
    w/-text
    w/crlf
    w/lf
    w/mixed
    w/none
    ```

1. `eolattr` that applies to the path. Possible values:

        eolattr/
        eolattr/-text
        eolattr/text
        eolattr/text eol=crlf
        eolattr/text eol=lf
        eolattr/text=auto
        eolattr/text=auto eol=crlf
        eolattr/text=auto eol=lf

1. path

### Renormalize repository

After modifying a gitattributes file, run the following from a clean working directory:

``` shell
git add --renormalize -- .
git commit -m 'git add --renormalize -- .'
```


<!-- vim: set ft=markdown : -->
