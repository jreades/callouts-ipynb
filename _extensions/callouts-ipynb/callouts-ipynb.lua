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
local function body_blocks(content)
  if content.t == 'Div' then return content.content end
  if content.t ~= nil then return pandoc.List({ content }) end
  return content
end

function Callout(callout)
  local m = map[callout.type]
  if not m then return nil end

  local function md(blocks)
    return (pandoc.write(pandoc.Pandoc(blocks), 'markdown'):gsub('%s+$', ''))
  end
  local function html(blocks)
    return (pandoc.write(pandoc.Pandoc(blocks), 'html'):gsub('%s+$', ''))
  end

  local title = title_inlines(callout, m.title)
  local prefix = (callout.icon ~= false) and (m.icon .. '&nbsp;') or ''
  local body = md(body_blocks(callout.content))
  local parts = { '<div class="alert alert-block ' .. m.class .. '">', '' }
  if callout.collapse ~= nil then
    -- collapse=true -> closed by default; collapse=false -> open but collapsible
    local open = (callout.collapse == false) and ' open' or ''
    table.insert(parts, '<details' .. open .. '><summary><b>' .. prefix ..
      html({ pandoc.Plain(title) }) .. '</b></summary>')
    table.insert(parts, '')
    table.insert(parts, body)
    table.insert(parts, '')
    table.insert(parts, '</details>')
  else
    table.insert(parts, '<b>' .. prefix .. md({ pandoc.Plain(title) }) .. '</b>')
    table.insert(parts, '')
    table.insert(parts, body)
  end
  table.insert(parts, '')
  table.insert(parts, '</div>')

  return pandoc.Para({ pandoc.RawInline('markdown', table.concat(parts, '\n')) })
end
