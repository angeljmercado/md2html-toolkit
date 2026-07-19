#!/bin/bash
# build.sh — turn a Markdown doc into one self-contained themed HTML file.
# Usage: ./build.sh <doc.md> [output.html]
# Finds its own assets, so the toolkit folder can live anywhere.
set -euo pipefail

TOOLKIT="$(cd "$(dirname "$0")" && pwd)"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "Error: pandoc is not installed (apt/dnf install pandoc)" >&2
  exit 1
fi

if [ $# -lt 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <doc.md> [output.html]" >&2
  exit 1
fi

SRC="$1"
OUT="${2:-${SRC%.md}.html}"

# Browser-tab title: the doc's first H1, falling back to the filename.
TITLE="$(grep -m1 '^# ' "$SRC" | sed 's/^# //')"
TITLE="${TITLE:-$(basename "${SRC%.md}")}"

# Footer stamp so a stale build is visible at a glance.
FOOTER="$(mktemp)"
trap 'rm -f "$FOOTER"' EXIT
printf '<footer class="doc-footer">Generated %s from %s</footer>\n' \
  "$(date '+%Y-%m-%d %H:%M')" "$(basename "$SRC")" > "$FOOTER"

pandoc "$SRC" \
  --standalone --embed-resources \
  --css "$TOOLKIT/doc-style.css" \
  --include-after-body "$TOOLKIT/toc-sidebar.html" \
  --include-after-body "$TOOLKIT/copy-code.html" \
  --include-after-body "$TOOLKIT/page-extras.html" \
  --include-after-body "$FOOTER" \
  --metadata pagetitle="$TITLE" \
  --toc --toc-depth=3 \
  -o "$OUT"

echo "Built $OUT"
