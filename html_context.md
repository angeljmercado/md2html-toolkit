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
  - `default-lang.lua` — pandoc filter: every code block gets syntax
    colors — unlabeled and plain-text labels (`text`, `console`, ...)
    are highlighted as bash; real language labels keep their own
  - `page-extras.html` — scroll-spy highlight in the outline

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
| Colors | design tokens at the top of `doc-style.css` (two `:root` blocks: light, then dark inside `@media`) — all assets read them via `var(--…)` |

## Dark theme

Pitch-black neutral surfaces with magenta reserved for accents; syntax
colors are the **Laserwave** palette (github.com/Jaredk3nt/laserwave).
The principle: never tint code backgrounds or body text — magenta
appears in small, deliberate places (links, H1 bar, "Outline" label,
active TOC entry, commands in code) plus a faint magenta tint on
interactive surfaces (buttons, table headers, hovers). Roughly: ~90%
neutral black/white, ~10% magenta family; yellow/violet/aqua appear only
inside code blocks. Light mode is a separate GitHub-light-ish palette
with CSS `darkmagenta` as its accent, and follows the system theme
automatically.

All colors are CSS custom properties in the two `:root` blocks at the top
of `doc-style.css`; the sidebar/copy-button/extras assets reference them
with `var(--…)`. Dark values:

| Token | Role | Color |
|-------|------|-------|
| `--bg` | Page background | `#000000` |
| `--surface` | Code blocks, sidebar, zebra rows (neutral) | `#0d0d12` |
| `--surface-2` / `--hover-bg` | Buttons, table headers / hovers (magenta-tinted) | `#1f1320` / `#2a1526` |
| `--border` / `--border-soft` | Borders | `#26262e` / `#1f1f26` |
| `--fg` | Body text and headings | `#f8f8f2` |
| `--fg-soft` / `--fg-muted` | Sidebar links, blockquotes / footer, captions, language badge | `#b3b3bd` / `#7a7a85` |
| `--accent` / `--accent-hover` | Magenta (links, H1 underline bar, "Outline" label, hovers) | `#eb64b9` / `#ff52bf` |

Laserwave syntax mapping (pandoc token classes): functions/commands/flags
`.fu/.ex/.at` `#eb64b9` hot pink · keywords/imports `.kw/.cf/.im`
`#40b4c4` maximum blue · strings `.st/.vs/.ch/.ss` `#b4dce7` powder blue
· numbers/constants `.dv/.bn/.fl/.cn` `#b381c5` african violet · types
`.dt` violet italic · variables `.va` `#ffffff` white ·
builtins/preprocessor `.bu/.pp` `#ffe261` mustard · operators
`.op/.ot/.sc` `#74dfc4` pearl aqua · comments/docs
`.co/.an/.cv/.do/.in/.re/.wa` `#91889b` old lavender italic · errors
`.er/.al` `#ff5555` red. A `code span` catch-all makes any unmapped class
fall back to bright foreground instead of pandoc's dark-on-dark defaults.
Note: true CSS `darkmagenta` (`#8b008b`) is too dark to read on black,
so dark mode uses Laserwave's magenta for text accents; `darkmagenta`
is the light-mode accent instead.

Beyond code: tables get borders, header background, zebra rows, and
horizontal scroll when wide; blockquotes get a purple left border; images
are capped at `max-width: 100%`; `kbd`, `hr`, figures, and definition
lists are styled.

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
