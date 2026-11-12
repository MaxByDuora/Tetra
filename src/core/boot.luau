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

function boot:initEnv(env)
	env.players = Players
	env.lp = LocalPlayer
	env.runService = RunService
	env.userInputService = game:GetService("UserInputService")
	env.tweenService = game:GetService("TweenService")
	env.coreGui = game:GetService("CoreGui")
	env.workspace = workspace
	env.lighting = game:GetService("Lighting")
	env.starterGui = game:GetService("StarterGui")
	env.teleportService = env.teleportService
	env.soundService = env.soundService
	env.replicatedStorage = env.replicatedStorage
	env.C = env.C
	env._nvL = { lp = LocalPlayer }

	env.reg = boot.createReg(_G._tetra_cmdReg)
	_G.reg = env.reg
	return env
end

function boot:createReg(cmdTable)
	local reg = {}
	function reg(name, desc, args, aliases, fn)
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
