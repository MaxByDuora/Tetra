--[[
	Tetra Configs — Local-only settings
]]

return function(env)
	local _tetra = env._tetra
	local HttpService = env.HttpService

	local PATH = "Tetra/configs.json"
	local store = { values = {} }
	local pending = false

	local function save()
		if pending then return end
		pending = true
		task.delay(0.5, function()
			pending = false
			pcall(function()
				if not isfolder("Tetra") then makefolder("Tetra") end
				writefile(PATH, HttpService:JSONEncode(store))
			end)
		end)
	end

	local defaults = {
		theme = "Liquid",
		transparent = true,
		notifyEnabled = true,
		autoExecEnabled = true,
		toggleKey = "RightShift",
		musicVolume = 0.5,
		musicSource = "soundcloud",
	}

	local cfg = {}

	function cfg:load()
		pcall(function()
			if isfile and isfile(PATH) then
				local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(PATH))
				if ok and type(data) == "table" then
					store.values = data.values or {}
				end
			end
		end)
	end

	function cfg:applyDefaults()
		for k, v in pairs(defaults) do
			if store.values[k] == nil then
				store.values[k] = v
			end
		end
	end

	function cfg:read(key, default)
		if store.values[key] == nil then
			store.values[key] = type(default) ~= "nil" and default or defaults[key]
			return store.values[key]
		end
		return store.values[key]
	end

	function cfg:write(key, value)
		store.values[key] = value
		save()
	end

	cfg:load()
	cfg:applyDefaults()
	save()

	_tetra.configs = cfg
	return cfg
end
