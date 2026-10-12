-- Rewrites Quarto callouts as Jupyter/IBM-style alert boxes when the output
-- format is ipynb, e.g.:
--   <div class="alert alert-block alert-success"><b>&#128161; Tip</b> ... </div>
-- Other formats are left untouched.

if FORMAT ~= 'ipynb' then
  return {}
end

-- callout type -> bootstrap alert class and HTML entity (icon)
-- Edit here to tweak the mapping.
local map = {
  note      = { class = 'alert-info',    icon = '&#128221;',         title = 'Note' },      -- memo
  tip       = { class = 'alert-success', icon = '&#128161;',         title = 'Tip' },       -- light bulb
  warning   = { class = 'alert-warning', icon = '&#9888;&#65039;',   title = 'Warning' },   -- warning sign
  caution   = { class = 'alert-warning', icon = '&#128679;',         title = 'Caution' },   -- construction
  important = { class = 'alert-danger',  icon = '&#10071;',          title = 'Important' }, -- exclamation
}

-- Quarto hands filters callouts as `Callout` custom nodes (not Divs), with
-- fields: type, title (Inlines/Plain or nil), content (Blocks), collapse
-- (true/false/nil), icon (true/false), appearance.
local function title_inlines(callout, default)
  local t = callout.title
  if t == nil then
    return pandoc.Inlines({ pandoc.Str(default) })
  end
  if t.t == 'Plain' or t.t == 'Para' then t = t.content end
  if #t == 0 then
    return pandoc.Inlines({ pandoc.Str(default) })
  end
  return t
end

-- callout.content may be a single Block (usually a Div) or a list of Blocks
-- (or nil for a title-only callout)
local function body_blocks(content)
  if content == nil then return pandoc.List() end
  if content.t == 'Div' then return content.content end
  if content.t ~= nil then return pandoc.List({ content }) end
  return content
end

local function md(blocks)
  return (pandoc.write(pandoc.Pandoc(blocks), 'markdown'):gsub('%s+$', ''))
end

local function html(blocks)
  return (pandoc.write(pandoc.Pandoc(blocks), 'html'):gsub('%s+$', ''))
end

-- Executable code chunks arrive as Divs with class `cell`; they must stay
-- top-level so the ipynb writer turns them into real code cells.
local function is_cell(block)
  return block.t == 'Div' and block.classes:includes('cell')
end

-- One complete alert box as a single markdown string (HTML wrapper and
-- markdown body separated by blank lines so Jupyter parses the body).
-- `heading` is a string or nil; `summary` (string) makes the box collapsible.
local function box(class, heading, body, summary, open)
  local parts = { '<div class="alert alert-block ' .. class .. '">', '' }
  if summary then
    table.insert(parts, '<details' .. open .. '><summary>' .. summary .. '</summary>')
    table.insert(parts, '')
  elseif heading then
    table.insert(parts, heading)
    table.insert(parts, '')
  end
  if body ~= '' then
    table.insert(parts, body)
    table.insert(parts, '')
  end
  if summary then
    table.insert(parts, '</details>')
    table.insert(parts, '')
  end
  table.insert(parts, '</div>')
  return pandoc.Para({ pandoc.RawInline('markdown', table.concat(parts, '\n')) })
end

function Callout(callout)
  local m = map[callout.type]
  if not m then return nil end

  local title = title_inlines(callout, m.title)
  local prefix = (callout.icon ~= false) and (m.icon .. '&nbsp;') or ''
  local body = body_blocks(callout.content)

  -- Split the body around code cells.
  local segments, current, has_cell = {}, pandoc.List(), false
  for _, b in ipairs(body) do
    if is_cell(b) then
      has_cell = true
      if #current > 0 then table.insert(segments, { blocks = current }) end
      current = pandoc.List()
      table.insert(segments, { cell = b })
    else
      current:insert(b)
    end
  end
  if #current > 0 then table.insert(segments, { blocks = current }) end

  local heading = '<b>' .. prefix .. md({ pandoc.Plain(title) }) .. '</b>'

  -- No code cells: one box, collapsible if requested and there is a body.
  if not has_cell then
    local text = md(body)
    if callout.collapse ~= nil and text ~= '' then
      local open = (callout.collapse == false) and ' open' or ''
      local summary = '<b>' .. prefix .. html({ pandoc.Plain(title) }) .. '</b>'
      return box(m.class, nil, text, summary, open)
    end
    return box(m.class, heading, text)
  end

  -- Code cells present: markdown segments become separate boxes around the
  -- cells (cannot collapse across a code cell). Title goes on the first box.
  local out = pandoc.List()
  local titled = false
  for _, seg in ipairs(segments) do
    if seg.cell then
      if not titled then
        out:insert(box(m.class, heading, ''))
        titled = true
      end
      out:insert(seg.cell)
    else
      out:insert(box(m.class, (not titled) and heading or nil, md(seg.blocks)))
      titled = true
    end
  end
  return out
end
