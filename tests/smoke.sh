#!/bin/bash
# Quick check: build a small doc and make sure the output looks right.
# Usage: tests/smoke.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP" "$ROOT/outputs/smoke-$$.html"' EXIT
fail=0
check() { if eval "$2"; then echo "ok    $1"; else echo "FAIL  $1"; fail=1; fi; }

cat > "$TMP/doc.md" <<'MD'
# Smoke test

```cytoscape
{"title": "t", "nodes": [{"id": "a", "x": 0, "y": 0}, {"id": "b", "x": 200, "y": 0}],
 "edges": [{"from": "a", "to": "b", "src": "eth0", "dst": "eth1"}]}
```

```bash
echo hello
```

| A | B |
|---|---|
| 1 | 2 |
MD

"$ROOT/build.sh" "$TMP/doc.md" "$TMP/doc.html" >"$TMP/log" 2>&1
check "builds" "[ -s '$TMP/doc.html' ]"
check "no external references" "[ \"\$(grep -cE '(href|src)=\"(https?:|[^#\"])' '$TMP/doc.html')\" = 0 ]"
check "diagram present" "[ \"\$(grep -c 'class=\"cy-figure\"' '$TMP/doc.html')\" = 1 ]"
check "code block highlighted" "grep -q 'class=\"sourceCode' '$TMP/doc.html'"
check "table present" "grep -q '<table' '$TMP/doc.html'"
check "no filter warnings" "! grep -q 'cytoscape.lua:' '$TMP/log'"

cp "$TMP/doc.md" "$TMP/smoke-$$.md"
"$ROOT/build.sh" "$TMP/smoke-$$.md" >/dev/null 2>&1
check "default output goes to outputs/" "[ -s '$ROOT/outputs/smoke-$$.html' ]"

printf '# t\n\n```cytoscape\n{"nodes":[{"id":"a"}],"edges":[{"from":"a","to":"missing"}]}\n```\n' > "$TMP/bad.md"
check "bad edge fails the build" "! '$ROOT/build.sh' '$TMP/bad.md' '$TMP/bad.html' >'$TMP/bad.log' 2>&1 && grep -q \"unknown\" '$TMP/bad.log'"

check "vendored files match SHA256SUMS" "(cd '$ROOT/vendor' && sha256sum -c --quiet SHA256SUMS)"

[ $fail = 0 ] && echo "All checks passed." || { echo "Some checks FAILED."; exit 1; }
