--[[
    Tetra v1.0 — Custom Liquid Glass Hub
    Entry point (run tetra.lua directly in your executor)
    Uses official WindUI library
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.LocalPlayerAdded:Wait()
end

-- Build environment
local env = {}
env.players = Players
env.lp = LocalPlayer
env.runService = RunService
env.userInputService = UserInputService
env.tweenService = TweenService
env.coreGui = CoreGui
env.workspace = workspace
env.lighting = game:GetService("Lighting")
env.starterGui = game:GetService("StarterGui")
env.teleportService = TeleportService
env.soundService = game:GetService("SoundService")
env.replicatedStorage = game:GetService("ReplicatedStorage")
env.mouse = LocalPlayer:GetMouse()
env._nvL = { lp = LocalPlayer }
env.C = {}
env._cs = {}

local function findPlayers(query)
    if type(query) ~= "string" or query == "" then return {} end
    local q = query:lower()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local name = p.Name:lower()
        local display = p.DisplayName:lower()
        if name == q or display == q or name:find(q, 1, true) or display:find(q, 1, true) then
            out[#out + 1] = p
        end
    end
    return out
end
env.findPlayers = findPlayers

function env.safeHttpGet(url)
    if type(url) ~= "string" then return nil end
    local low = url:lower()
    if low:find("soundcloud") or low:find("sc-") then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok then return res end
    end
    return nil
end

function env.safeLoadstring(src)
    if type(src) ~= "string" then return nil end
    return loadstring(src)
end

-- Load module from src/<name>.luau
local function loadModule(name)
    local path = "src/" .. name .. ".luau"
    local ok, src = pcall(readfile, path)
    if ok and type(src) == "string" and src ~= "" then
        return loadstring(src, "=" .. name)
    end
    return nil
end

-- Load all commands from all_commands.luau
local allCmdSrc = loadfile("src/commands/all_commands.luau")
if allCmdSrc then
    local allCmdFn = loadstring(allCmdSrc, "=cmds/all_commands")
    if allCmdFn then
        local ok2, cmdMod = pcall(allCmdFn)
        if ok2 and type(cmdMod) == "function" then
            pcall(function() cmdMod(env) end)
        end
    end
end

-- Load core boot module
local bootFn = loadModule("core/boot")
if bootFn then
    env = bootFn(env)
end

-- Load configs module
local configsFn = loadModule("core/configs")
if configsFn then
    Tetra.configs = configsFn({ _tetra = Tetra, HttpService = HttpService })
end

-- Load official WindUI library
local winduiFn = loadModule("lib/WindUI")
local WindUI = winduiFn()
Tetra.WindUI = WindUI

-- Create main window
local Window = WindUI:CreateWindow({
    Title = "Tetra",
    Author = "Tetra Hub",
    Icon = "droplet",
    Folder = "Tetra",
    Size = UDim2.fromOffset(800, 500),
    MinSize = Vector2.new(560, 350),
    ToggleKey = Enum.KeyCode.RightShift,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 220,
    BackgroundImageTransparency = 0.35,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() end,
    },
})
Tetra.Window = Window

-- Register tabs
local homeTab = Window:Tab({ Title = "Home", Icon = "home" })
local settingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local commandsTab = Window:Tab({ Title = "Commands", Icon = "list" })
local musicTab = Window:Tab({ Title = "Music", Icon = "music" })
local playersTab = Window:Tab({ Title = "Players", Icon = "users" })

-- Load tabs
require(script:WaitForChild("tabs"):WaitForChild("home"))({
    _tetra = Tetra,
    kit = WindUI,
    tab = homeTab,
    window = Window,
    windui = WindUI,
})

require(script:WaitForChild("tabs"):WaitForChild("settings"))({
    _tetra = Tetra,
    kit = WindUI,
    configs = configs,
    tab = settingsTab,
    window = Window,
    windui = WindUI,
})

require(script:WaitForChild("tabs"):WaitForChild("commands"))({
    _tetra = Tetra,
    kit = WindUI,
    tab = commandsTab,
    window = Window,
    windui = WindUI,
})

require(script:WaitForChild("tabs"):WaitForChild("music"))({
    _tetra = Tetra,
    kit = WindUI,
    tab = musicTab,
    window = Window,
    windui = WindUI,
})

require(script:WaitForChild("tabs"):WaitForChild("players"))({
    _tetra = Tetra,
    kit = WindUI,
    tab = playersTab,
    window = Window,
    windui = WindUI,
})

-- Load features
local flyMod = loadModule("features/fly")
if flyMod then
    Tetra.fly = flyMod({
        _tetra = Tetra,
        kit = WindUI,
        configs = configs,
        windui = WindUI,
    })
end

local espMod = loadModule("features/esp")
if espMod then
    Tetra.esp = espMod({
        _tetra = Tetra,
        kit = WindUI,
        configs = Tetra.configs,
        windui = WindUI,
    })
end

-- Load music player
local musicplayer = loadModule("music/musicplayer")
if musicplayer then
    Tetra.musicplayer = musicplayer({
        _tetra = Tetra,
        kit = WindUI,
        configs = Tetra.configs,
        windui = WindUI,
    })
end

_tetra:notify("Tetra", "Hub loaded — " .. tostring(#_G._tetra_cmdReg or 0) .. " commands ready", 5)

Window:Toggle()
return Tetra