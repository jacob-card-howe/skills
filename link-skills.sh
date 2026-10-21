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

backup=''
backup_dir=''
# link_path <destination dir> <link name> <target>. Conflicting entries move to a
# unique backup directory beside the destination, so a scanned dir never holds one.
link_path() {
  local dest link target
  dest=$1
  link="$dest/$2"
  target=$3
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    return 0
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    if [ "$backup_dir" != "$dest" ]; then
      backup=$(mktemp -d "$(dirname "$dest")/$(basename "$dest")-backup.$(date +%Y%m%dT%H%M%S).XXXXXX")
      backup_dir=$dest
      printf 'Backup: %s\n' "$backup"
    fi
    mv "$link" "$backup/$2"
  fi
  ln -s "$target" "$link"
  printf 'Linked: %s -> %s\n' "$link" "$target"
}

for agent in "$HOME/.pi/agent" "$HOME/.claude"; do
  mkdir -p "$agent/skills"
  backup=''
  backup_dir=''
  for skill in "${skills[@]}"; do
    target=${skill%/}
    link_path "$agent/skills" "${target##*/}" "$target"
  done
done

# pstack is a Pi-only fork of github.com/cursor/plugins/pstack. Its skills name Pi
# tools, agents, and model-file paths, so they are never linked into Claude.
if [ -d "$repo/pstack/skills" ]; then
  if [ ! -f "$repo/pstack/skills/poteto-mode/SKILL.md" ]; then
    printf 'Missing SKILL.md: %s\n' "$repo/pstack/skills/poteto-mode" >&2
    exit 1
  fi
  mkdir -p "$HOME/.pi/agent/skills" "$HOME/.pi/agent/agents"
  backup=''
  backup_dir=''
  link_path "$HOME/.pi/agent/skills" pstack "$repo/pstack/skills"
  for subagent in "$repo"/pstack/agents/*.md; do
    link_path "$HOME/.pi/agent/agents" "${subagent##*/}" "$subagent"
  done
fi
