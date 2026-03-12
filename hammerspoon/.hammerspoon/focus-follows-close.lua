-- Focus the next window when the focused window is destroyed
local wf = hs.window.filter.new()
wf:subscribe(hs.window.filter.windowDestroyed, function()
    local win = hs.window.focusedWindow()
    if not win then
        local allWindows = hs.window.orderedWindows()
        if #allWindows > 0 then
            allWindows[1]:focus()
        end
    end
end)
