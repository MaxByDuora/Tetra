--[[
    Tetra v1.0 — Custom Liquid Glass Hub
    ========================================
    LOADER — Run this in your executor:
    loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL/tetra.lua"))()

    SETUP:
    1. Push this entire Tetra/ folder to a GitHub repo
    2. Change GITHUB_RAW below to your raw GitHub URL
    3. Run loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/tetra/main/tetra.lua"))() in your executor
]]

-- ============================================================================
-- CONFIGURATION — EDIT THIS
-- ============================================================================
local GITHUB_RAW = "https://raw.githubusercontent.com/MaxByDuora/tetra/main/src/"
-- ============================================================================

-- Helper: load a .luau file (local first, then remote with tick cache-bust)
local function loadModule(name)
    local path = "src/" .. name .. ".luau"
    local src = loadfile(path)
    if not src then
        local ok, res = pcall(game.HttpGet, game, GITHUB_RAW .. name .. ".luau?t=" .. tick())
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
local allCmdSrc = loadModule("commands/all_commands")
if allCmdFn then
    pcall(allCmdFn(env))
end

-- Load core boot
local bootFn = loadModule("core/boot")
if bootFn then
    env = bootFn(env)
end
Tetra.env = env

-- Load configs
local configsFn = loadModule("core/configs")
if configsFn then
    Tetra.configs = configsFn({ _tetra = Tetra, HttpService = env.httpService })
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

-- Load tabs
local homeTab = Window:Tab({ Title = "Home", Icon = "home" })
local settingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local commandsTab = Window:Tab({ Title = "Commands", Icon = "list" })
local musicTab = Window:Tab({ Title = "Music", Icon = "music" })
local playersTab = Window:Tab({ Title = "Players", Icon = "users" })

local homeFn = loadModule("tabs/home")
if homeFn then pcall(homeFn({ _tetra = Tetra, kit = WindUI, tab = homeTab, window = Window, windui = WindUI })) end

local settingsFn = loadModule("tabs/settings")
if settingsFn then
    pcall(settingsFn({ _tetra = Tetra, kit = WindUI, configs = Tetra.configs, tab = settingsTab, window = Window, windui = WindUI }))
end

local commandsFn = loadModule("tabs/commands")
if commandsFn then
    pcall(commandsFn({ _tetra = Tetra, kit = WindUI, tab = commandsTab, window = Window, windui = WindUI }))
end)

local musicFn = loadModule("tabs/music")
if musicFn then
    pcall(musicFn({ _tetra = Tetra, kit = WindUI, tab = musicTab, window = Window, windui = WindUI }))
end)

local playersFn = loadModule("tabs/players")
if playersFn then
    pcall(playersFn({ _tetra = Tetra, kit = WindUI, tab = playersTab, window = Window, windui = WindUI }))
end)

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

-- Notify
_tetra:notify("Tetra", "Hub loaded — " .. tostring(#_G._tetra_cmdReg or 0) .. " commands ready", 5)

Window:Toggle()

return Tetra
