--[[
    Tetra v1.0 — Loader
    Run this in your executor:
    loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL/tetra.lua"))()
    
    Setup:
    1. Push this entire Tetra/ folder to a GitHub repo
    2. Replace GITHUB_RAW below with your raw GitHub URL
    3. Run loadstring(game:HttpGet("YOUR_GITHUB_RAW/tetra.lua"))()
]]

-- CONFIGURE THIS — Replace with your GitHub raw URL
local GITHUB_RAW = "https://raw.githubusercontent.com/YOUR_USERNAME/tetra/main/src/"

-- Helper: load file (local first, then remote HTTP)
local function loadModule(name)
    local path = "src/" .. name .. ".luau"
    local src = loadfile(path)
    if not src then
        -- Try remote
        local ok, res = pcall(game.HttpGet, game, GITHUB_RAW .. name .. ".luau")
        if ok and type(res) == "string" and res ~= "" then
            src = res
        end
    end
    if not src then
        warn("Tetra: module not found: " .. name)
        return nil
    end
    return loadstring(src, "=" .. name)
end

-- Build environment
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local env = {
    players = Players,
    lp = LocalPlayer,
    runService = game:GetService("RunService"),
    userInputService = game:GetService("UserInputService"),
    tweenService = game:GetService("TweenService"),
    coreGui = game:GetService("CoreGui"),
    workspace = workspace,
    lighting = game:GetService("Lighting"),
    starterGui = game:GetService("StarterGui"),
    teleportService = game:GetService("TeleportService"),
    soundService = game:GetService("SoundService"),
    replicatedStorage = game:GetService("ReplicatedStorage"),
    mouse = LocalPlayer:GetMouse(),
    _nvL = { lp = LocalPlayer },
    C = {},
    _cs = {},
}

-- Safe HTTP (SoundCloud only)
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

-- Command registry
_G._tetra_cmdReg = _G._tetra_cmdReg or {}
function env.reg(name, desc, args, aliases, fn, ui)
    if type(aliases) == "function" then fn = aliases; aliases = {}; ui = fn end
    if type(fn) == "table" then ui = fn; fn = aliases; aliases = {} end
    aliases = aliases or {}
    if type(aliases) ~= "table" then aliases = {aliases} end
    ui = ui or {}
    table.insert(_G._tetra_cmdReg, {
        name = name,
        desc = desc or "",
        args = args or "",
        aliases = aliases,
        exec = fn,
        ui = ui,
    })
    return entry
end

-- Load all commands from all_commands.luau
local allCmdSrc = loadLocalFile("src/commands/all_commands.luau")
if allCmdSrc then
    local allCmdFn = loadstring(allCmdSrc, "=cmds/all_commands")
    if allCmdFn then
        local ok2, cmdMod = pcall(allCmdFn)
        if ok2 and type(cmdMod) == "function" then
            pcall(function() cmdMod(env) end)
            print("Tetra: Loaded " .. tostring(#_G._tetra_cmdReg or 0) .. " commands")
        else
            warn("Tetra: all_commands.luau error: " .. tostring(cmdMod))
        end
    else
        warn("Tetra: failed to compile all_commands.luau")
    end
end

-- Load core modules
local bootFn = loadModule("core/boot")
if bootFn then env = bootFn(env) end
Tetra.env = env

local configsFn = loadModule("core/configs")
if configsFn then Tetra.configs = configsFn({ _tetra = Tetra, HttpService = HttpService }) end

-- Load WindUI
local winduiFn = loadModule("lib/WindUI")
local WindUI = winduiFn and winduiFn() or require(script:WaitForChild("lib"):WaitForChild("WindUI"))
Tetra.WindUI = WindUI

-- Create window
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
    User = { Enabled = true, Anonymous = false, Callback = function() end },
})
Tetra.Window = Window

-- Load tabs
local homeTab = Window:Tab({ Title = "Home", Icon = "home" })
local settingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local commandsTab = Window:Tab({ Title = "Commands", Icon = "list" })
local musicTab = Window:Tab({ Title = "Music", Icon = "music" })
local playersTab = Window:Tab({ Title = "Players", Icon = "users" })

require(script:WaitForChild("tabs"):WaitForChild("home"))({
    _tetra = Tetra, kit = WindUI, tab = homeTab, window = Window, windui = WindUI,
})
require(script:WaitForChild("tabs"):WaitForChild("settings"))({
    _tetra = Tetra, kit = WindUI, configs = Tetra.configs, tab = settingsTab, window = Window, windui = WindUI,
})
require(script:WaitForChild("tabs"):WaitForChild("commands"))({
    _tetra = Tetra, kit = WindUI, tab = commandsTab, window = Window, windui = WindUI,
})
require(script:WaitForChild("tabs"):WaitForChild("music"))({
    _tetra = Tetra, kit = WindUI, tab = musicTab, window = Window, windui = WindUI,
})
require(script:WaitForChild("tabs"):WaitForChild("players"))({
    _tetra = Tetra, kit = WindUI, tab = playersTab, window = Window, windui = WindUI,
})

-- Load features
local flyMod = require(script:WaitForChild("features"):WaitForChild("fly"))
Tetra.fly = flyMod({ _tetra = Tetra, kit = WindUI, configs = Tetra.configs, windui = WindUI })

local espMod = require(script:WaitForChild("features"):WaitForChild("esp"))
Tetra.esp = espMod({ _tetra = Tetra, kit = WindUI, configs = Tetra.configs, windui = WindUI })

-- Load music player
local musicplayer = require(script:WaitForChild("music"):WaitForChild("musicplayer"))
Tetra.musicplayer = musicplayer

_tetra:notify("Tetra", "Hub loaded — " .. tostring(#_G._tetra_cmdReg or 0) .. " commands ready", 5)
Window:Toggle()

return Tetra
