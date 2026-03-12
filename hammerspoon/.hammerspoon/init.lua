-- Hammerspoon configuration
require("screenshot")
require("window-switcher")
require("launch")
require("focus-follows-close")

-- Auto-reload on config change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()
