#!/usr/bin/env bash
# Usage: prepare.sh <tag>
# Splits .github/release-notes/<tag>.md into a title and a body file and
# writes them as step outputs (name, body_path). Without a notes file both
# outputs are empty, so the caller falls back to generated notes.
set -euo pipefail

tag=$1
file="$(dirname "$0")/$tag.md"
out=${GITHUB_OUTPUT:-/dev/stdout}

if [ ! -f "$file" ]; then
  echo "No $file; using generated notes."
  { echo "name="; echo "body_path="; } >> "$out"
  exit 0
fi

title=$(head -n 1 "$file" | sed 's/^# *//')
body="${RUNNER_TEMP:-/tmp}/release-body.md"
# Everything after the title line, minus leading blank lines.
tail -n +2 "$file" | sed '/./,$!d' > "$body"

[ -n "$title" ] || { echo "::error::$file has an empty title line"; exit 1; }
[ -s "$body" ] || { echo "::error::$file has no description"; exit 1; }

{ echo "name=$title"; echo "body_path=$body"; } >> "$out"
