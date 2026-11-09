-- Turns ```cytoscape blocks (JSON) into interactive diagrams.
-- The library and runtime get inlined once per page, and only if the doc has a block.
-- Needs CY_DIR (build.sh sets it) to find vendor/cytoscape and cytoscape-runtime.html.
local dir = os.getenv("CY_DIR")
local used = false
local known = {}  -- node ids from every diagram, to check [text]{node=id} references

local function slurp(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("a")
  f:close()
  return s
end

-- Fail the build with a clear message instead of drawing a broken diagram.
local function validate(m)
  local function fail(msg) error("cytoscape block: " .. msg, 0) end
  if m.autolink ~= nil and type(m.autolink) ~= "boolean" then fail('"autolink" must be true or false') end
  if type(m.nodes) ~= "table" or #m.nodes == 0 then fail('"nodes" must be a non-empty list') end
  local ids = {}
  for i, n in ipairs(m.nodes) do
    if type(n.id) ~= "string" or n.id == "" then fail("node #" .. i .. ' needs a string "id"') end
    if ids[n.id] then fail("duplicate node id '" .. n.id .. "'") end
    ids[n.id] = true
  end
  for _, n in ipairs(m.nodes) do
    if n.parent ~= nil and not ids[n.parent] then
      fail("node '" .. n.id .. "' has unknown parent '" .. tostring(n.parent) .. "'")
    end
  end
  for i, e in ipairs(m.edges or {}) do
    for _, k in ipairs({ "src", "dst" }) do
      local v = e[k]
      local ok = v == nil or type(v) == "string"
      if type(v) == "table" then
        ok = true
        for _, line in ipairs(v) do if type(line) ~= "string" then ok = false end end
      end
      if not ok then fail("edge #" .. i .. ' "' .. k .. '" must be a string or a list of strings') end
    end
    for _, end_ in ipairs({ "from", "to" }) do
      if not ids[e[end_]] then
        fail("edge #" .. i .. " has unknown \"" .. end_ .. "\" node '" .. tostring(e[end_]) .. "'")
      end
    end
  end
end

local function render(el)
  if not el.classes:includes("cytoscape") then return nil end
  local ok, model = pcall(pandoc.json.decode, el.text, false)
  if not ok or type(model) ~= "table" then
    error("cytoscape block: not valid JSON (" .. tostring(model):sub(1, 120) .. ")", 0)
  end
  validate(model)
  for _, n in ipairs(model.nodes) do known[n.id] = true end
  used = true
  local json = el.text:gsub("</", "<\\/")
  local title = type(model.title) == "string" and model.title or ""
  title = title:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
  return pandoc.RawBlock("html",
    '<figure class="cy-figure">' ..
    (title ~= "" and ('<div class="cy-title">' .. title .. '</div>') or "") ..
    '<div class="cy-tools"><button class="cy-copy" data-a="copy" hidden>Copy layout</button><button class="cy-lock" data-a="lock"></button><button class="cy-pin" data-a="pin" title="Keep the diagram on screen while you scroll">Pin</button><button class="cy-pop" data-a="pop" title="Open the diagram in its own window">Pop out</button><button class="cy-expand" data-a="expand">Expand</button><button data-a="in" title="Zoom in">+</button>' ..
    '<button data-a="out" title="Zoom out">&minus;</button>' ..
    '<button data-a="fit" title="Fit to view">&#9633;</button></div>' ..
    '<div class="cy-canvas"></div><div class="cy-panel" hidden></div>' ..
    '<div class="cy-hint">click a device for details &middot; scroll to zoom &middot; drag the background to pan &middot; Pin to keep it beside the text</div>' ..
    '<script type="application/json">' .. json .. '</script></figure>')
end

-- [text]{node=id} in the text links to a diagram node: hover highlights it,
-- click opens its details. Several ids ("r1 r2") highlight them and the links
-- between them.
local function ref(el)
  local v = el.attributes.node
  if v == nil then return nil end
  local text = pandoc.utils.stringify(el)
  if v:match("^%s*$") then error("[" .. text .. "]{node=...}: empty node id", 0) end
  for id in v:gmatch("%S+") do
    if not known[id] then
      error("[" .. text .. "]{node=" .. v .. "}: unknown node '" .. id .. "'", 0)
    end
  end
  el.attributes.node = nil
  el.attributes["data-node"] = v
  el.classes:insert("cy-ref")
  return el
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

return { { CodeBlock = render }, { Span = ref }, { Pandoc = finish } }
