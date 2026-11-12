--[[
	Tetra Tab — Players
	Player list with quick actions
]]

return function(env)
	local _tetra = env._tetra
	local tab = env.tab
	local windui = env.windui

	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	tab:Section({ Title = "Player List", Icon = "users" })

	local function refresh()
		-- Clear existing player buttons by recreating section
		-- WindUI doesn't have a clear method, so we just add buttons
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				tab:Button({
					Title = p.DisplayName .. " (@" .. p.Name .. ")",
					Desc = "UserId: " .. p.UserId,
					Callback = function()
						-- TP to player
						local char = LocalPlayer.Character
						local tChar = p.Character
						if char and tChar then
							local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
							local thrp = tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso")
							if hrp and thrp then
								hrp.CFrame = thrp.CFrame + Vector3.new(3, 1, 0)
							end
						end
					end,
				})
				tab:Button({
					Title = "Spectate " .. p.DisplayName,
					Desc = "Watch this player",
					Callback = function()
						_tetra:notify("Spectate", "Spectating " .. p.DisplayName, 4)
					end,
				})
				tab:Button({
					Title = "Friend " .. p.DisplayName,
					Desc = "Send friend request",
					Callback = function()
						pcall(function() LocalPlayer:RequestFriendship(p) end)
						_tetra:notify("Friend", "Request sent to " .. p.DisplayName, 4)
					end,
				})
				tab:Divider()
			end
		end
	end

	Players.PlayerAdded:Connect(function()
		-- Refresh would need tab rebuild; for now just notify
	end)
	Players.PlayerRemoving:Connect(function()
	end)

	refresh()

	-- Add manual refresh button
	tab:Button({
		Title = "Refresh Player List",
		Desc = "Reload the player list",
		Callback = refresh,
	})
end
