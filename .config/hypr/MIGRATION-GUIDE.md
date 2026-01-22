# i3 → Hyprland Migration Guide

## Installation

```bash
# Core packages
sudo pacman -S hyprland waybar wofi wl-clipboard grim slurp \
  hyprpaper hyprlock hypridle hyprpicker wf-recorder \
  xdg-desktop-portal-hyprland qt5-wayland qt6-wayland \
  wtype jq

# Optional: cliphist for clipboard history
sudo pacman -S cliphist
```

## Directory Structure

```
~/.config/hypr/
├── hyprland.conf      # Main config (keybindings, rules, etc.)
├── hyprpaper.conf     # Wallpaper config
├── hyprlock.conf      # Lock screen config
├── hypridle.conf      # Idle/sleep config
└── scripts/
    ├── power-menu.sh
    ├── screen-recording.sh
    ├── color-picker.sh
    ├── text-extractor.sh
    ├── project-launcher.sh
    ├── emoji-picker.sh
    ├── battery_alert.sh
    └── wallpaper-random.sh
```

## Keybinding Mapping (i3 → Hyprland)

| Action | i3 | Hyprland | Status |
|--------|-----|----------|--------|
| Terminal | `$mod+Return` | `$mod+Return` | ✅ Same |
| Kill window | `$mod+q` | `$mod+Q` | ✅ Same |
| Launcher | `$mod+space` | `$mod+Space` | ✅ Same (wofi) |
| Chrome | `$mod+g` | `$mod+G` | ✅ Same |
| Thunar | `$mod+Shift+n` | `$mod+Shift+N` | ✅ Same |
| Power menu | `$mod+Shift+p` | `$mod+Shift+P` | ✅ Same |
| Lock | `$mod+Shift+x` | `$mod+Shift+X` | ✅ Same (hyprlock) |
| Fullscreen | `$mod+f` | `$mod+F` | ✅ Same |
| Float toggle | `$mod+Shift+space` | `$mod+Shift+Space` | ✅ Same |
| Workspaces | `$mod+1-0` | `$mod+1-0` | ✅ Same |
| Move to WS | `$mod+Shift+1-0` | `$mod+Shift+1-0` | ✅ Same |
| Focus hjkl | `$mod+j/k/l/;` | `$mod+J/K/L/;` | ✅ Same |
| Move hjkl | `$mod+Shift+hjkl` | `$mod+Shift+HJKL` | ✅ Same |
| Resize mode | `$mod+r` | `$mod+R` | ✅ Same (submap) |
| Screenshot | `Print` variants | `Print` variants | ✅ Same (grim) |
| Volume | `XF86Audio*` | `XF86Audio*` | ✅ Same |
| Brightness | `XF86MonBrightness*` | `XF86MonBrightness*` | ✅ Same |
| Recording | `$mod+Shift+v/s` | `$mod+Shift+V/S` | ✅ Same (wf-recorder) |
| Color picker | `$mod+Shift+g` | `$mod+Shift+G` | ✅ Same (hyprpicker) |
| OCR | `$mod+Shift+o` | `$mod+Shift+O` | ✅ Same |

## Tool Replacements

| X11 Tool | Wayland Tool | Notes |
|----------|--------------|-------|
| picom | Hyprland built-in | Blur, shadows, animations native |
| polybar | Waybar | Config migrated |
| rofi | wofi | Theme migrated |
| maim | grim + slurp | Screenshots |
| xclip | wl-clipboard | wl-copy, wl-paste |
| xcolor | hyprpicker | Color picker |
| xdotool | hyprctl | Window manipulation |
| xrandr | wlr-randr | Monitor config |
| xset | hyprctl dpms | Screen power |
| betterlockscreen | hyprlock | Lock screen |
| feh | hyprpaper | Wallpaper |
| ffmpeg x11grab | wf-recorder | Screen recording |
| i3lock | hyprlock | Lock screen |

## Testing Checklist

### Phase 1: Basic Functionality
- [ ] Hyprland starts without errors
- [ ] Waybar displays correctly
- [ ] Workspaces switch properly
- [ ] Windows open and close

### Phase 2: Keybindings
- [ ] `$mod+Return` opens Alacritty
- [ ] `$mod+Space` opens wofi
- [ ] `$mod+q` closes windows
- [ ] Focus navigation works (hjkl and arrows)
- [ ] Window movement works
- [ ] Resize mode works
- [ ] Workspace switching works

### Phase 3: Applications
- [ ] Chrome opens on workspace 1
- [ ] Thunar opens on workspace 4
- [ ] Project launcher works
- [ ] Power menu works

### Phase 4: Media & Utilities
- [ ] Volume keys work
- [ ] Brightness keys work
- [ ] Screenshots work (all variants)
- [ ] Screen recording works
- [ ] Color picker works
- [ ] OCR text extractor works

### Phase 5: System Integration
- [ ] Lock screen works
- [ ] Suspend/resume works
- [ ] Notifications appear
- [ ] Clipboard works
- [ ] Battery alerts work

## Rollback

If anything goes wrong, you can always:

1. Log out of Hyprland
2. Select i3 from your display manager
3. Log back into i3

Your i3 configuration is untouched at `~/.config/i3/config`

## Known Differences

1. **Stacking layout** (`$mod+s` in i3): Hyprland uses groups instead. `$mod+W` creates/toggles groups.

2. **Tabbed layout** (`$mod+w` in i3): Mapped to group toggle in Hyprland.

3. **Split direction**: In i3, `$mod+h/v` sets next split direction. In Hyprland, use `$mod+H/V` with preselect.

4. **Resize mode**: Works the same way using Hyprland's submap feature.

## Random Wallpaper

To set a random wallpaper like feh did:

```bash
~/.config/hypr/scripts/wallpaper-random.sh
```

Or add to startup:
```
exec-once = ~/.config/hypr/scripts/wallpaper-random.sh
```

## Troubleshooting

### Waybar not showing
```bash
killall waybar
waybar &
```

### Screen recording not working
```bash
# Check wf-recorder is installed
pacman -Qs wf-recorder

# Test manually
wf-recorder -f test.mp4
```

### Clipboard not working
```bash
# Ensure wl-clipboard is installed
pacman -Qs wl-clipboard

# Test
echo "test" | wl-copy
wl-paste
```
