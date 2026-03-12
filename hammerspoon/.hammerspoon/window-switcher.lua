-- Window switcher: Cmd+Space or Cmd+o (cycles windows of focused app on current desktop)
-- keycode 49 = Space
-- keycode 1 = physical QWERTY S position (RPD "o")
local function cycleAppWindows()
    local app = hs.application.frontmostApplication()
    if not app then return end

    local currentScreen = hs.screen.mainScreen()
    local wins = hs.fnutils.filter(app:allWindows(), function(w)
        return w:isStandard() and w:screen() == currentScreen
    end)

    if #wins < 2 then return end

    -- Sort by window ID for stable cycling order
    table.sort(wins, function(a, b) return a:id() < b:id() end)

    local focused = hs.window.focusedWindow()
    for i, w in ipairs(wins) do
        if w == focused then
            local next = wins[(i % #wins) + 1]
            next:focus()
            return
        end
    end
    wins[1]:focus()
end

hs.hotkey.bind({"cmd", "alt"}, 49, cycleAppWindows)  -- Cmd+Option+Space (keycode 49)
hs.hotkey.bind({"cmd", "alt"}, 1, cycleAppWindows)   -- Cmd+Option+o on RPD (physical QWERTY S, keycode 1)

-- Toggle between two most recent windows of the same app on current desktop
local function toggleRecentAppWindow()
    local app = hs.application.frontmostApplication()
    if not app then return end

    local currentScreen = hs.screen.mainScreen()
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:application() == app and w:isStandard() and w:screen() == currentScreen
    end)

    if #wins < 2 then return end

    wins[2]:focus()
end

hs.hotkey.bind({"cmd"}, 49, toggleRecentAppWindow)             -- Cmd+Space (keycode 49)
hs.hotkey.bind({"cmd"}, 1, toggleRecentAppWindow)              -- Cmd+o on RPD (physical QWERTY S, keycode 1)
