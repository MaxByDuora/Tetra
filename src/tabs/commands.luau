--[[
	Tetra Tab — Commands Browser
	Browse and execute registered commands with proper UI controls
]]

return function(env)
	local _tetra = env._tetra
	local kit = env.kit
	local tab = env.tab
	local windui = env.windui

	local cmdReg = _G._tetra_cmdReg or {}

	tab:Section({ Title = "Command Registry", Icon = "list" })
	tab:Paragraph({ Title = tostring(#cmdReg) .. " commands registered", Desc = "Execute commands directly from this panel" })
	tab:Divider()

	-- Group commands by type for clean layout
	for _, cmd in ipairs(cmdReg) do
		local ui = cmd.ui or {}
		local uiType = ui.type or "button"

		if uiType == "slider" then
			local min = tonumber(ui.min) or 0
			local max = tonumber(ui.max) or 100
			local default = tonumber(ui.default) or 0
			local label = ui.label or cmd.name

			tab:Slider({
				Title = label,
				Desc = cmd.desc or "",
				Min = min,
				Max = max,
				Value = default,
				Callback = function(v)
					-- Run command with slider value
					local parts = { cmd.name, tostring(math.floor(v)) }
					local ok, ret = pcall(cmd.exec, parts)
					if not ok then
						_tetra:notify("Commands", "Error running " .. cmd.name, 4)
					end
				end,
			})

		elseif uiType == "toggle" then
			local onCmd = ui.on_cmd or cmd.name
			local offCmd = ui.off_cmd or ""

			tab:Toggle({
				Title = cmd.name,
				Desc = cmd.desc or "",
				Value = false,
				Callback = function(on)
					if on then
						local ok, ret = pcall(cmd.exec, { cmd.name })
						if not ok then
							_tetra:notify("Commands", "Error running " .. cmd.name, 4)
						end
					else
						if offCmd and offCmd ~= "" then
							-- Find and run the off command
							for _, c in ipairs(cmdReg) do
								if c.name == offCmd then
									pcall(c.exec, { offCmd })
									break
								end
							end
						end
					end
				end,
			})

		elseif uiType == "input" then
			local placeholder = ui.placeholder or ""

			tab:Input({
				Title = cmd.name,
				Placeholder = placeholder,
				Desc = cmd.desc or "",
				Callback = function(text)
					if text == "" then return end
					local parts = { cmd.name, text }
					local ok, ret = pcall(cmd.exec, parts)
					if not ok then
						_tetra:notify("Commands", "Error running " .. cmd.name, 4)
					end
				end,
			})

		else
			-- Default: button
			local title = cmd.name
			if cmd.args and cmd.args ~= "" then
				title = title .. " <" .. cmd.args .. ">"
			end

			tab:Button({
				Title = title,
				Desc = cmd.desc or "",
				Callback = function()
					local ok, ret = pcall(cmd.exec, { cmd.name })
					if not ok then
						_tetra:notify("Commands", "Error running " .. cmd.name, 4)
					end
				end,
			})
		end

		tab:Divider()
	end

	_tetra:notify("Commands", "Loaded " .. #cmdReg .. " commands", 4)
end
