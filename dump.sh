#!/usr/bin/env bash
# dump_repo.sh
# Run from the root of your marvin repo:
#   bash dump_repo.sh > marvin_dump.md
# Then paste marvin_dump.md contents to Claude.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT_FILE="marvin_dump.md"

# File extensions to include
INCLUDE_EXT=("lua" "vim" "toml" "json" "yaml" "yml" "sh" "md" "txt" "nix")

# Dirs/files to skip
SKIP_PATTERNS=(".git" "node_modules" "*.zip" "*.png" "*.jpg" "*.gif")

should_skip() {
  local path="$1"
  for pat in "${SKIP_PATTERNS[@]}"; do
    case "$path" in
      *"$pat"*) return 0 ;;
    esac
  done
  return 1
}

has_ext() {
  local file="$1"
  local ext="${file##*.}"
  for e in "${INCLUDE_EXT[@]}"; do
    [[ "$ext" == "$e" ]] && return 0
  done
  return 1
}

{
  echo "# marvin — full source dump"
  echo ""
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "Repo: $REPO_ROOT"
  echo ""
  echo "---"
  echo ""

  # Directory tree overview
  echo "## Directory Tree"
  echo ""
  echo '```'
  if command -v tree &>/dev/null; then
    tree -a --noreport -I '.git|node_modules|*.zip' "$REPO_ROOT"
  else
    find "$REPO_ROOT" -not -path '*/.git/*' -not -name '*.zip' | sort | sed "s|$REPO_ROOT/||"
  fi
  echo '```'
  echo ""
  echo "---"
  echo ""

  # File contents
  echo "## File Contents"
  echo ""

  while IFS= read -r -d '' file; do
    rel="${file#$REPO_ROOT/}"

    should_skip "$rel" && continue
    has_ext "$file"  || continue

    ext="${file##*.}"
    echo "### \`$rel\`"
    echo ""
    echo "\`\`\`$ext"
    cat "$file"
    echo ""
    echo "\`\`\`"
    echo ""
  done < <(find "$REPO_ROOT" -type f -print0 | sort -z)

} > "$OUTPUT_FILE"

echo "Done! → $OUTPUT_FILE  ($(wc -l < "$OUTPUT_FILE") lines)" >&2
