-- Screenshot keybind: Cmd+| (keycode 24 = pipe key on Real Programmers Dvorak)
-- hs.hotkey.bind accepts a keycode number as the key parameter
local scriptPath = os.getenv("HOME") .. "/.hammerspoon/scripts/screenshot.sh"

hs.hotkey.bind({"cmd"}, 24, function()
    hs.task.new("/bin/bash", nil, {scriptPath}):start()
end)
