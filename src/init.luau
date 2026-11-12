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
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Tetra = {
    version = "1.0",
    lp = LocalPlayer,
    playerGui = PlayerGui,
    coreGui = CoreGui,
    config = {
        theme = "Liquid",
        transparent = true,
        notifyEnabled = true,
        autoExecEnabled = true,
        toggleKey = Enum.KeyCode.RightShift,
        musicVolume = 0.5,
        musicSource = "soundcloud",
    },
    binds = {},
    Window = nil,
    WindUI = nil,
    configs = nil,
    fly = nil,
    esp = nil,
    musicplayer = nil,
}

function Tetra.notify(title, text, duration)
    if not Tetra.config.notifyEnabled then return end
    if Tetra.WindUI then
        Tetra.WindUI:Notify({
            Title = title or "Tetra",
            Text = text or "",
            Duration = duration or 5,
        })
    end
end

function Tetra.execCmd(name, parts)
    parts = parts or { name }
    local cmdReg = _G._tetra_cmdReg or {}
    for _, c in ipairs(cmdReg) do
        if c.name == name then
            local ok, ret = pcall(c.exec, parts)
            return ret
        end
        for _, a in ipairs(c.aliases or {}) do
            if a == name then
                local ok, ret = pcall(c.exec, parts)
                return ret
            end
        end
    end
    Tetra:notify("Commands", "Unknown command: " .. tostring(name), 4)
    return false
end

_G.Tetra = Tetra

-- Load core boot module using loadfile+loadstring
local function loadModule(relativePath)
    local path = "src/" .. relativePath .. ".luau"
    local ok, src = pcall(readfile, path)
    if ok and type(src) == "string" and src ~= "" then
        local fn, err = loadstring(src, "=" .. path)
        if fn then
            return fn
        else
            warn("Tetra: failed to compile " .. path .. ": " .. tostring(fn))
            return nil
        end
    end
    warn("Tetra: module not found: " .. path)
    return nil
end

-- Boot module
local bootFn = loadModule("core/boot")
local env = {}
if bootFn then
    env = bootFn(env) -- boot returns env
end
Tetra.env = env

-- Ensure env has everything
env._tetra = Tetra
env.reg = env.reg or function(name, desc, args, aliases, fn)
    if type(aliases) == "function" then
        fn = aliases
        aliases = {}
        ui = fn
    elseif type(fn) == "table" then
        ui = fn
        fn = aliases
        aliases = {}
    end
    aliases = aliases or {}
    if type(aliases) ~= "table" then aliases = {aliases} end
    ui = ui or {}
    local entry = {
        name = name,
        desc = desc or "",
        args = args or "",
        aliases = aliases,
        exec = fn,
        ui = ui,
    }
    table.insert(_G._tetra_cmdReg or {}, entry)
    return entry
end
_G._tetra_cmdReg = _G._tetra_cmdReg or {}

-- Load configs module
local configsFn = loadModule("core/configs")
if configsFn then
    local configs = configsFn({ _tetra = Tetra, HttpService = HttpService })
    Tetra.configs = configs
end

-- Load official WindUI library
local winduiFn = loadModule("lib/WindUI")
local WindUI
if winduiFn then
    WindUI = winduiFn()
else
    -- Fallback: try require if WindUI is a ModuleScript
    WindUI = require(script:WaitForChild("lib"):WaitForChild("WindUI"))
end
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
local flyMod = require(script:WaitForChild("features"):WaitForChild("fly"))
Tetra.fly = flyMod({
    _tetra = Tetra,
    kit = WindUI,
    configs = configs,
    windui = WindUI,
})

local espMod = require(script:WaitForChild("features"):WaitForChild("esp"))
Tetra.esp = espMod({
    _tetra = Tetra,
    kit = WindUI,
    configs = configs,
    windui = WindUI,
})

-- Load music player
local musicplayer = require(script:WaitForChild("music"):WaitForChild("musicplayer"))
Tetra.musicplayer = musicplayer

-- Load all commands from single file
task.defer(function()
    if Tetra.config.autoExecEnabled then
        local allCmdFile = "src/commands/all_commands.luau"
        local ok, src = pcall(readfile, allCmdFile)
        if ok and type(src) == "string" and src ~= "" then
            local fn, err = loadstring(src, "=cmds/all_commands")
            if fn then
                local ok2, cmdMod = pcall(fn)
                if ok2 and type(cmdMod) == "function" then
                    pcall(function() cmdMod(env) end)
                    local cmdCount = _G._tetra_cmdReg and #_G._tetra_cmdReg or 0
                    _tetra:notify("Tetra", "Loaded " .. cmdCount .. " commands", 5)
                    _G._tetra_cmdCount = cmdCount
                else
                    warn("Tetra: failed to execute all_commands.luau: " .. tostring(cmdMod))
                end
            else
                warn("Tetra: failed to compile all_commands.luau: " .. tostring(fn))
            end
        else
            _tetra:notify("Tetra", "Commands folder not found", 5)
        end
    end
end)

task.delay(1, function()
    if Tetra.config.notifyEnabled then
        Tetra:notify("Tetra", "Liquid glass hub loaded — ready", 5)
    end
end)

Window:Toggle()
return Tetra
