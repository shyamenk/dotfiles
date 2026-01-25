#!/bin/bash

# Keybindings Help Menu for Hyprland
# Shows all keybindings with descriptions in wofi

keybindings="
 Core
Super + Return          Open Terminal (Alacritty)
Super + Q               Close Active Window
Super + Space           Application Launcher
Super + Shift + C       Reload Hyprland Config
Super + Shift + E       Exit Hyprland

 Applications
Super + G               Google Chrome
Super + Shift + N       File Manager (Thunar)
Super + P               Project Launcher
Super + .               Emoji Picker
Super + N               Scratchpad Notes

 Power & Lock
Super + Shift + P       Power Menu
Super + Shift + X       Lock Screen
Super + Shift + I       Turn Off Display

 Layout & Windows
Super + F               Fullscreen
Super + Shift + Space   Toggle Floating
Super + E               Toggle Split Direction
Super + W               Toggle Window Group
Super + A               Cycle Group Windows
Super + R               Enter Resize Mode

 Focus (Vim-style)
Super + J               Focus Left
Super + K               Focus Down
Super + L               Focus Up
Super + ;               Focus Right

 Focus (Arrows)
Super + Arrow Keys      Focus Direction

 Move Windows
Super + Shift + H/J/K/L Move Window (Vim)
Super + Shift + Arrows  Move Window (Arrows)

󰖯 Resize Mode (press Super+R first)
J / Left                Shrink Width
K / Down                Grow Height
L / Up                  Shrink Height
; / Right               Grow Width
Enter / Escape          Exit Resize Mode

 Workspaces
Super + 1-9, 0          Switch to Workspace 1-10
Super + Shift + 1-9, 0  Move Window to Workspace

 Screenshots
Print                   Screenshot (Full)
Super + Print           Screenshot (Window)
Shift + Print           Screenshot (Selection)
Ctrl + Print            Screenshot to Clipboard
Super + Shift + Print   Selection to Clipboard

󰕾 Media Keys
Volume Up/Down          Adjust Volume
Mute                    Toggle Mute
Brightness Up/Down      Adjust Brightness

 Utilities
Super + H               Clipboard History
Super + Alt + C         Clear Clipboard History
Super + Shift + V       Start Screen Recording
Super + Shift + S       Stop Screen Recording
Super + Shift + G       Color Picker
Super + Shift + O       Text Extractor (OCR)

 Mouse
Super + Left Click      Move Window
Super + Right Click     Resize Window
"

# Display in wofi with custom style
echo "$keybindings" | wofi --dmenu \
    --style ~/.config/wofi/style-keybindings.css \
    --conf ~/.config/wofi/config-keybindings \
    --cache-file /dev/null \
    --prompt "Keybindings"
