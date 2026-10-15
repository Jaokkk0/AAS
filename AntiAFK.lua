-- AntiAFK.lua
-- runtime: Roblox client, executor (Luau, uses VirtualUser)
-- target: Players.LocalPlayer idle kick (~20 min)
-- load: loadstring(game:HttpGet("<raw url>"))()

if getgenv().ANTI_AFK_ACTIVE then
    warn("[anti-afk] already running")
    return
end
getgenv().ANTI_AFK_ACTIVE = true

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local NUDGE_INTERVAL = 60 -- seconds between synthetic inputs (must stay well under 20 min)

local function pulse(reason)
    local ok, err = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
    if not ok then
        warn("[anti-afk] pulse failed (" .. tostring(reason) .. "): " .. tostring(err))
    end
end

-- Reactive: fires when the engine flags the client as idle
local idleConn = player.Idled:Connect(function()
    pulse("idled")
end)

-- Proactive: periodic input so the idle timer never reaches the threshold
local running = true
task.spawn(function()
    while running do
        task.wait(NUDGE_INTERVAL)
        if not running then break end
        pulse("nudge")
    end
end)

-- Teardown handle: call getgenv().ANTI_AFK_STOP() to disable
getgenv().ANTI_AFK_STOP = function()
    running = false
    if idleConn then idleConn:Disconnect() end
    getgenv().ANTI_AFK_ACTIVE = false
    getgenv().ANTI_AFK_STOP = nil
    print("[anti-afk] stopped")
end

print("[anti-afk] active, nudge every " .. NUDGE_INTERVAL .. "s")
