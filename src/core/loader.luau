--[[
	Tetra Core — Loader
	Loads all Tetra modules in correct order
]]

local loader = {}

local src = script.Parent

function loader:requireModule(relativePath)
	local ok, mod = pcall(function()
		return require(src:WaitForChild(relativePath))
	end)
	if not ok then
		warn("Tetra loader: failed to load " .. tostring(relativePath) .. ": " .. tostring(mod))
		return nil
	end
	return mod
end

function loader:loadAll(tetra)
	local modules = {}

	-- Core
	modules.boot = self:requireModule("core/boot.luau")
	modules.http = self:requireModule("core/http.luau")
	modules.configs = self:requireModule("core/configs.luau")

	-- UI (WindUI is loaded directly in init)
	modules.kit = nil -- WindUI is used directly

	-- Tabs
	modules.home = self:requireModule("tabs/home.luau")
	modules.settings = self:requireModule("tabs/settings.luau")
	modules.commands = self:requireModule("tabs/commands.luau")
	modules.music = self:requireModule("tabs/music.luau")
	modules.players = self:requireModule("tabs/players.luau")

	-- Music
	modules.musicplayer = self:requireModule("music/musicplayer.luau")

	-- Features
	modules.fly = self:requireModule("features/fly.luau")
	modules.esp = self:requireModule("features/esp.luau")

	-- Island
	modules.notifications = self:requireModule("island/notifications.luau")
	modules.dynamic = self:requireModule("island/dynamic.luau")

	-- Module registration
	modules.commandreg = self:requireModule("modules/commandreg.luau")
	modules.tabreg = self:requireModule("modules/tabreg.luau")

	return modules
end

return loader
