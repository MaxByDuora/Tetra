--[[
	Tetra Tab — Music
	SoundCloud music player integration
	Downloads tracks locally then plays via rbxasset:// (getcustomasset)
]]

return function(env)
	local _tetra = env._tetra
	local kit = env.kit
	local tab = env.tab
	local windui = env.windui

	local musicplayer = require(script.Parent.Parent:WaitForChild("music"):WaitForChild("musicplayer"))

	tab:Section({ Title = "SoundCloud Player", Icon = "music" })

	-- Now playing info
	local nowPlayingLbl = tab:Paragraph({ Title = "No track playing", Desc = "SoundCloud · Tetra" })

	tab:Divider()

	-- Search input
	local searchBox = tab:Input({
		Title = "Search SoundCloud",
		Placeholder = "Enter track name or URL...",
		Callback = function(text)
			if text == "" then return end
			_tetra:notify("Music", "Searching SoundCloud for: " .. text, 4)
			musicplayer.search(text, function(tracks)
				if #tracks == 0 then
					_tetra:notify("Music", "No tracks found", 4)
					return
				end
				for _, track in ipairs(tracks) do
					tab:Button({
						Title = track.title or "Unknown",
						Desc = (track.artist or "SoundCloud") .. " · SoundCloud",
						Callback = function()
							_tetra:notify("Music", "Preparing: " .. (track.title or "Unknown") .. " (downloading...)", 6)
							task.spawn(function()
								local ok, err = musicplayer:play(track)
								if ok then
									nowPlayingLbl:Update and nowPlayingLbl:Update({ Title = track.title or "Unknown", Desc = (track.artist or "SoundCloud") .. " · SoundCloud" })
									_tetra:notify("Music", "Now playing: " .. (track.title or "Unknown"), 5)
								else
									_tetra:notify("Music", "Play failed: " .. tostring(err), 5)
								end
							end)
						end,
					})
				end
			end)
		end,
	})

	tab:Divider()

	-- Playback controls section
	tab:Section({ Title = "Playback", Icon = "play" })

	tab:Button({
		Title = "Play / Pause",
		Desc = "Toggle playback",
		Callback = function()
			if musicplayer then
				if musicplayer:isPlaying() then
					musicplayer:pause()
					_tetra:notify("Music", "Paused", 4)
				else
					musicplayer:resume()
					_tetra:notify("Music", "Playing", 4)
				end
			end
		end,
	})

	tab:Button({
		Title = "Stop",
		Desc = "Stop playback",
		Callback = function()
			if musicplayer then
				musicplayer:stop()
				_tetra:notify("Music", "Stopped", 4)
			end
		end,
	})

	tab:Slider({
		Title = "Volume",
		Min = 0,
		Max = 100,
		Value = math.floor(_tetra.config.musicVolume * 100),
		Callback = function(v)
			if musicplayer then musicplayer:setVolume(v / 100) end
			_tetra.config.musicVolume = v / 100
		end,
	})

	_tetra:notify("Music", "SoundCloud tab ready", 4)
end
