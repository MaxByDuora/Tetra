--[[
	Tetra UI Kit — Thin wrapper around official WindUI
	All UI creation goes through WindUI directly
]]

local WindUI = require(script.Parent.Parent:WaitForChild("lib"):WaitForChild("WindUI"))

local kit = {}
kit.WindUI = WindUI
kit.C = {
	accent = Color3.fromRGB(90, 170, 255),
	text = Color3.fromRGB(240, 240, 248),
	dim = Color3.fromRGB(150, 150, 164),
	sub = Color3.fromRGB(190, 190, 204),
	danger = Color3.fromRGB(239, 80, 80),
}

-- Pass-through to WindUI
kit.createWindow = function(spec)
	return WindUI:CreateWindow(spec)
end

kit.notify = function(spec)
	if _G.Tetra and _G.Tetra.WindUI then
		_G.Tetra.WindUI:Notify(spec)
	end
end

return kit
