# md2html-toolkit

Turn a Markdown file into a single self-contained HTML page with one
command. The output is one file with everything embedded — open it in any
browser, copy it anywhere, no internet or installs needed to view it.

I use this for homelab documentation: write the doc in Markdown, build the
HTML when I want a version that is easy to read and share.

## What you get

- Collapsible outline sidebar with the doc's headers, highlights the
  section you are reading
- Dark theme (pitch black, magenta accents) and light theme, follows
  the system setting
- Copy button on every code block, Laserwave-style magenta syntax
  colors in dark mode
- Interactive diagrams (Cytoscape.js): click, hover, zoom, pan
- "Generated <date>" footer so you can tell when a build is stale
- Print-friendly — use the browser's Print > Save as PDF for a PDF

## Requirements

Only `pandoc` 3.1.1 or newer, and only on the machine doing the build:

```bash
sudo apt install pandoc   # or: sudo dnf install pandoc
```

Cytoscape.js is already in `vendor/`. Viewers just need a browser. Works on
Linux and on Windows (run `build.sh` from Git Bash).

## Usage

```bash
./build.sh mydoc.md              # builds outputs/mydoc.html in the toolkit folder
./build.sh mydoc.md out.html     # custom output path
```

The tab title comes from the doc's first `# H1`. Unlabeled code blocks and
plain-text labels (` ```text `, ` ```console `) are colored as bash. Label a
block (` ```yaml `, ` ```python `) to get another language.

**GUI:** `./start-gui.sh` (Windows: `start-gui.bat`) opens a local page in
your browser. Drop `.md` files on it or click Browse. Each one is built with
`build.sh`, offered as a download, and saved in `outputs/`. Needs Python 3.
Images linked by relative path are not included.

Check a build is fully self-contained (must print 0):

```bash
grep -cE '(href|src)="(https?:|[^#"])' mydoc.html
```

## Diagrams

Put JSON in a ` ```cytoscape ` block and place each device with `x`/`y`:

````
```cytoscape
{
  "title": "Example",
  "nodes": [
    {"id": "core", "label": "Core Switch", "sub": "192.168.1.2", "type": "switch",
     "x": 0, "y": 100, "details": {"Ports": "24x 1G", "STP": "root"}},
    {"id": "pve1", "label": "Proxmox 1", "sub": "10.10.10.11", "type": "server",
     "x": 300, "y": 100, "details": {"RAM": "64 GB"}}
  ],
  "edges": [
    {"from": "core", "to": "pve1", "src": "Gi1/0/10", "dst": "eno1 10.10.10.11/24",
     "details": {"Mode": "access VLAN 10"}}
  ]
}
```
````

- **Node:** `id`, `label`, `x`/`y`, plus optional `sub` (second line),
  `type` (`internet`, `firewall`, `switch`, `server`, `storage`, `client`,
  `ap`), `parent` (put it inside a group node, like a VLAN) and `details`.
- **Edge:** `from`, `to`, plus optional `label` (middle), `src`/`dst` (labels
  at each end, good for interface and IP), `dashed`, `arrow` and `details`.
- **Block:** optional `title`, and `height` if you don't want the automatic one.
- **In the page:** click a device or link for its details, hover to highlight
  its links, scroll to zoom, drag the background to pan, **Expand** for full
  window.
- **Moving things:** devices are locked by default. Hit **Unlocked** to drag
  them, then **Copy layout** to copy the JSON with the new positions and paste
  it back into the Markdown.
- Bad JSON, an unknown node in an edge, a duplicate id or an unknown parent
  fails the build with a message.

## Files

| File | What it is |
|------|------------|
| `build.sh` | The build command |
| `gui.py`, `gui.html`, `start-gui.*` | Drag-and-drop GUI |
| `doc-style.css` | Layout, light/dark theme, syntax colors (`--page-width` sets the column width) |
| `toc-sidebar.html`, `page-extras.html` | Outline sidebar and scroll highlighting |
| `copy-code.html` | Copy buttons |
| `default-lang.lua` | Forces syntax colors on every code block (bash by default) |
| `cytoscape.lua`, `cytoscape-runtime.html` | Diagrams: validation, rendering, behavior |
| `vendor/` | Cytoscape.js 3.34.4 and its `SHA256SUMS` |
| `tests/smoke.sh` | Quick check: builds a small doc and verifies the output |
| `html_context.md` | Full reference: how it works, theme colors, gotchas |

`outputs/` (generated HTML) and `examples/` are local only and not in Git.
Markdown stays the source of truth. Rebuild after every edit — the HTML does
not update itself.
