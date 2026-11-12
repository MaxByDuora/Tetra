--[[
	Tetra Tab — Home
	Welcome screen with quick stats and actions
]]

return function(env)
	local _tetra = env._tetra
	local tab = env.tab
	local window = env.window
	local configs = env.configs
	local windui = env.windui

	local Players = game:GetService("Players")

	-- Welcome section
	tab:Section({ Title = "Welcome", Icon = "sparkles" })
	tab:Paragraph({ Title = "Welcome to Tetra", Desc = "Pure liquid glass script hub — WindUI powered" })
	tab:Divider()

	-- Stats
	tab:Paragraph({ Title = "Version", Desc = _tetra.version })
	tab:Paragraph({ Title = "Players", Desc = tostring(#Players:GetPlayers()) })
	tab:Paragraph({ Title = "PlaceId", Desc = tostring(game.PlaceId) })
	tab:Divider()

	-- Quick Actions section
	tab:Section({ Title = "Quick Actions", Icon = "zap" })

	tab:Button({
		Title = "Open Console",
		Desc = "Open Roblox developer console",
		Callback = function()
			pcall(function()
				game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
			end)
		end,
	})

	tab:Button({
		Title = "Rejoin Server",
		Desc = "Rejoin the current server",
		Callback = function()
			pcall(function()
				local ts = game:GetService("TeleportService")
				if #Players:GetPlayers() <= 1 then
					LocalPlayer:Kick("\nRejoining...")
					task.wait()
					ts:Teleport(game.PlaceId, LocalPlayer)
				else
					ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
				end
			end)
		end,
	})

	tab:Button({
		Title = "Copy Job ID",
		Desc = "Copy server join link to clipboard",
		Callback = function()
			local link = "roblox://placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId)
			pcall(function() setclipboard(link) end)
			_tetra:notify("Tetra", "Job ID copied to clipboard", 4)
		end,
	})

	tab:Toggle({
		Title = "Notifications",
		Desc = "Enable/disable hub notifications",
		Value = true,
		Callback = function(on)
			_tetra.config.notifyEnabled = on
		end,
	})

	task.delay(2, function()
		if _tetra.config.notifyEnabled then
			_tetra:notify("Tetra", "Home tab loaded", 4)
		end
	end)
end
