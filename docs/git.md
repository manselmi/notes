---
tags:
  - git
  - shell
---

# Git

## Configuration

### Global

* [`~/.gitconfig`]({{ prefix_repo_url("assets/git/.gitconfig") }})

## gitattributes and gitignore tips

The following command pipeline prints all distinct file extensions, or filenames if the filename has
no extension:

``` shell
find -- "$(git rev-parse --show-toplevel)" -type d -name .git -prune -o \! -type d -print0 \
  | gawk -v RS='\0' -v ORS='\0' -- '{ match($0, /\/([^\/]+)$/, a); s = a[1]; print match(s, /(\.[^.]+)$/, a) ? a[1] : s }' \
  | sort -fuz \
  | gawk -v RS='\0' -v ORS='\n' -- '{ print gensub(/[^[:print:]]+/, "�", "g") }'
```

The following command pipeline prints a four-column table that may be useful for debugging gitignore
patterns:

``` shell
find -- "$(git rev-parse --show-toplevel)" -type d -name .git -prune -o \! -type d -print0 \
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


<!-- vim: set ft=markdown : -->
