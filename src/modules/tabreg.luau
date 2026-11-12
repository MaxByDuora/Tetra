--[[
	Tetra Module — Tab Registration
	Manages tab registration for the Window
]]

local tabreg = {}

local _tabs = {}

function tabreg:register(name, icon, moduleFn, env)
	local entry = {
		name = name,
		icon = icon or "📄",
		module = moduleFn,
		env = env or {},
	}
	table.insert(_tabs, entry)
	return entry
end

function tabreg:getAll()
	return _tabs
end

return tabreg
