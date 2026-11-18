# md2html-toolkit context

## Goal
Markdown to one self-contained, themed HTML file with pandoc. Works on Linux
and Windows (Git Bash), no network needed to build or view.

## State
- Working: build, outline sidebar, dark/light theme, SVG network diagrams
  (`diagram.lua` + `diagram-runtime.html`, no library), drag-and-drop GUI,
  diagram validation, `tests/smoke.sh` (16 checks, all pass 2026-11-18).
- 2026-11-18: Cytoscape.js replaced by an in-house SVG engine and removed
  (vendored lib, checksum, runtime). Block name is ` ```diagram `;
  ` ```cytoscape ` still accepted for older docs. Classes renamed `cy-*` →
  `dg-*`, env var `CY_DIR` → `MD2HTML_DIR`. Unlock / Copy layout removed:
  devices are always fixed, move them by editing `x`/`y`. Pages ~425 KB
  smaller (Lab 4 demo 884 → 460 KB).
- New look: colors are `--dg-*` CSS tokens at the top of
  `diagram-runtime.html`, light and dark follow the page. Cards show type
  tag, bold name, monospace IP; end tags outlined in their device's color
  (interface bold, IP dim); VLAN name in a tab on the box edge; hover lights
  links in the device's color; parallel links curve apart; SVG text is
  selectable and prints sharp.
- Verified 2026-11-18 in headless Chromium on the real build (dark + light,
  800 and 1400 px): render, click device/link/VLAN, hover highlight,
  Ctrl + wheel zoom, wheel hint, right-drag pan, devices fixed, text-link
  hover tip / click / auto-pin, Esc, Expand. No console errors.
- Not verified with the SVG engine: Pop out (PiP and `window.open`),
  touch/pinch, Firefox/Safari, Windows.
- Earlier features still there: Pin (dock right/top, resizable,
  remembered), Pop out, `[text]{node=id}` links, opt-in `"autolink": true`
  for IPs, details panel lists each device's links, Ctrl + wheel zoom,
  right-drag pan, Fit, embedded Inter + JetBrains Mono.
- Output goes to `outputs/<name>.html` (the GUI saves a copy there too).
  `outputs/` and `examples/` are gitignored. Local demos:
  `examples/lab-workbook-demo.md`, `examples/diagram-demo.md`. The smoke
  test builds its own small doc.
- Headless test browser: Playwright's chromium headless shell. This machine
  lacks libatk and friends, so it runs with `LD_LIBRARY_PATH` pointed at
  libs unpacked in another local project's `.cache/browser-libs/`. Pages
  use smooth scrolling; tests should set `scroll-behavior: auto` first.

## Decisions
- Diagrams: own SVG engine, no library (2026-11-18). Compared Cytoscape,
  JointJS, plain SVG, D3, vis-network, ECharts, G6, Mermaid: hand-placed
  fixed diagrams don't need a layout/graph library, and only SVG allows
  per-part label styling (name vs IP, tags colored by device), CSS theming
  and sharp print. D2 was tried and dropped earlier (35 MB binaries).
- Layouts are hand-placed (`x`/`y`), no auto layout. A device without
  `x`/`y` is put in a row under the rest.
- Page column is `--page-width: 75rem`, diagrams match it. Fit (on load
  and □) never goes above 100%; manual zoom goes 30% to 300%.
- Tried and dropped: Devices/Links tables under diagrams. The table styling
  in `doc-style.css` stays.
- Fonts embedded, not linked: Inter (text) and JetBrains Mono (code, IPs,
  terminal output), Latin subsets in `vendor/fonts/`. Ligatures and code
  italics off so commands show exactly as typed.
- Ctrl + wheel to zoom and right-drag to pan, so normal page scrolling and
  left clicks never move a diagram.

## Gotchas
- `doc-style.css` centers `figure`; `.dg-figure` sets `text-align: left`.
- The `dt`/`dd` margins in `doc-style.css` leaked into the details panel, so
  the panel resets them.
- Card/tag sizes are measured with the real fonts; keep the `FONT` table in
  the runtime script in step with the `.dg` CSS font sizes.
- `color-mix()` needs a 2023+ browser; an `@supports` fallback gives plain
  cards. More in `html_context.md`.
- Needs pandoc 3.1.1+ (`pandoc.json`).

## Next
- User to try the new diagrams on Windows, in Pop out, and in Firefox.
- Nothing committed yet: lock removal, engine swap, renames, docs.
- Ideas: hide a middle label on short links, minimum label size when
  pinned narrow.
- Offered 2026-11-10, not wanted for now: middle-drag pan, keyboard zoom,
  click to copy in the panel, find-a-device box, prompt/output styling in
  console blocks, light/dark toggle, PNG export, browser test in `tests/`.
- Open questions: show IPs in plain text/tables in JetBrains Mono
  automatically (today only with backticks)? Brighter commands after a
  Cisco `#` prompt (the highlighter grays them as comments)?
- Environment type (homelab/dev/prod) not recorded, README says homelab docs.
