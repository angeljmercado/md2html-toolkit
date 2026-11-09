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
- Checked in headless Chromium at 800, 1400, 1600 and 3840 px: pin/unpin,
  Esc, Expand while pinned, resize grip, reload restore, click-to-pin, hover
  both ways, pop out + dock (PiP and `window.open`), label placement.
  Not checked: Firefox/Safari, Windows, a real PiP window on a desktop.
- Windows: tested by the user, works. Linux: checked in headless Chromium
  (render, alignment, click panel, lock/unlock, wheel zoom, Copy layout,
  Expand, GUI build) at widths from 1000 to 3840 px.
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
- Page column is `--page-width: 75rem`, diagrams match it, zoom never goes
  above 100%.
- Diagram colors are bright on purpose (white labels, light links, tinted
  cards) so they read well on black.
- Tried and dropped: Devices/Links tables under diagrams. The table styling
  in `doc-style.css` stays.
- Cytoscape.js 3.34.4 is vendored (436 KB), hash in `vendor/SHA256SUMS`.

## Gotchas
- Cytoscape's `width: label` is deprecated and left some nodes zero-sized
  (blank diagram), so card size is computed from the text.
- `doc-style.css` centers `figure`, which pushed the canvases sideways.
  `.cy-figure` sets `text-align: left`.
- The `dt`/`dd` margins in `doc-style.css` leaked into the details panel, so
  the panel resets them.
- Needs pandoc 3.1.1+ (`pandoc.json`).

## Next
- Try pin/pop out on Windows and in Firefox.
- Ideas: hide a middle label on short links, minimum label size when
  pinned narrow, click to copy an IP in the panel, find-a-device box.
- Optional: PNG export, auto layout.
- Environment type (homelab/dev/prod) not recorded, README says homelab docs.
