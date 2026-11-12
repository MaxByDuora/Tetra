--[[
	Tetra Module — Command Registration
	Central registry for all Tetra commands
]]

local commandreg = {}

local _cmdReg = {}

function commandreg:register(name, desc, args, aliases, fn)
	local entry = {
		name = name,
		desc = desc or "",
		args = args or "",
		aliases = aliases or {},
		exec = fn,
	}
	table.insert(_cmdReg, entry)
	return entry
end

function commandreg:getAll()
	return _cmdReg
end

function commandreg:find(name)
	for _, c in ipairs(_cmdReg) do
		if c.name == name then return c end
		for _, a in ipairs(c.aliases or {}) do
			if a == name then return c end
		end
	end
	return nil
end

function commandreg:count()
	return #_cmdReg
end

-- Expose globally for tabs and command runner
_G._tetra_cmdReg = _cmdReg
commandreg._cmdReg = _cmdReg

return commandreg
