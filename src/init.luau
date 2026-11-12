--[[
    Tetra v1.0 - Loader
    Run: loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL/tetra.lua"))()
    
    Setup:
    1. Push this folder to GitHub
    2. Change GITHUB_RAW below to your repo URL
    3. Run loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL/tetra.lua"))() in your executor
]]

-- CONFIGURE THIS
local GITHUB_RAW = "https://raw.githubusercontent.com/MaxByDuora/tetra/main/src/"

-- Build environment
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.LocalPlayerAdded:Wait()
end

local env = {
    players = Players,
    lp = LocalPlayer,
    runService = RunService,
    userInputService = UserInputService,
    tweenService = TweenService,
    coreGui = CoreGui,
    workspace = workspace,
    lighting = game:GetService("Lighting"),
    starterGui = game:GetService("StarterGui"),
    teleportService = TeleportService,
    soundService = game:GetService("SoundService"),
    replicatedStorage = game:GetService("ReplicatedStorage"),
    mouse = LocalPlayer:GetMouse(),
    _nvL = { lp = LocalPlayer },
    C = {},
    _cs = {},
}

function env.findPlayers(query)
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
    table.insert(_G._tetra_cmdReg, entry)
    return entry
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

-- Load boot module
local bootFn = loadModule("core/boot")
local env2 = bootFn(env)
Tetra.env = env

-- Load configs
local configsFn = loadModule("core/configs")
if configsFn then
    Tetra.configs = configsFn({ _tetra = Tetra, HttpService = HttpService })
end

-- Load WindUI
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

-- Load tabs
local homeTab = Window:Tab({ Title = "Home", Icon = "home" })
local settingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local commandsTab = Window:Tab({ Title = "Commands", Icon = "list" })
local musicTab = Window:Tab({ Title = "Music", Icon = "music" })
local playersTab = Window:Tab({ Title = "Players", Icon = "users" })

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
        configs = Tetra.configs,
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

_tetra:notify("Tetra", "Hub loaded - " .. tostring(#_G._tetra_cmdReg or 0) .. " commands ready", 5)

Window:Toggle()
return Tetra
