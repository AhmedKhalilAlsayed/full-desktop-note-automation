#! /bin/env bash

# v4

# 1. Configuration
# Increase this slightly if it still fails. 0.4s is safer for GNOME animations.
#delay=1

# get the high cpu%
# delay = base + ratio, with max delay is 1 sec
high_cpu=$(top -bn1 | awk 'NR>7 {print $9}' | sort -rn | head -1)
delay=$(echo "0.2 + $high_cpu / 100" | bc -l) # tuning
delay_max=1 #3

if (( $(echo "$delay > $delay_max" | bc -l) )); then
    delay=$delay_max
fi

#notes_extension="\.md"
notes_regex="\.md.+Code" # means .md in vscode

# 2. Take window screenshot
# get this window, make sure you are in it
activeWinId=$(xdotool getactivewindow)
#xdotool windowactivate "$activeWinId"
# sleep 0.1

# clear the last image screenshot, to be safe if error, paste nothing
xclip -selection clipboard /dev/null

if ! maim -i "$activeWinId" | xclip -selection clipboard -t image/png; then
    notify-send "Error" "Maim failed to capture window"
    exit 1
fi

# Check if the clipboard contains any image format

if xclip -selection clipboard -t TARGETS -o | grep -qF "image"; then
    :    echo "Success: Image detected in clipboard."
else
    :   echo "Error: Clipboard does not contain an image."
    notify-send "Capture Failed" "No image found in clipboard"
    exit 1
fi

# Give the clipboard a moment to "hold" the image
sleep $delay

# 3. Switch to the Notes window

# Instead of Alt+Tab, we search for the window directly.
# md windows, with vscode, the last stacked window
md_WinId=$(xdotool search  --name "$notes_regex")
# md_WinName=$(xdotool getwindowname "$md_WinId")

if [[ -z "$md_WinId" ]]; then
    notify-send "Error" "No files matched (regex: $notes_regex)"
    exit 1
fi

# open .md file in vscode
xdotool windowactivate "$md_WinId" && sleep $delay

xdotool key ctrl+v && sleep $delay && xdotool key End && sleep $delay && xdotool key Return && sleep $delay


# sync
#sleep $delay
#xdotool key End
#sleep $delay
#xdotool key Return
#sleep $delay


# 6. Return to Lecture
#xdotool windowactivate "$activeWinId" && sleep $delay

#-----------------------------------------------

#notify-send "Note Taken" "Screenshot pasted in $md_WinName"

# to see the delay
#notify-send "Movement Delay" "$delay"



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





