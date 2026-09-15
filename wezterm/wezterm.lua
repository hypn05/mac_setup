-- WezTerm config — Mac-like copy/paste and tabs so Linux/Windows match iTerm.
-- Linked to ~/.wezterm.lua by the wezterm module (or copied into the Windows
-- home directory when running under WSL).
--
-- Copy/paste chords (same as macOS Cmd+C / Cmd+V):
--   Super+C / Super+V     primary (Cmd on Mac keyboards, Win/Super on PC)
--   Ctrl+Shift+C / V      Linux convention (also enabled by WezTerm defaults)
--
-- Reload: Super+R  or  Ctrl+Shift+R

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = 'Builtin Dark'
config.font_size = 13.0
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.audible_bell = 'Disabled'
config.scrollback_lines = 100000

-- Selection automatically copies on mouse release (iTerm-like).
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
}

-- Explicit Mac-parity keys. SUPER = Cmd on macOS, Super/Win on Linux/Windows.
-- CTRL|SHIFT variants keep the familiar Linux terminal chords too.
config.keys = {
  -- Copy / paste (Cmd/Super — same as iTerm on macOS)
  { key = 'c', mods = 'SUPER', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' },
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- Tabs / window (Cmd/Super parity with iTerm)
  { key = 't', mods = 'SUPER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'SUPER', action = act.CloseCurrentTab { confirm = true } },
  { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = true } },

  -- Font size
  { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
  { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
  { key = '0', mods = 'SUPER', action = act.ResetFontSize },

  -- Search / clear / reload
  { key = 'f', mods = 'SUPER', action = act.Search { CaseSensitiveString = '' } },
  { key = 'k', mods = 'SUPER', action = act.ClearScrollback 'ScrollbackOnly' },
  { key = 'r', mods = 'SUPER', action = act.ReloadConfiguration },

  -- Tab switching (Super+1..9)
  { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
  { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
  { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
  { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
  { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
  { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
  { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
  { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
  { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },
}

return config
