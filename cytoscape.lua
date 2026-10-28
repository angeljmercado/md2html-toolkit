-- Turns ```cytoscape blocks (JSON) into interactive diagrams.
-- The library and runtime get inlined once per page, and only if the doc has a block.
-- Needs CY_DIR (build.sh sets it) to find vendor/cytoscape and cytoscape-runtime.html.
local dir = os.getenv("CY_DIR")
local used = false

local function slurp(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("a")
  f:close()
  return s
end

local function render(el)
  if not el.classes:includes("cytoscape") then return nil end
  local ok, model = pcall(pandoc.json.decode, el.text, false)
  if not ok or type(model) ~= "table" then
    io.stderr:write("cytoscape.lua: block is not valid JSON, leaving as code\n")
    return nil
  end
  used = true
  local json = el.text:gsub("</", "<\\/")
  local title = type(model.title) == "string" and model.title or ""
  title = title:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
  return pandoc.RawBlock("html",
    '<figure class="cy-figure">' ..
    (title ~= "" and ('<div class="cy-title">' .. title .. '</div>') or "") ..
    '<div class="cy-tools"><button class="cy-copy" data-a="copy" hidden>Copy layout</button><button class="cy-lock" data-a="lock"></button><button class="cy-expand" data-a="expand">Expand</button><button data-a="in" title="Zoom in">+</button>' ..
    '<button data-a="out" title="Zoom out">&minus;</button>' ..
    '<button data-a="fit" title="Fit to view">&#9633;</button></div>' ..
    '<div class="cy-canvas"></div><div class="cy-panel" hidden></div>' ..
    '<div class="cy-hint">click a device for details &middot; scroll to zoom &middot; drag the background to pan &middot; Unlock to move items</div>' ..
    '<script type="application/json">' .. json .. '</script></figure>')
end

local function finish(doc)
  if not used then return nil end
  if not dir or dir == "" then
    io.stderr:write("cytoscape.lua: CY_DIR not set, diagrams will not render\n")
    return nil
  end
  local lib = slurp(dir .. "/vendor/cytoscape/cytoscape.min.js")
  local rt = slurp(dir .. "/cytoscape-runtime.html")
  if not lib or not rt then
    io.stderr:write("cytoscape.lua: vendored library or runtime missing\n")
    return nil
  end
  local i, j = rt:find("/*CYTOSCAPE_LIB*/", 1, true)
  rt = rt:sub(1, i - 1) .. lib .. rt:sub(j + 1)
  doc.blocks:insert(pandoc.RawBlock("html", rt))
  return doc
end

return { { CodeBlock = render }, { Pandoc = finish } }
