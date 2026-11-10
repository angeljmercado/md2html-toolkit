# md2html-toolkit context

## Goal
Markdown to one self-contained, themed HTML file with pandoc. Works on Linux
and Windows (Git Bash), no network needed to build or view.

## State
- Working: build, outline sidebar, dark/light theme, Cytoscape.js diagrams,
  drag-and-drop GUI, diagram validation, `tests/smoke.sh`.
- Added 2026-11-09 for following lab workbooks: diagram Pin (dock
  right/top, resizable, remembered) and Pop out (Document PiP, `window.open`
  fallback); text-to-diagram links (`[text]{node=id}`, opt-in
  `"autolink": true` for IPs); link end labels next to their own device
  (interface over IP); VLAN titles under the box; details panel lists each
  device's links; lock button shows the action (Unlock/Lock). Local demo:
  `examples/lab-workbook-demo.md`.
- Changed 2026-11-10: zoom is Ctrl + wheel (or pinch), a plain wheel
  scrolls the page and flashes a "Ctrl + scroll to zoom" hint; Expanded or
  popped out a plain wheel zooms. Pan is right-drag (touch keeps one-finger
  pan). Fit button (□) already existed. Fonts: Inter + JetBrains Mono
  embedded from `vendor/fonts/` (subsets, ligatures off, ~370 KB per page),
  tables use tabular digits, no italics anywhere in code. Checked in
  headless Chromium (dark + light): fonts load, diagram waits for them,
  wheel/hint/Expand/right-drag behave, 0 italic elements in code. Demos
  now include a `show ip route` table and a font check block.
- Checked in headless Chromium at 800, 1400, 1600 and 3840 px: pin/unpin,
  Esc, Expand while pinned, resize grip, reload restore, click-to-pin, hover
  both ways, pop out + dock (PiP and `window.open`), label placement.
  Not checked: Firefox/Safari, Windows, a real PiP window on a desktop.
- Windows: tested by the user before the 2026-11-10 changes, works. Linux:
  checked in headless Chromium (render, alignment, click panel,
  lock/unlock, zoom, Copy layout, Expand, GUI build) at 1000 to 3840 px.
- Not verified: touch input.
- Output goes to `outputs/<name>.html` (the GUI saves a copy there too).
  `outputs/` and `examples/` are gitignored. The smoke test builds its own
  small doc, it does not use `examples/`.
- Headless test browser: Playwright's chromium headless shell. This machine
  lacks libatk and friends, so it runs with `LD_LIBRARY_PATH` pointed at
  libs unpacked in another local project's `.cache/browser-libs/`.

## Decisions
- Cytoscape.js is the only diagram tool. I tried D2 and removed it: its
  binaries were 35 MB (99% of the repo) and it gave less control.
- Layouts are hand-placed (`x`/`y`), no ELK/dagre, to stay light.
- Page column is `--page-width: 75rem`, diagrams match it. Fit (on load
  and □) never goes above 100%; manual zoom goes 30% to 300%.
- Diagram colors are bright on purpose (white labels, light links, tinted
  cards) so they read well on black.
- Tried and dropped: Devices/Links tables under diagrams. The table styling
  in `doc-style.css` stays.
- Cytoscape.js 3.34.4 is vendored (436 KB), hash in `vendor/SHA256SUMS`.
- Fonts embedded, not linked: Inter (text) and JetBrains Mono (code, IPs,
  terminal output), Latin subsets in `vendor/fonts/`. Inter over Roboto:
  made for screens, aligned digits. Ligatures and code italics off so
  commands show exactly as typed.
- Ctrl + wheel to zoom and right-drag to pan, so normal page scrolling and
  left clicks never move a diagram.

## Gotchas
- Cytoscape's `width: label` is deprecated and left some nodes zero-sized
  (blank diagram), so card size is computed from the text.
- `doc-style.css` centers `figure`, which pushed the canvases sideways.
  `.cy-figure` sets `text-align: left`.
- The `dt`/`dd` margins in `doc-style.css` leaked into the details panel, so
  the panel resets them.
- Needs pandoc 3.1.1+ (`pandoc.json`).

## Next
- Try pin/pop out, the new wheel/pan and the fonts on Windows and in
  Firefox.
- Ideas: hide a middle label on short links, minimum label size when
  pinned narrow, auto layout.
- Offered 2026-11-10, not wanted for now: middle-drag pan, keyboard zoom,
  click to copy in the panel, find-a-device box, prompt/output styling in
  console blocks, light/dark toggle, PNG export, browser test in `tests/`.
- Open questions: show IPs in plain text/tables in JetBrains Mono
  automatically (today only with backticks)? Brighter commands after a
  Cisco `#` prompt (the highlighter grays them as comments)?
- Environment type (homelab/dev/prod) not recorded, README says homelab docs.
