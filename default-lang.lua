-- Every code block gets syntax colors. Blocks with no language label,
-- or a plain-text label, are highlighted as bash; real language labels
-- (python, yaml, ...) keep their own highlighting.
local plain = {
  text = true, plain = true, txt = true,
  log = true, output = true, console = true,
}
function CodeBlock(el)
  if #el.classes == 0 or plain[el.classes[1]:lower()] then
    el.classes = { "bash" }
  end
  return el
end
