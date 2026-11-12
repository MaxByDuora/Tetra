--[[
	Tetra Tab — Settings
	Local-only configuration (no external saves)
]]

return function(env)
	local _tetra = env._tetra
	local tab = env.tab
	local configs = env.configs
	local windui = env.windui

	-- Appearance section
	tab:Section({ Title = "Appearance", Icon = "palette" })

	tab:Toggle({
		Title = "Liquid Glass Transparency",
		Desc = "Enable transparent window background",
		Value = true,
		Callback = function(on)
			_tetra.config.transparent = on
		end,
	})

	tab:Toggle({
		Title = "Enable Notifications",
		Desc = "Show toast notifications",
		Value = true,
		Callback = function(on)
			_tetra.config.notifyEnabled = on
		end,
	})

	tab:Toggle({
		Title = "Auto-Execute on Load",
		Desc = "Run commands automatically on hub start",
		Value = true,
		Callback = function(on)
			_tetra.config.autoExecEnabled = on
		end,
	})

	tab:Slider({
		Title = "Music Volume",
		Desc = "SoundCloud player volume",
		Min = 0,
		Max = 100,
		Value = 50,
		Callback = function(v)
			_tetra.config.musicVolume = v / 100
		end,
	})

	tab:Divider()

	-- Tetra Info section
	tab:Section({ Title = "Tetra Info", Icon = "info" })

	tab:Paragraph({ Title = "Version", Desc = "Tetra v" .. _tetra.version })
	tab:Paragraph({ Title = "Storage", Desc = "Settings saved locally in Tetra/ folder" })
	tab:Paragraph({ Title = "UI Library", Desc = "WindUI (official)" })
	tab:Paragraph({ Title = "Theme", Desc = "Pure Liquid Glass" })

	tab:Divider()

	tab:Button({
		Title = "Open Commands List",
		Desc = "Browse all registered commands",
		Callback = function()
			-- Switch to Commands tab
			for _, t in ipairs(window.TabModule.Tabs or {}) do
				if t.Title == "Commands" then
					t:Select()
					break
				end
			end
		end,
	})
end
