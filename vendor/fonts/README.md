# Fonts

Embedded into every built page by `doc-style.css` (pandoc inlines them), so
pages look the same everywhere, offline. Both are SIL OFL-1.1, see the
`LICENSE-*.txt` files. Neither declares a Reserved Font Name.

| File | Source |
|------|--------|
| `inter-var.woff2`, `inter-var-italic.woff2` | Inter 4.1, `InterVariable*.ttf` from `Inter-4.1.zip` (github.com/rsms/inter, release v4.1) |
| `jetbrains-mono-var*.woff2` | JetBrains Mono 2.304, `fonts/variable/JetBrainsMono*[wght].ttf` from `JetBrainsMono-2.304.zip` (github.com/JetBrains/JetBrainsMono, release v2.304) |

Release zip SHA-256 when downloaded (2026-11-10):

```text
9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e  Inter-4.1.zip
6f6376c6ed2960ea8a963cd7387ec9d76e3f629125bc33d1fdcd7eb7012f7bbf  JetBrainsMono-2.304.zip
```

## How they were made

Cut down to keep each built page small (about 270 KB for all four files):

- Characters: Latin, punctuation, currency, arrows, math, box drawing
  (`tree`-style output) and a few symbols. Anything else falls back to a
  system font.
- Inter: optical size pinned at 14 (the text design), weight stays variable.
- JetBrains Mono: `calt` dropped, so no coding ligatures (`->`, `!=` stay
  as typed), even in the diagram canvas where CSS can't turn them off.

Needs `fonttools` and `brotli` (`pip install fonttools brotli`). Run from
the folder with the unzipped fonts:

```bash
U="U+0000-017F,U+0192,U+02C6-02DC,U+0300-0308,U+2000-206F,U+20A0-20CF,U+2100-2122,U+2190-21FF,U+2200-22FF,U+2300-23FF,U+2500-259F,U+25A0-25FF,U+2713-2717,U+FEFF,U+FFFD"
IF="kern,mark,mkmk,ccmp,locl,calt,case,tnum,pnum,zero,frac,numr,dnom,sups,subs"
JF="kern,mark,mkmk,ccmp,locl,case,zero,frac,sups,subs"
for f in InterVariable InterVariable-Italic; do
  fonttools varLib.instancer "$f.ttf" opsz=14 -o "$f-opsz14.ttf"
done
pyftsubset InterVariable-opsz14.ttf --unicodes="$U" --layout-features="$IF" --flavor=woff2 --output-file=inter-var.woff2
pyftsubset InterVariable-Italic-opsz14.ttf --unicodes="$U" --layout-features="$IF" --flavor=woff2 --output-file=inter-var-italic.woff2
pyftsubset "JetBrainsMono[wght].ttf" --unicodes="$U" --layout-features="$JF" --flavor=woff2 --output-file=jetbrains-mono-var.woff2
pyftsubset "JetBrainsMono-Italic[wght].ttf" --unicodes="$U" --layout-features="$JF" --flavor=woff2 --output-file=jetbrains-mono-var-italic.woff2
```
