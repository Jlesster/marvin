#!/usr/bin/env bash
# dump_src.sh — print every Rust source file for pasting into Claude
set -euo pipefail

find -name "*.lua" | sort | while read -r f; do
    echo "==== $f ===="
    cat "$f"
    echo ""
done
