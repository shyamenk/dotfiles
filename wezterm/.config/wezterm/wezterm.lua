local wezterm = require("wezterm")
local act = wezterm.action

return {
	-- ── Appearance ────────────────────────────────────────────────────────
	color_scheme = "Catppuccin Mocha",
	font = wezterm.font_with_fallback({
		"JetBrainsMono Nerd Font",
		"VictorMono Nerd Font",
		"Noto Color Emoji",
	}),
	font_size = 14.0,
	window_background_opacity = 0.9,
	default_cursor_style = "SteadyBlock",
	window_decorations = "RESIZE",
	enable_tab_bar = false,
	window_padding = { left = 10, right = 10, top = 10, bottom = 10 },

	-- ── Keys ──────────────────────────────────────────────────────────────
	keys = {
		-- Ctrl+C: copy if selection exists, otherwise send SIGINT
		{
			key = "c",
			mods = "CTRL",
			action = wezterm.action_callback(function(window, pane)
				local sel = window:get_selection_text_for_pane(pane)
				if sel ~= "" then
					window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
					window:perform_action(act.ClearSelection, pane)
				else
					window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
				end
			end),
		},
		-- Ctrl+V: paste
		{ key = "v",   mods = "CTRL",       action = act.PasteFrom("Clipboard") },
		-- Ctrl+Shift+Space: enter vim copy mode
		{ key = "Space", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
		-- Ctrl+Shift+Return: Shift+Enter passthrough (same as alacritty binding)
		{ key = "Return", mods = "SHIFT",   action = act.SendString("\x1b\r") },
		-- Ctrl+K: send Ctrl+C (kill line, same as alacritty)
		{ key = "k",   mods = "CTRL",       action = act.SendKey({ key = "c", mods = "CTRL" }) },
		-- Clear scrollback
		{ key = "'",   mods = "CTRL",       action = act.ClearScrollback("ScrollbackAndViewport") },
		-- Fullscreen
		{ key = "f",   mods = "CTRL",       action = act.ToggleFullScreen },
		-- Font size
		{ key = "=",   mods = "CTRL",       action = act.IncreaseFontSize },
		{ key = "-",   mods = "CTRL",       action = act.DecreaseFontSize },
		{ key = "0",   mods = "CTRL",       action = act.ResetFontSize },
	},

	-- ── Vim copy mode (Ctrl+Shift+Space) ─────────────────────────────────
	key_tables = {
		copy_mode = {
			{ key = "h",      mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "j",      mods = "NONE", action = act.CopyMode("MoveDown") },
			{ key = "k",      mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "l",      mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "w",      mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{ key = "b",      mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
			{ key = "e",      mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
			{ key = "0",      mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = "$",      mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "g",      mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
			{ key = "G",      mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "f",      mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
			{ key = "b",      mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
			{ key = "v",      mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "V",      mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "v",      mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
			{ key = "y",      mods = "NONE", action = act.Multiple({
				act.CopyTo("ClipboardAndPrimarySelection"),
				act.CopyMode("Close"),
			})},
			{ key = "/",      mods = "NONE", action = act.Search("CurrentSelectionOrEmptyString") },
			{ key = "n",      mods = "NONE", action = act.CopyMode("NextMatch") },
			{ key = "N",      mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "q",      mods = "NONE", action = act.CopyMode("Close") },
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
		},
	},

	-- ── Mouse ─────────────────────────────────────────────────────────────
	mouse_bindings = {
		{ event = { Down = { streak = 1, button = "Middle" } }, mods = "NONE",
		  action = act.PasteFrom("PrimarySelection") },
		{ event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL",
		  action = act.OpenLinkAtMouseCursor },
	},
}
