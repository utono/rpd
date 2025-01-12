# Hyprland Keybind

Below is a list of Hyprland keybinds with their corresponding `modmask` values. Modifier keys are denoted in parentheses.

Modifier Mask (Keys)       Submap         Key                      Description														   Dispatcher                 Argument
--------------------------  -------------  -----------------------  -----------------------------------------------------------------  -------------------------  ---------------------------------------------------------------------------------------
64 (Meta)                  None           RETURN                   Opens your preferred terminal emulator (alacritty)				   exec                       alacritty
64 (Meta)                  None           E                        Opens your preferred file manager                                   exec
64 (Meta)                  None           A                        Screen capture selection                                            exec                       grim -g "$(slurp)" - | swappy -f -
64 (Meta)                  None           Q                        Closes (not kill) current window									   killactive
65 (Shift + Meta)          None           M                        Exits Hyprland by terminating the user session                      exec                       loginctl terminate-user ""
64 (Meta)                  None           V                        Switches current window between floating and tiling                 togglefloating
64 (Meta)                  None           SPACE                    Runs your application launcher									   exec                       rofi -show combi -modi window,run,combi -combi-modi window,run
64 (Meta)                  None           F                        Toggles current window fullscreen mode                              fullscreen
64 (Meta)                  None           Y                        Pin current window (shows on all workspaces)                        pin
64 (Meta)                  None           J                        Toggles current window split mode                                   togglesplit
64 (Meta)                  None           K                        Toggles current window group mode (ungroup all)                     togglegroup
64 (Meta)                  None           Tab                      Switches to the next window in the group							   changegroupactive		  f
65 (Shift + Meta)          None           G                        Set CachyOS default gaps											   exec                       hyprctl --batch "keyword general:gaps_out 5;keyword general:gaps_in 3"
64 (Meta)                  None           G                        Remove gaps between windows                                         exec                       hyprctl --batch "keyword general:gaps_out 0;keyword general:gaps_in 0"
0                          None           XF86AudioRaiseVolume     Increases audio volume                                              exec                       pactl set-sink-volume @DEFAULT_SINK@ +5% && pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | awk '{if($1>100) system("pactl set-sink-volume @DEFAULT_SINK@ 100%")}'
0                          None           XF86AudioLowerVolume     Decreases audio volume                                              exec                       pactl set-sink-volume @DEFAULT_SINK@ -5%
0                          None           XF86AudioMute            Toggles audio mute                                                  exec                       amixer sset Master toggle
0                          None           XF86AudioPlay            Toggles play/pause                                                  exec                       playerctl play-pause
0                          None           XF86AudioNext            Next track														   exec                       playerctl next
0                          None           XF86AudioPrev            Previous track													   exec                       playerctl previous
0                          None           XF86MonBrightnessUp      Increases screen brightness										   exec                       brightnessctl s +5%
0                          None           XF86MonBrightnessDown    Decreases screen brightness                                         exec                       brightnessctl s 5%-
65 (Shift + Meta)          None           P                        Runs the calculator application									   exec                       gnome-calculator
64 (Meta)                  None           L                        Lock the screen                                                     exec                       swaylock-fancy -e -K -p 10 -f Hack-Regular
64 (Meta)                  None           O                        Reload/restart Waybar                                               exec                       killall -SIGUSR2 waybar
64 (Meta)                  None           mouse:272                Move the window towards a direction                                 movewindow
65 (Shift + Meta)          None           left                     Move active window to the left                                      movewindow                 l
65 (Shift + Meta)          None           right                    Move active window to the right                                     movewindow                 r
65 (Shift + Meta)          None           up                       Move active window upwards                                          movewindow                 u
65 (Shift + Meta)          None           down                     Move active window downwards                                        movewindow                 d
64 (Meta)                  None           left                     Move focus to the left                                              movefocus                  l
64 (Meta)                  None           right                    Move focus to the right                                             movefocus                  r
64 (Meta)                  None           up                       Move focus upwards                                                  movefocus                  u
64 (Meta)                  None           down                     Move focus downwards                                                movefocus                  d
64 (Meta)                  resize         right                    Resize to the right                                                 resizeactive               15 0
64 (Meta)                  resize         left                     Resize to the left                                                  resizeactive               -15 0
64 (Meta)                  resize         up                       Resize upwards                                                      resizeactive               0 -15
64 (Meta)                  resize         down                     Resize downwards                                                    resizeactive               0 15
64 (Meta)                  resize         l                        Resize to the right                                                 resizeactive               15 0
64 (Meta)                  resize         h                        Resize to the left                                                  resizeactive               -15 0
64 (Meta)                  resize         k                        Resize upwards                                                      resizeactive               0 -15
64 (Meta)                  resize         j                        Resize downwards                                                    resizeactive               0 15
64 (Meta)                  resize         escape                   Ends window resizing mode                                           submap                     reset
69 (Ctrl + Alt)            None           right                    Resize to the right                                                 resizeactive               15 0
69 (Ctrl + Alt)            None           left                     Resize to the left                                                  resizeactive               -15 0
69 (Ctrl + Alt)            None           up                       Resize upwards                                                      resizeactive               0 -15
69 (Ctrl + Alt)            None           down                     Resize downwards                                                    resizeactive               0 15
69 (Ctrl + Alt)            None           l                        Resize to the right                                                 resizeactive               15 0
69 (Ctrl + Alt)            None           h                        Resize to the left                                                  resizeactive               -15 0
69 (Ctrl + Alt)            None           k                        Resize upwards                                                      resizeactive               0 -15
69 (Ctrl + Alt)            None           j                        Resize downwards                                                    resizeactive               0 15
64 (Meta)                  None           1                        Switch to workspace 1                                               workspace                  1
64 (Meta)                  None           2                        Switch to workspace 2                                               workspace                  2
64 (Meta)                  None           3                        Switch to workspace 3                                               workspace                  3
64 (Meta)                  None           4                        Switch to workspace 4											   workspace                  4
64 (Meta)                  None           5                        Switch to workspace 5                                               workspace                  5
64 (Meta)                  None           6                        Switch to workspace 6                                               workspace                  6
64 (Meta)                  None           7                        Switch to workspace 7                                               workspace                  7
64 (Meta)                  None           8                        Switch to workspace 8                                               workspace                  8
64 (Meta)                  None           9                        Switch to workspace 9                                               workspace                  9
64 (Meta)                  None           0                        Switch to workspace 10                                              workspace                  10
64 (Meta)                  None           PERIOD                   Scroll through workspaces incrementally                             workspace                  e+1
64 (Meta)                  None           COMMA                    Scroll through workspaces decrementally                             workspace                  e-1
64 (Meta)                  None           mouse_down               Scroll through workspaces incrementally                             workspace                  e+1
64 (Meta)                  None           mouse_up                 Scroll through workspaces decrementally                             workspace                  e-1
64 (Meta)                  None           slash                    Switch to the previous workspace                                    workspace                  previous
64 (Meta)                  None           minus                    Move active window to Special workspace                             movetoworkspace			  special
64 (Meta)                  None           equal                    Toggles the Special workspace                                       togglespecialworkspace     special
64 (Meta)                  None           F1                       Call special workspace scratchpad                                   togglespecialworkspace     scratchpad
73 (Ctrl + Alt + Shift)    None           F1                       Move active window to special workspace scratchpad                  movetoworkspacesilent	  special:scratchpad
