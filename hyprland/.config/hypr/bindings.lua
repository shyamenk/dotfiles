-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Personal overrides
-- SUPER+Q closes the window (Omarchy default SUPER+W still works too).
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- SUPER+SHIFT+N: today's daily note in leaf, floating; focuses it if already open (was: Netflix)
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Daily note", "daily-note --toggle")

-- SUPER+ALT+N: Netflix web app (moved from SUPER+SHIFT+N)
o.bind("SUPER + ALT + N", "Netflix", { webapp = "https://www.netflix.com/browse" })

-- SUPER+V: hold to dictate, release to transcribe (was: Universal paste)
hl.unbind("SUPER + V")
o.bind("SUPER + V", "Start dictation (push-to-talk)", "voxtype record start")
o.bind("SUPER + V", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })

-- SUPER+F keeps the bar visible (was: true full screen, which covers the bar).
-- SUPER+ALT+F is now true full screen (was: Full width).
hl.unbind("SUPER + F")
o.bind("SUPER + F", "Full screen (keep bar)", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.unbind("SUPER + ALT + F")
o.bind("SUPER + ALT + F", "True full screen (hide bar)", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Thunar replaces Nautilus as the file manager (was: Nautilus on SUPER+SHIFT+F).
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", { launch = "thunar" })
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", 'setsid uwsm-app -- thunar "$(omarchy-cmd-terminal-cwd)"')

-- SUPER+SHIFT+L: LinkedIn web app (key was unbound before)
o.bind("SUPER + SHIFT + L", "LinkedIn", { webapp = "https://www.linkedin.com/in/shyamenk/" })

-- SUPER+SHIFT+K: Google Keep web app
o.bind("SUPER + SHIFT + K", "Keep", { webapp = "https://keep.google.com/" })



-- SUPER+SHIFT+H: clipboard history (same panel as SUPER+CTRL+V, which still works)
o.bind("SUPER + SHIFT + H", "Clipboard history", "omarchy-shell shell toggle omarchy.clipboard")

-- SUPER+SHIFT+S: quick note appended to today's daily note, nvim, floating (was: Google Maps)
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Quick note (nvim)", "omarchy-launch-tui --app-id=TUI.float quick-note")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end

-- SUPER+SHIFT+O: extract text (OCR) from screen (OCR was on SUPER+CTRL+PRINT, then SUPER+SHIFT+P)
hl.unbind("SUPER + CTRL + PRINT")
o.rebind("SUPER + SHIFT + O", "Extract text (OCR) from screenshot", "omarchy-capture-text")
