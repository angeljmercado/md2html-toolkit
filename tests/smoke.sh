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

```diagram
{"title": "t", "nodes": [{"id": "a", "x": 0, "y": 0}, {"id": "b", "x": 200, "y": 0}],
 "edges": [{"from": "a", "to": "b", "src": "eth0", "dst": "eth1"}]}
```

See [node a]{node=a} and [both]{node="a b"}.

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
check "diagram present" "[ \"\$(grep -c 'class=\"dg-figure\"' '$TMP/doc.html')\" = 1 ]"
check "diagram runtime inlined" "grep -q 'function make(m, host, uid)' '$TMP/doc.html'"
check "no leftover Cytoscape" "! grep -qi 'cytoscape' '$TMP/doc.html'"
check "code block highlighted" "grep -q 'class=\"sourceCode' '$TMP/doc.html'"
check "table present" "grep -q '<table' '$TMP/doc.html'"
check "node reference rendered" "grep -q 'class=\"dg-ref\" data-node=\"a b\"' '$TMP/doc.html'"
check "pin and pop-out buttons" "grep -q 'data-a=\"pin\"' '$TMP/doc.html' && grep -q 'data-a=\"pop\"' '$TMP/doc.html'"
check "4 fonts embedded" "[ \"\$(grep -o 'font/woff2;base64' '$TMP/doc.html' | wc -l)\" -ge 4 ] && ! grep -q 'vendor/fonts/' '$TMP/doc.html'"
check "no filter warnings" "! grep -q 'diagram.lua:' '$TMP/log'"

cp "$TMP/doc.md" "$TMP/smoke-$$.md"
"$ROOT/build.sh" "$TMP/smoke-$$.md" >/dev/null 2>&1
check "default output goes to outputs/" "[ -s '$ROOT/outputs/smoke-$$.html' ]"

printf '# t\n\n```cytoscape\n{"nodes":[{"id":"a","x":0,"y":0}]}\n```\n' > "$TMP/old.md"
"$ROOT/build.sh" "$TMP/old.md" "$TMP/old.html" >/dev/null 2>&1
check "older cytoscape block name still works" "grep -q 'class=\"dg-figure\"' '$TMP/old.html'"

printf '# t\n\n```diagram\n{"nodes":[{"id":"a"}],"edges":[{"from":"a","to":"missing"}]}\n```\n' > "$TMP/bad.md"
check "bad edge fails the build" "! '$ROOT/build.sh' '$TMP/bad.md' '$TMP/bad.html' >'$TMP/bad.log' 2>&1 && grep -q \"unknown\" '$TMP/bad.log'"

printf '# t\n\n```diagram\n{"nodes":[{"id":"a"}]}\n```\n\nSee [x]{node=nope}.\n' > "$TMP/badref.md"
check "unknown node reference fails the build" "! '$ROOT/build.sh' '$TMP/badref.md' '$TMP/badref.html' >'$TMP/badref.log' 2>&1 && grep -q \"unknown node 'nope'\" '$TMP/badref.log'"

check "vendored files match SHA256SUMS" "(cd '$ROOT/vendor' && sha256sum -c --quiet SHA256SUMS)"

[ $fail = 0 ] && echo "All checks passed." || { echo "Some checks FAILED."; exit 1; }
