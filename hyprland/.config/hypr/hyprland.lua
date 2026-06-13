-- =============================================
-- Hyprland Lua Configuration
-- Migrated from hyprland.conf
-- =============================================

------------------
---- MONITORS ----
------------------

-- monitor=eDP-1,1920x1080@60,0x0,1
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

-------------------------
---- WORKSPACE RULES ----
-------------------------

-- Bind workspaces 1-10 to eDP-1
for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = "eDP-1",
        default   = (i == 1)
    })
end

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 2,
        col = {
            active_border   = "rgb(cba6f7)",
            inactive_border = "rgb(6c7086)",
        },
        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 10,

        blur = {
            enabled = true,
            size    = 7,
            passes  = 3,
            xray    = false,
        },

        shadow = {
            enabled      = false,
            range        = 12,
            render_power = 3,
            color        = "rgba(00000075)",
        }
    }
})

--------------------
---- ANIMATIONS ----
--------------------

hl.curve("ease", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.1} } })

hl.animation({ leaf = "windows",      enabled = true, speed = 4, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 4, bezier = "ease",     style = "slide" })
hl.animation({ leaf = "fade",         enabled = true, speed = 4, bezier = "ease" })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 4, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "border",       enabled = true, speed = 5, bezier = "ease" })

-----------------
---- LAYOUTS ----
-----------------

hl.config({
    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms  = true,
    }
})

----------------------
---- WINDOW RULES ----
----------------------

-- Transparency Rules
hl.window_rule({
    name  = "alacritty-opacity",
    match = { class = "^(Alacritty)$" },
    opacity = "0.85 0.85"
})
hl.window_rule({
    name  = "kitty-opacity",
    match = { class = "^(kitty)$" },
    opacity = "0.85 0.85"
})

-- Workspace Assignments
hl.window_rule({ name = "chrome-workspace",      match = { class = "^(google-chrome)$" },      workspace = 1 })
hl.window_rule({ name = "beekeeper-workspace",   match = { class = "^(beekeeper-studio)$" },   workspace = 3 })
hl.window_rule({ name = "thunar-workspace",      match = { class = "^(thunar)$" },             workspace = 4 })
hl.window_rule({ name = "spotify-workspace",     match = { class = "^([sS]potify)$" },         workspace = 5 })
hl.window_rule({ name = "remmina-workspace",     match = { class = "^(remmina)$" },            workspace = 6 })
hl.window_rule({ name = "remmina-org-workspace", match = { class = "^(org.remmina.Remmina)$" }, workspace = 6 })
hl.window_rule({ name = "slack-workspace",       match = { class = "^(.*[sS]lack.*)$" },       workspace = 7 })

-- Floating Windows & Dialogs
hl.window_rule({ name = "pavucontrol-float", match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ name = "galendae-float",    match = { class = "^(galendae)$" },    float = true })
hl.window_rule({ name = "pip-float",         match = { title = "^(Picture-in-Picture)$" }, float = true })

-- Scratchpad Rules
hl.window_rule({
    name  = "scratchpad-rules",
    match = { class = "^(scratchpad)$" },
    float  = true,
    size   = "800 600",
    center = true,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- NVIDIA Primary GPU Settings
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "1")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Core Binds
hl.bind(mainMod .. " + Return",         hl.dsp.exec_cmd("alacritty"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("wezterm"))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())

-- Applications
hl.bind(mainMod .. " + G",         hl.dsp.exec_cmd("/opt/google/chrome/google-chrome"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + P",         hl.dsp.exec_cmd("~/.config/hypr/scripts/project-launcher.sh"))
hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd("~/.config/hypr/scripts/sf-org-pick.sh"))
hl.bind(mainMod .. " + period",    hl.dsp.exec_cmd("~/.config/hypr/scripts/emoji-picker.sh"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-gdrive.sh"))

-- Power & Lock
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/power-menu.sh"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("hyprctl dispatch dpms off"))

-- Layout Control
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + W",           hl.dsp.group.toggle())
hl.bind(mainMod .. " + E",           hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + A",           hl.dsp.group.next())

-- Focus (Vim-style)
hl.bind(mainMod .. " + J",         hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + K",         hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + L",         hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + semicolon", hl.dsp.focus({ direction = "r" }))

-- Focus (Arrow keys)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))

-- Move Windows (Vim-style)
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- Move Windows (Arrow keys)
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))

-- Switch & Move to Workspaces (1-10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Mouse Bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grim ~/Pictures/$(date +'%Y-%m-%d_%H-%M-%S').png"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd([[hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - ~/Pictures/$(date +'%Y-%m-%d_%H-%M-%S').png]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/$(date +'%Y-%m-%d_%H-%M-%S').png"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind("CTRL + " .. mainMod .. " + Print", hl.dsp.exec_cmd([[hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - - | wl-copy]]))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

-- Volume Control (Locked + Repeating)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

-- Brightness Control (Locked + Repeating)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +10%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true, repeating = true })

-- Screen Recording
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/screen-recording.sh"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[pkill -INT wf-recorder && notify-send "Screen Recording" "Recording stopped"]]))

-- Utilities
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd("~/.config/hypr/scripts/color-picker.sh"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/text-extractor.sh"))

-- Speech to Text (Handy)
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd("handy --toggle-transcription"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("handy --toggle-post-process"))
hl.bind(mainMod .. " + ALT + T",   hl.dsp.exec_cmd("handy --cancel"))

-- Password Manager
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-pass.sh"))

-- Clipboard History
hl.bind(mainMod .. " + H",       hl.dsp.exec_cmd([[cliphist list | wofi --dmenu | cliphist decode | wl-copy]]))
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd([[cliphist wipe && notify-send "Clipboard" "History cleared"]]))

-- Scratchpad
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/hypr/scripts/scratchpad.sh"))

-- Keybindings Help
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybindings-help.sh"))

---------------------
---- INPUTS/DEVICES --
---------------------

hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
        }
    }
})

hl.device({
    name    = "gxtp5100:00-27c6:01e0-touchpad",
    enabled = false,
})

---------------------
---- SUBMAPS --------
---------------------

-- Resize mode submap
hl.define_submap("resize", function()
    hl.bind("J", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("semicolon", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })

    hl.bind("left",  hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })

    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind(mainMod .. " + R", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

----------------------------
---- STARTUP APPLICATIONS --
----------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("awww-daemon && sleep 1 && ~/.config/hypr/scripts/wallpaper-rotate.sh")
    hl.exec_cmd("dunst")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("~/.config/hypr/scripts/battery_alert.sh")
    hl.exec_cmd("handy --start-hidden")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("thunar --daemon")
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-rotate.sh")
end)

hl.on("config.reloaded", function()
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-rotate.sh")
end)

------------------------------------------------
---- ADVANCED PROGRAMMATIC LUA ENHANCEMENTS ----
------------------------------------------------

-- 1. Toggleable Window Transparency Keybind
local semi_transparent_windows = {}

hl.bind(mainMod .. " + CTRL + O", function()
    local win = hl.get_active_window()
    if win and win.address then
        local addr = win.address
        if semi_transparent_windows[addr] then
            -- Make it opaque
            hl.dispatch(hl.dsp.window.set_prop({ window = "address:" .. addr, prop = "opacity", value = "1.0" }))
            semi_transparent_windows[addr] = nil
        else
            -- Make it semi-transparent
            hl.dispatch(hl.dsp.window.set_prop({ window = "address:" .. addr, prop = "opacity", value = "0.85" }))
            semi_transparent_windows[addr] = true
        end
    end
end)
