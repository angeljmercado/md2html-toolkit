#!/bin/bash
# build.sh — turn a Markdown doc into one self-contained themed HTML file.
# Usage: ./build.sh <doc.md> [output.html]   (default: outputs/<doc>.html)
# Finds its own assets, so the toolkit folder can live anywhere.
set -euo pipefail

TOOLKIT="$(cd "$(dirname "$0")" && pwd)"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "Error: pandoc is not installed (apt/dnf install pandoc)" >&2
  exit 1
fi

# cytoscape.lua needs pandoc.json, added in pandoc 3.1.1.
PANDOC_VER="$(pandoc --version | head -1 | awk '{print $2}')"
if [ "$(printf '%s\n3.1.1\n' "$PANDOC_VER" | sort -V | head -1)" != "3.1.1" ]; then
  echo "Error: pandoc $PANDOC_VER is too old; 3.1.1 or newer is required" >&2
  exit 1
fi

if [ $# -lt 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <doc.md> [output.html]" >&2
  exit 1
fi

export CY_DIR="$TOOLKIT"   # cytoscape.lua reads vendor/cytoscape from here

# On Windows (Git Bash) pandoc can't read POSIX-style paths, so convert this one.
if command -v cygpath >/dev/null 2>&1; then
  export CY_DIR="$(cygpath -m "$CY_DIR")"
fi

SRC="$1"
if [ $# -ge 2 ]; then
  OUT="$2"
else
  BASE="$(basename "$SRC")"; BASE="${BASE%.md}"; BASE="${BASE%.markdown}"
  mkdir -p "$TOOLKIT/outputs"
  OUT="$TOOLKIT/outputs/$BASE.html"
fi

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
  --lua-filter "$TOOLKIT/cytoscape.lua" \
  --lua-filter "$TOOLKIT/default-lang.lua" \
  --css "$TOOLKIT/doc-style.css" \
  --include-after-body "$TOOLKIT/toc-sidebar.html" \
  --include-after-body "$TOOLKIT/copy-code.html" \
  --include-after-body "$TOOLKIT/page-extras.html" \
  --include-after-body "$FOOTER" \
  --metadata pagetitle="$TITLE" \
  --toc --toc-depth=3 \
  -o "$OUT"

echo "Built $OUT"
