--[[
	Tetra Core — Boot & Session Guard
	Initializes Tetra environment and session safety
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local boot = {}

-- Session guard: prevents duplicate loads
_G._tetra_session = _G._tetra_session or {
	loaded = false,
	version = "1.0",
	startTime = os.clock(),
}

if _G._tetra_session.loaded then
	warn("Tetra: session already loaded, skipping boot")
	return _G._tetra_session
end

_G._tetra_session.loaded = true

-- findPlayers: resolve a player search string to a list of Player objects
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

function boot:initEnv()
	local env = {}
	env.players = Players
	env.lp = LocalPlayer
	env.findPlayers = findPlayers
	env.runService = RunService
	env.httpService = HttpService
	env.userInputService = game:GetService("UserInputService")
	env.tweenService = game:GetService("TweenService")
	env.teleportService = game:GetService("TeleportService")
	env.coreGui = game:GetService("CoreGui")
	env.workspace = workspace
	env.lighting = game:GetService("Lighting")
	env.starterGui = game:GetService("StarterGui")
	env.replicatedStorage = game:GetService("ReplicatedStorage")
	env.soundService = game:GetService("SoundService")
	env.mouse = LocalPlayer:GetMouse()
	env._nvL = { lp = LocalPlayer }
	env.C = {}
	env._cs = _G._tetra_session or {}

	-- Safe HTTP (stubbed except SoundCloud)
	function env.safeHttpGet(url)
		if type(url) ~= "string" then return nil end
		local low = url:lower()
		if low:find("soundcloud") or low:find("sc-") then
			local ok, res = pcall(function()
				return game:HttpGet(url)
			end)
			if ok then return res end
		end
		return nil
	end

	function env.safeLoadstring(src)
		if type(src) ~= "string" then return nil end
		return loadstring(src)
	end

	return env
end

function boot:createReg(cmdTable)
	local reg = {}
	function reg(name, desc, args, aliases, fn, ui)
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
		table.insert(cmdTable, entry)
		return entry
	end
	return reg
end

return boot
