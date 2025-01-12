bindd
	modmask: 64
	submap: 
	key: RETURN
	keycode: 0
	catchall: false
	description: Opens your preferred terminal emulator (alacritty)
	dispatcher: exec
	arg: alacritty

bindd
	modmask: 64
	submap: 
	key: E
	keycode: 0
	catchall: false
	description: Opens your preferred filemanager ()
	dispatcher: exec
	arg: 

bindd
	modmask: 64
	submap: 
	key: A
	keycode: 0
	catchall: false
	description: Screen capture selection
	dispatcher: exec
	arg: grim -g "$(slurp)" - | swappy -f -

bindd
	modmask: 64
	submap: 
	key: Q
	keycode: 0
	catchall: false
	description: Closes (not kill) current window
	dispatcher: killactive
	arg: 

bindd
	modmask: 65
	submap: 
	key: M
	keycode: 0
	catchall: false
	description: Exits Hyprland by terminating the user sessions
	dispatcher: exec
	arg: loginctl terminate-user ""

bindd
	modmask: 64
	submap: 
	key: V
	keycode: 0
	catchall: false
	description: Switches current window between floating and tiling mode
	dispatcher: togglefloating
	arg: 

bindd
	modmask: 64
	submap: 
	key: SPACE
	keycode: 0
	catchall: false
	description: Runs your application launcher
	dispatcher: exec
	arg: rofi -show combi -modi window,run,combi -combi-modi window,run

bindd
	modmask: 64
	submap: 
	key: F
	keycode: 0
	catchall: false
	description: Toggles current window fullscreen mode
	dispatcher: fullscreen
	arg: 

bindd
	modmask: 64
	submap: 
	key: Y
	keycode: 0
	catchall: false
	description: Pin current window (shows on all workspaces)
	dispatcher: pin
	arg: 

bindd
	modmask: 64
	submap: 
	key: J
	keycode: 0
	catchall: false
	description: Toggles curren window split mode
	dispatcher: togglesplit
	arg: 

bindd
	modmask: 64
	submap: 
	key: K
	keycode: 0
	catchall: false
	description: Toggles current window group mode (ungroup all related)
	dispatcher: togglegroup
	arg: 

bindd
	modmask: 64
	submap: 
	key: Tab
	keycode: 0
	catchall: false
	description: Switches to the next window in the group
	dispatcher: changegroupactive
	arg: f

bindd
	modmask: 65
	submap: 
	key: G
	keycode: 0
	catchall: false
	description: Set CachyOS default gaps
	dispatcher: exec
	arg: hyprctl --batch "keyword general:gaps_out 5;keyword general:gaps_in 3"

bindd
	modmask: 64
	submap: 
	key: G
	keycode: 0
	catchall: false
	description: Remove gaps between window
	dispatcher: exec
	arg: hyprctl --batch "keyword general:gaps_out 0;keyword general:gaps_in 0"

bindle
	modmask: 0
	submap: 
	key: XF86AudioRaiseVolume
	keycode: 0
	catchall: false
	description: 
	dispatcher: exec
	arg: pactl set-sink-volume @DEFAULT_SINK@ +5% && pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | awk '{if($1>100) system("pactl set-sink-volume @DEFAULT_SINK@ 100%")}'

bindle
	modmask: 0
	submap: 
	key: XF86AudioLowerVolume
	keycode: 0
	catchall: false
	description: 
	dispatcher: exec
	arg: pactl set-sink-volume @DEFAULT_SINK@ -5%

bindle
	modmask: 0
	submap: 
	key: XF86AudioMute
	keycode: 0
	catchall: false
	description: 
	dispatcher: exec
	arg: amixer sset Master toggle | sed -En '/\[on\]/ s/.*\[([0-9]+)%\].*/\1/ p; /\[off\]/ s/.*/0/p' | head -1 > /tmp/0bd541f2fd902dbfa04c3ea2ccf679395e316887_1736628518_174513971.wob

bindd
	modmask: 0
	submap: 
	key: XF86AudioPlay
	keycode: 0
	catchall: false
	description: Toggles play/pause
	dispatcher: exec
	arg: playerctl play-pause

bindd
	modmask: 0
	submap: 
	key: XF86AudioNext
	keycode: 0
	catchall: false
	description: Next track
	dispatcher: exec
	arg: playerctl next

bindd
	modmask: 0
	submap: 
	key: XF86AudioPrev
	keycode: 0
	catchall: false
	description: Previous track
	dispatcher: exec
	arg: playerctl previous

bindle
	modmask: 0
	submap: 
	key: XF86MonBrightnessUp
	keycode: 0
	catchall: false
	description: 
	dispatcher: exec
	arg: brightnessctl s +5%

bindle
	modmask: 0
	submap: 
	key: XF86MonBrightnessDown
	keycode: 0
	catchall: false
	description: 
	dispatcher: exec
	arg: brightnessctl s 5%-

bindd
	modmask: 65
	submap: 
	key: P
	keycode: 0
	catchall: false
	description: Runs the calculator application
	dispatcher: exec
	arg: gnome-calculator

bindd
	modmask: 64
	submap: 
	key: L
	keycode: 0
	catchall: false
	description: Lock the screen
	dispatcher: exec
	arg: swaylock-fancy -e -K -p 10 -f Hack-Regular

bindd
	modmask: 64
	submap: 
	key: O
	keycode: 0
	catchall: false
	description: Reload/restarts Waybar
	dispatcher: exec
	arg: killall -SIGUSR2 waybar

bindd
	modmask: 64
	submap: 
	key: mouse:272
	keycode: 0
	catchall: false
	description: Move the window towards a direction
	dispatcher: movewindow
	arg: 

bindd
	modmask: 65
	submap: 
	key: left
	keycode: 0
	catchall: false
	description: Move active window to the left
	dispatcher: movewindow
	arg: l

bindd
	modmask: 65
	submap: 
	key: right
	keycode: 0
	catchall: false
	description: Move active window to the right
	dispatcher: movewindow
	arg: r

bindd
	modmask: 65
	submap: 
	key: up
	keycode: 0
	catchall: false
	description: Move active window upwards
	dispatcher: movewindow
	arg: u

bindd
	modmask: 65
	submap: 
	key: down
	keycode: 0
	catchall: false
	description: Move active window downwards
	dispatcher: movewindow
	arg: d

bindd
	modmask: 64
	submap: 
	key: left
	keycode: 0
	catchall: false
	description: Move focus to the left
	dispatcher: movefocus
	arg: l

bindd
	modmask: 64
	submap: 
	key: right
	keycode: 0
	catchall: false
	description: Move focus to the right
	dispatcher: movefocus
	arg: r

bindd
	modmask: 64
	submap: 
	key: up
	keycode: 0
	catchall: false
	description: Move focus upwards
	dispatcher: movefocus
	arg: u

bindd
	modmask: 64
	submap: 
	key: down
	keycode: 0
	catchall: false
	description: Move focus downwards
	dispatcher: movefocus
	arg: d

bindd
	modmask: 64
	submap: 
	key: R
	keycode: 0
	catchall: false
	description: Activates window resizing mode
	dispatcher: submap
	arg: resize

bindd
	modmask: 0
	submap: resize
	key: right
	keycode: 0
	catchall: false
	description: Resize to the right (resizing mode)
	dispatcher: resizeactive
	arg: 15 0

bindd
	modmask: 0
	submap: resize
	key: left
	keycode: 0
	catchall: false
	description: Resize to the left (resizing mode)
	dispatcher: resizeactive
	arg: -15 0

bindd
	modmask: 0
	submap: resize
	key: up
	keycode: 0
	catchall: false
	description: Resize upwards (resizing mode)
	dispatcher: resizeactive
	arg: 0 -15

bindd
	modmask: 0
	submap: resize
	key: down
	keycode: 0
	catchall: false
	description: Resize downwards (resizing mode)
	dispatcher: resizeactive
	arg: 0 15

bindd
	modmask: 0
	submap: resize
	key: l
	keycode: 0
	catchall: false
	description: Resize to the right (resizing mode)
	dispatcher: resizeactive
	arg: 15 0

bindd
	modmask: 0
	submap: resize
	key: h
	keycode: 0
	catchall: false
	description: Resize to the left (resizing mode)
	dispatcher: resizeactive
	arg: -15 0

bindd
	modmask: 0
	submap: resize
	key: k
	keycode: 0
	catchall: false
	description: Resize upwards (resizing mode)
	dispatcher: resizeactive
	arg: 0 -15

bindd
	modmask: 0
	submap: resize
	key: j
	keycode: 0
	catchall: false
	description: Resize downwards (resizing mode)
	dispatcher: resizeactive
	arg: 0 15

bindd
	modmask: 0
	submap: resize
	key: escape
	keycode: 0
	catchall: false
	description: Ends window resizing mode
	dispatcher: submap
	arg: reset

bindd
	modmask: 69
	submap: 
	key: right
	keycode: 0
	catchall: false
	description: Resize to the right
	dispatcher: resizeactive
	arg: 15 0

bindd
	modmask: 69
	submap: 
	key: left
	keycode: 0
	catchall: false
	description: Resize to the left
	dispatcher: resizeactive
	arg: -15 0

bindd
	modmask: 69
	submap: 
	key: up
	keycode: 0
	catchall: false
	description: Resize upwards
	dispatcher: resizeactive
	arg: 0 -15

bindd
	modmask: 69
	submap: 
	key: down
	keycode: 0
	catchall: false
	description: Resize downwards
	dispatcher: resizeactive
	arg: 0 15

bindd
	modmask: 69
	submap: 
	key: l
	keycode: 0
	catchall: false
	description: Resize to the right
	dispatcher: resizeactive
	arg: 15 0

bindd
	modmask: 69
	submap: 
	key: h
	keycode: 0
	catchall: false
	description: Resize to the left
	dispatcher: resizeactive
	arg: -15 0

bindd
	modmask: 69
	submap: 
	key: k
	keycode: 0
	catchall: false
	description: Resize upwards
	dispatcher: resizeactive
	arg: 0 -15

bindd
	modmask: 69
	submap: 
	key: j
	keycode: 0
	catchall: false
	description: Resize downwards
	dispatcher: resizeactive
	arg: 0 15

bindm
	modmask: 64
	submap: 
	key: mouse:273
	keycode: 0
	catchall: false
	description: 
	dispatcher: mouse
	arg: resizewindow

bindm
	modmask: 64
	submap: 
	key: mouse:272
	keycode: 0
	catchall: false
	description: 
	dispatcher: mouse
	arg: movewindow

bindd
	modmask: 68
	submap: 
	key: 1
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 1
	dispatcher: movetoworkspace
	arg: 1

bindd
	modmask: 68
	submap: 
	key: 2
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 2
	dispatcher: movetoworkspace
	arg: 2

bindd
	modmask: 68
	submap: 
	key: 3
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 3
	dispatcher: movetoworkspace
	arg: 3

bindd
	modmask: 68
	submap: 
	key: 4
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 4
	dispatcher: movetoworkspace
	arg: 4

bindd
	modmask: 68
	submap: 
	key: 5
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 5
	dispatcher: movetoworkspace
	arg: 5

bindd
	modmask: 68
	submap: 
	key: 6
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 6
	dispatcher: movetoworkspace
	arg: 6

bindd
	modmask: 68
	submap: 
	key: 7
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 7
	dispatcher: movetoworkspace
	arg: 7

bindd
	modmask: 68
	submap: 
	key: 8
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 8
	dispatcher: movetoworkspace
	arg: 8

bindd
	modmask: 68
	submap: 
	key: 9
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 9
	dispatcher: movetoworkspace
	arg: 9

bindd
	modmask: 68
	submap: 
	key: 0
	keycode: 0
	catchall: false
	description: Move window and switch to workspace 10
	dispatcher: movetoworkspace
	arg: 10

bindd
	modmask: 68
	submap: 
	key: left
	keycode: 0
	catchall: false
	description: Move window and switch to the next workspace
	dispatcher: movetoworkspace
	arg: -1

bindd
	modmask: 68
	submap: 
	key: right
	keycode: 0
	catchall: false
	description: Move window and switch to the previous workspace
	dispatcher: movetoworkspace
	arg: +1

bindd
	modmask: 65
	submap: 
	key: 1
	keycode: 0
	catchall: false
	description: Move window silently to workspace 1
	dispatcher: movetoworkspacesilent
	arg: 1

bindd
	modmask: 65
	submap: 
	key: 2
	keycode: 0
	catchall: false
	description: Move window silently to workspace 2
	dispatcher: movetoworkspacesilent
	arg: 2

bindd
	modmask: 65
	submap: 
	key: 3
	keycode: 0
	catchall: false
	description: Move window silently to workspace 3
	dispatcher: movetoworkspacesilent
	arg: 3

bindd
	modmask: 65
	submap: 
	key: 4
	keycode: 0
	catchall: false
	description: Move window silently to workspace 4
	dispatcher: movetoworkspacesilent
	arg: 4

bindd
	modmask: 65
	submap: 
	key: 5
	keycode: 0
	catchall: false
	description: Move window silently to workspace 5
	dispatcher: movetoworkspacesilent
	arg: 5

bindd
	modmask: 65
	submap: 
	key: 6
	keycode: 0
	catchall: false
	description: Move window silently to workspace 6
	dispatcher: movetoworkspacesilent
	arg: 6

bindd
	modmask: 65
	submap: 
	key: 7
	keycode: 0
	catchall: false
	description: Move window silently to workspace 7
	dispatcher: movetoworkspacesilent
	arg: 7

bindd
	modmask: 65
	submap: 
	key: 8
	keycode: 0
	catchall: false
	description: Move window silently to workspace 8
	dispatcher: movetoworkspacesilent
	arg: 8

bindd
	modmask: 65
	submap: 
	key: 9
	keycode: 0
	catchall: false
	description: Move window silently to workspace 9
	dispatcher: movetoworkspacesilent
	arg: 9

bindd
	modmask: 65
	submap: 
	key: 0
	keycode: 0
	catchall: false
	description: Move window silently to workspace 10
	dispatcher: movetoworkspacesilent
	arg: 10

bindd
	modmask: 64
	submap: 
	key: 1
	keycode: 0
	catchall: false
	description: Switch to workspace 1
	dispatcher: workspace
	arg: 1

bindd
	modmask: 64
	submap: 
	key: 2
	keycode: 0
	catchall: false
	description: Switch to workspace 2
	dispatcher: workspace
	arg: 2

bindd
	modmask: 64
	submap: 
	key: 3
	keycode: 0
	catchall: false
	description: Switch to workspace 3
	dispatcher: workspace
	arg: 3

bindd
	modmask: 64
	submap: 
	key: 4
	keycode: 0
	catchall: false
	description: Switch to workspace 4
	dispatcher: workspace
	arg: 4

bindd
	modmask: 64
	submap: 
	key: 5
	keycode: 0
	catchall: false
	description: Switch to workspace 5
	dispatcher: workspace
	arg: 5

bindd
	modmask: 64
	submap: 
	key: 6
	keycode: 0
	catchall: false
	description: Switch to workspace 6
	dispatcher: workspace
	arg: 6

bindd
	modmask: 64
	submap: 
	key: 7
	keycode: 0
	catchall: false
	description: Switch to workspace 7
	dispatcher: workspace
	arg: 7

bindd
	modmask: 64
	submap: 
	key: 8
	keycode: 0
	catchall: false
	description: Switch to workspace 8
	dispatcher: workspace
	arg: 8

bindd
	modmask: 64
	submap: 
	key: 9
	keycode: 0
	catchall: false
	description: Switch to workspace 9
	dispatcher: workspace
	arg: 9

bindd
	modmask: 64
	submap: 
	key: 0
	keycode: 0
	catchall: false
	description: Switch to workspace 10
	dispatcher: workspace
	arg: 10

bindd
	modmask: 64
	submap: 
	key: PERIOD
	keycode: 0
	catchall: false
	description: Scroll through workspaces incrementally
	dispatcher: workspace
	arg: e+1

bindd
	modmask: 64
	submap: 
	key: COMMA
	keycode: 0
	catchall: false
	description: Scroll through workspaces decrementally
	dispatcher: workspace
	arg: e-1

bindd
	modmask: 64
	submap: 
	key: mouse_down
	keycode: 0
	catchall: false
	description: Scroll through workspaces incrementally
	dispatcher: workspace
	arg: e+1

bindd
	modmask: 64
	submap: 
	key: mouse_up
	keycode: 0
	catchall: false
	description: Scroll through workspaces decrementally
	dispatcher: workspace
	arg: e-1

bindd
	modmask: 64
	submap: 
	key: slash
	keycode: 0
	catchall: false
	description: Switch to the previous workspace
	dispatcher: workspace
	arg: previous

bindd
	modmask: 64
	submap: 
	key: minus
	keycode: 0
	catchall: false
	description: Move active window to Special workspace
	dispatcher: movetoworkspace
	arg: special

bindd
	modmask: 64
	submap: 
	key: equal
	keycode: 0
	catchall: false
	description: Toggles the Special workspace
	dispatcher: togglespecialworkspace
	arg: special

bindd
	modmask: 64
	submap: 
	key: F1
	keycode: 0
	catchall: false
	description: Call special workspace scratchpad
	dispatcher: togglespecialworkspace
	arg: scratchpad

bindd
	modmask: 73
	submap: 
	key: F1
	keycode: 0
	catchall: false
	description: Move active window to special workspace scratchpad
	dispatcher: movetoworkspacesilent
	arg: special:scratchpad


