# md2html-toolkit

Turn a Markdown file into a single self-contained HTML page with one
command. The output is one file with everything embedded — open it in any
browser, copy it anywhere, no internet or installs needed to view it.

I use this for homelab documentation: write the doc in Markdown, build the
HTML when I want a version that is easy to read and share.

## What you get

- Collapsible outline sidebar with the doc's headers, highlights the
  section you are reading
- Dark theme (pitch black, Dracula-style accents) and light theme,
  follows the system setting
- Copy button on every code block
- Anchor links on headers for sharing direct links to a section
- "Generated <date>" footer so you can tell when a build is stale
- Print-friendly — use the browser's Print > Save as PDF for a PDF

## Requirements

Only `pandoc`, and only on the machine doing the build:

```bash
sudo apt install pandoc   # or: sudo dnf install pandoc
```

Viewers need nothing — just a browser.

## Usage

```bash
./build.sh mydoc.md              # builds mydoc.html next to it
./build.sh mydoc.md out.html     # custom output path
```

The script finds its own assets, so the toolkit folder can live anywhere.
The browser-tab title comes from the doc's first `# H1`.

Verify the output is fully self-contained (must print 0):

```bash
grep -cE '(href|src)="(https?:|[^#"])' mydoc.html
```

## Files

| File | What it is |
|------|------------|
| `build.sh` | The build command |
| `doc-style.css` | Layout, light/dark theme, syntax colors |
| `toc-sidebar.html` | Outline sidebar |
| `copy-code.html` | Copy buttons |
| `page-extras.html` | Header anchor links, scroll highlighting |
| `html_context.md` | Full reference: how it works, theme colors, customization, gotchas |

Markdown stays the source of truth. Rebuild after every edit — the HTML
does not update itself.
