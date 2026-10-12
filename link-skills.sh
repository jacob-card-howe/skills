#!/bin/bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")" && pwd -P)
shopt -s nullglob
skills=("$repo"/skills/*/)

if [ ${#skills[@]} -eq 0 ]; then
  echo 'No skills found in the repository.' >&2
  exit 1
fi
for skill in "${skills[@]}"; do
  if [ ! -f "${skill}SKILL.md" ]; then
    printf 'Missing SKILL.md: %s\n' "$skill" >&2
    exit 1
  fi
done

for agent in "$HOME/.pi/agent" "$HOME/.claude"; do
  mkdir -p "$agent/skills"
  backup=''
  for skill in "${skills[@]}"; do
    target=${skill%/}
    name=${target##*/}
    link="$agent/skills/$name"
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
      continue
    fi
    if [ -e "$link" ] || [ -L "$link" ]; then
      if [ -z "$backup" ]; then
        backup=$(mktemp -d "$agent/skills-backup.$(date +%Y%m%dT%H%M%S).XXXXXX")
        printf 'Backup: %s\n' "$backup"
      fi
      mv "$link" "$backup/$name"
    fi
    ln -s "$target" "$link"
    printf 'Linked: %s -> %s\n' "$link" "$target"
  done
done
