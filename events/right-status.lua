local wezterm = require("wezterm")
local math = require("utils.math")
local M = {}

M.separator_char = " ~ "

M.colors = {
  date_fg = "#3E7FB5",
  date_bg = "#0F2536",
  battery_fg = "#B52F90",
  battery_bg = "#0F2536",
  separator_fg = "#786D22",
  separator_bg = "#0F2536",
  close_fg = "#FF5C57", -- 添加关闭按钮颜色
  close_bg = "#0F2536", -- 添加关闭按钮背景
}

M.cells = {} -- wezterm FormatItems (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)

---@param text string
---@param icon string
---@param fg string
---@param bg string
---@param separate boolean
M.push = function(text, icon, fg, bg, separate)
  table.insert(M.cells, { Foreground = { Color = fg } })
  table.insert(M.cells, { Background = { Color = bg } })
  table.insert(M.cells, { Attribute = { Intensity = "Bold" } })
  table.insert(M.cells, { Text = icon .. " " .. text .. " " })

  if separate then
    table.insert(M.cells, { Foreground = { Color = M.colors.separator_fg } })
    table.insert(M.cells, { Background = { Color = M.colors.separator_bg } })
    table.insert(M.cells, { Text = M.separator_char })
  end

  table.insert(M.cells, "ResetAttributes")
end

M.set_date = function()
  local date = wezterm.strftime(" %a %H:%M")
  M.push(date, "", M.colors.date_fg, M.colors.date_bg, true)
end

M.set_battery = function()
  -- ref: https://wezfurlong.org/wezterm/config/lua/wezterm/battery_info.html
  local discharging_icons = { "󰂃", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹" }
  local charging_icons = { "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅" }

  local charge = ""
  local icon = ""

  for _, b in ipairs(wezterm.battery_info()) do
    local idx = math.clamp(math.round(b.state_of_charge * 10), 1, 10)
    charge = string.format("%.0f%%", b.state_of_charge * 100)

    if b.state == "Charging" then
      icon = charging_icons[idx]
    else
      icon = discharging_icons[idx]
    end
  end

  M.push(charge, icon, M.colors.battery_fg, M.colors.battery_bg, false)
end

-- 添加关闭按钮函数
M.set_close_button = function()
  -- 创建可点击的关闭按钮
  table.insert(M.cells, { Foreground = { Color = M.colors.close_fg } })
  table.insert(M.cells, { Background = { Color = M.colors.close_bg } })
  table.insert(M.cells, { Attribute = { Hyperlink = "wezterm:custom_action:refresh" } })

  -- 添加点击事件：发送 "CLOSE_WINDOW" 事件
  --[[ table.insert(M.cells, {
    MouseArea = {
      x = 0,
      y = 0,
      width = 10, -- 按钮宽度（根据内容调整）
      height = "100%",
      action = wezterm.action.EmitEvent("CLOSE_WINDOW"),
    },
  }) ]]

  table.insert(M.cells, { Text = "  " }) -- 使用字体图标作为关闭按钮
  table.insert(M.cells, "ResetAttributes")
end
-- 修正后的关闭按钮函数
-- M.set_close_button = function()
--   local close_element = {
--     Foreground = { Color = M.colors.close_fg },
--     Background = { Color = M.colors.close_bg },
--     Attribute = { Intensity = "Bold" },
--     MouseArea = {
--       Width = 20, -- 像素宽度
--       Action = wezterm.action.EmitEvent("CLOSE_WINDOW"),
--     },
--     Text = "  ", -- 关闭图标
--   }
--
--   table.insert(M.cells, close_element)
--   table.insert(M.cells, "ResetAttributes")
-- end

wezterm.on("open-uri", function(window, pane, uri)
  if uri == "wezterm:custom_action:refresh" then
    window:perform_action(wezterm.action.ReloadConfiguration, pane)
    return true
  end
  return false
end)

M.setup = function()
  wezterm.on("update-right-status", function(window, _pane)
    M.cells = {}
    M.set_date()
    M.set_battery()
    -- M.set_close_button() -- 添加关闭按钮

    window:set_right_status(wezterm.format(M.cells))
  end)
end

return M
