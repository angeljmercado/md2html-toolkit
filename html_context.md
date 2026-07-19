# Building Portable HTML Documentation

Convert a Markdown doc into one self-contained HTML file with an outline
sidebar, dark mode, syntax highlighting, and copy buttons. Markdown is the
source of truth — regenerate the HTML after every edit.

## Requirements

- **pandoc** (`apt/dnf install pandoc`) — the build machine's only
  dependency; viewers of the generated HTML need nothing
- This **`html_toolkit/`** folder — the whole toolkit, self-contained for
  backup:
  - `build.sh` — the build command; finds its own assets, so the folder
    can live anywhere
  - `doc-style.css` — layout, light/dark theme, dark-mode syntax palette
  - `toc-sidebar.html` — collapsible outline panel (with scroll-spy
    highlight of the current section)
  - `copy-code.html` — Copy button on code blocks
  - `page-extras.html` — hover ¶ anchor links on headings, scroll-spy

The assets are embedded into the HTML at build time; the finished file
never references them again.

## Build

```bash
/path/to/html_toolkit/build.sh <name>.md            # output: <name>.html
/path/to/html_toolkit/build.sh <name>.md out.html   # custom output path
```

The script derives the browser-tab title from the doc's first H1 and stamps
a "Generated <date>" footer so stale builds are visible. The underlying
pandoc flags live in `build.sh`; the non-obvious ones:

- `--embed-resources` inlines everything → one portable file
- `pagetitle=` sets the tab title only; `title=` would duplicate the H1
- `--toc` emits `<nav id="TOC">`, which the sidebar asset restyles

Verify self-containment (must print 0 — only `#anchor` links remain):

```bash
grep -cE '(href|src)="(https?:|[^#"])' <name>.html
```

## Tweaks (all one-liners)

| What | Where |
|------|-------|
| Content width (`46rem`) | `body` in `doc-style.css` |
| Sidebar width (`270px`) | `toc-sidebar.html` (nav width + margin calc) |
| Sidebar auto-open breakpoint (`1100px`) | `toc-sidebar.html` (media query + JS) |
| Outline depth | `--toc-depth=N` |
| Colors | `doc-style.css` (dark mode = the `@media` block) |

## Dark theme

Pitch-black neutral surfaces with purple reserved for accents; syntax
colors are the **Dracula** palette (draculatheme.com). The principle: never
tint backgrounds or body text purple — purple only appears in small,
deliberate places. Light mode is a separate GitHub-light-ish palette and
follows the system theme automatically.

Surfaces and text (all in `doc-style.css` dark block; sidebar/copy-button
variants in their own assets):

| Role | Color |
|------|-------|
| Page background | `#000000` |
| Code block / sidebar background | `#0d0d12` / `#0a0a0d` |
| Borders | `#26262e` / `#1f1f26` |
| Body text / headings | `#e8e8e8` / `#f8f8f2` |
| Accent purple (links, H1 underline bar, `$VARIABLES`, "Outline" label, hovers) | `#bd93f9` |

Dracula syntax mapping (pandoc token classes): keywords `.kw/.cf`
`#ff79c6` pink · functions `.fu` `#50fa7b` green · strings `.st` `#f1fa8c`
yellow · variables/numbers `.va/.dv` `#bd93f9` purple · builtins `.bu/.ot`
`#8be9fd` cyan · preprocessor `.pp` `#ffb86c` orange · comments `.co`
`#6272a4` blue-gray italic · errors `.er/.al` `#ff5555` red.

## Gotchas (why the assets look the way they do)

- Pandoc's syntax colors are for light backgrounds — the dark-mode
  `code span.XX` overrides in `doc-style.css` keep commands readable.
- Pandoc puts horizontal scrolling on the outer `div.sourceCode`, letting
  wide code slide out of the `pre`'s styled box — `doc-style.css` moves
  the scrollbar onto the `pre` itself.
- The Copy button must sit on a non-scrolling wrapper, never inside the
  scrolling `pre`, or it slides away with the code — `copy-code.html`
  handles this.
- Generated HTML goes stale silently — regenerate after editing the
  Markdown. Print → Save as PDF for a PDF; sidebar/buttons auto-hide.
