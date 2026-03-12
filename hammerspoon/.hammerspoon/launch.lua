-- Launch apps
-- Cmd+Return (keycode 36) = open new kitty OS window (single instance)
hs.hotkey.bind({"cmd"}, 36, function()
    hs.task.new("/Applications/kitty.app/Contents/MacOS/kitty", nil, {"--single-instance", "--directory", os.getenv("HOME")}):start()
end)
