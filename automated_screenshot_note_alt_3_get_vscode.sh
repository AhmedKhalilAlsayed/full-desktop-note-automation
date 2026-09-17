#! /bin/env bash
# Author: Ahmed Khalil
# Improvements: Copilot

# v4+
# v3

# 1. Configuration
# Increase this slightly if it still fails. 0.4s is safer for GNOME animations.

# delay=0.3
notes_extension=".+V.+S" #Visual Studio Code
# notes_extension="\.md"
windw_regex="$notes_extension.+Code" # means .md in vscode

# 2. Switch to the Notes window

# Instead of Alt+Tab, we search for the window directly.
# md windows, with vscode, the last stacked window

windwId=$(xdotool search  --name "$windw_regex")
# md_WinName=$(xdotool getwindowname "$md_WinId")

if [[ -z "$windwId" ]]; then
    notify-send "Error" "No files matched (regex: $windw_regex)"
    exit 1
fi

# get .md window in vscode

xdotool windowactivate "$windwId"
# sleep $delay




# # v2

# # 1. Configuration
# # Increase this slightly if it still fails. 0.4s is safer for GNOME animations.
# delay=0.2
# notes_extension=".md"

# # 2. Take the screenshot

# # get this window
# activeWinId=$(xdotool getactivewindow)
# xdotool windowactivate "$activeWinId"
# sleep 0.1

# # We capture the window. If this fails, we stop immediately.

# # xdotool key Print

# # it works with CPU but with hardware acc, the videos are with GPU, so the screeenshot tool sees empty buffer!
# # gnome-screenshot --window --clipboard
# # if ! gnome-screenshot --window --clipboard; then
# #     notify-send "Error" "Could not take screenshot"
# #     exit 1
# # fi

# # works with video (that was with GPU), works with the screen very well
# # if ! flameshot screen -c; then
# #     notify-send "Error" "Flameshot failed"
# #     exit 1
# # fi

# # clear the last image screenshot, to be safe
# xclip -selection clipboard /dev/null
# #sleep 0.1

# if ! maim -i "$activeWinId" | xclip -selection clipboard -t image/png; then
#     notify-send "Error" "Maim failed to capture window"
#     exit 1
# fi

# # Give the clipboard a moment to "hold" the image
# sleep $delay

# # 3. Switch to the Notes window
# # Instead of Alt+Tab, we search for the window directly.
# # This is much safer than Alt+Tab which depends on the order of windows.
# xdotool key alt+Tab
# sleep $delay


# # 4. Get window details
# activeWinId=$(xdotool getactivewindow)
# activeWinName=$(xdotool getwindowname "$activeWinId")

# # 5. Logical Check
# if [[ "$activeWinName" == *"$notes_extension"* ]]; then
#     # We use 'windowactivate' to make sure the focus is 100% on this window
#     xdotool windowactivate "$activeWinId"
#     sleep 0.1
#     xdotool key ctrl+v
#     sleep $delay
#     xdotool key End
#     sleep 0.1
#     xdotool key Return
#     sleep 0.1

#     # 6. Return to Lecture
#     xdotool key alt+Tab
#     sleep $delay

#     notify-send "Note Taken" "Screenshot pasted in $activeWinName"
# else
#     # If we are not in a .md file, go back so we don't paste in the wrong place
#     xdotool key alt+Tab
#     notify-send "Failed" "Target window is not a $notes_extension file"
# fi


# v0

# set -e

# actionDelay=0.33

# # take a window screenshot
# # flameshot screen
# if ! gnome-screenshot --window --clipboard;then
#     notify-send "Failed screenshot"
#     exit
# fi
# #gnome-screenshot
# #xdotool key Print
# sleep $actionDelay

# # switch to the background window
# xdotool key alt+Tab
# sleep $actionDelay

# # paste the screenshot
# # check this window is vscode or not
# activeWinId=$(xdotool getactivewindow)
# # echo "$activeWinId"
# sleep $actionDelay
# activeWinName=$(xdotool getwindowname "${activeWinId}")
# # echo "$activeWinName"
# sleep $actionDelay
# if [[ $activeWinName == *.md* ]]; then # any file.md but in vscode
#     #xdotool key Down
#     #sleep $actionDelay
#     #xdotool key Return
#     #sleep $actionDelay
#     xdotool key End Return ctrl+v
#     sleep $actionDelay


#     # back to the working window
#     xdotool key alt+Tab
#     sleep $actionDelay

#     notify-send "Done: note is taked"
# else
#     xdotool key alt+Tab
#     sleep $actionDelay

#     notify-send "Failed: not .md file"
# fi


# set +e
