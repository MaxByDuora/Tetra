--[[
	Tetra Music Player — SoundCloud Integration
	1. Scrape SoundCloud client_id from soundcloud.com JS assets
	2. Search tracks via api-v2.soundcloud.com
	3. Resolve transcoding/stream URL
	4. Download audio bytes to local file
	5. getcustomasset() → rbxasset:// URL
	6. Play via Roblox Sound object
	Only connects to SoundCloud (allowed external source)
]]

local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local musicplayer = {}

local currentSound = nil
local currentTrack = nil
local isPlaying = false
local volume = 0.5
local listeners = {}
local MUSIC_FOLDER = "Tetra/music"

-- ── HTTP request helper (supports multiple executors) ──────────────────────

local function httpRequest(url, method, headers, body)
	method = method or "GET"
	headers = headers or {}

	-- Try executor request functions first
	local req = (syn and syn.request)
		or http_request
		or request
		or (fluxus and fluxus.request)
		or (getgenv and getgenv()._request)

	if type(req) == "function" then
		local ok, res = pcall(req, {
			Url = url,
			Method = method,
			Headers = headers,
			Body = body,
		})
		if ok and type(res) == "table" then
			local bodyStr = type(res.Body) == "string" and res.Body or ""
			local code = tonumber(res.StatusCode) or 0
			if (res.Success == true or code == 0 or code < 400) and #bodyStr > 0 then
				return bodyStr
			end
		end
	end

	-- Fallback to game:HttpGet (GET only)
	if method == "GET" then
		local ok, data = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok and type(data) == "string" and #data > 0 then
			return data
		end
	end

	return nil
end

local function httpGet(url)
	return httpRequest(url, "GET")
end

-- ── File helpers ───────────────────────────────────────────────────────────

local function ensureMusicFolder()
	pcall(function()
		if not isfolder("Tetra") then makefolder("Tetra") end
		if not isfolder(MUSIC_FOLDER) then makefolder(MUSIC_FOLDER) end
	end)
end

local function safeFileName(name)
	name = tostring(name or "track")
	name = name:gsub('[<>:"/\\|%?%*]', "")
	name = name:gsub("%s+", " ")
	name = name:match("^%s*(.-)%s*$") or name
	if #name > 80 then name = name:sub(1, 80) end
	if name == "" then name = "track" end
	return name
end

local function getAssetPath(path)
	-- Prefer getcustomasset, fallback to getsynasset
	if type(getcustomasset) == "function" then
		local ok, res = pcall(getcustomasset, path)
		if ok and type(res) == "string" and res ~= "" then return res end
	end
	if type(getsynasset) == "function" then
		local ok, res = pcall(getsynasset, path)
		if ok and type(res) == "string" and res ~= "" then return res end
	end
	return nil
end

-- ── SoundCloud client_id extraction ────────────────────────────────────────

local _scClientId, _scClientAt = nil, 0

local function fetchScClientId()
	if _scClientId and (tick() - _scClientAt) < 3600 then
		return _scClientId
	end

	local html = httpGet("https://soundcloud.com")
	if type(html) ~= "string" then return nil end

	-- Extract JS asset URLs from soundcloud.com HTML
	local scripts = {}
	for src in html:gmatch('src="(https://a%%-v2%.sndcdn%.com/assets/[^"]+%.js)"') do
		scripts[#scripts + 1] = src
	end
	if #scripts == 0 then
		for src in html:gmatch("src='(https://a%%-v2%.sndcdn%.com/assets/[^']+%.js)'") do
			scripts[#scripts + 1] = src
		end
	end

	table.sort(scripts, function(a, b)
		local as = (a:find("48%-", 1, true) or a:find("client", 1, true)) and 0 or 1
		local bs = (b:find("48%-", 1, true) or b:find("client", 1, true)) and 0 or 1
		return as < bs
	end)

	local maxCheck = math.min(#scripts, 12)
	for i = 1, maxCheck do
		local js = httpGet(scripts[i])
		if type(js) == "string" then
			local id = js:match('client_id%s*[:=]%s*"([%w%-_]+)"')
				or js:match("client_id%s*[:=]%s*'([%w%-_]+)'")
				or js:match(',client_id:"([%w%-_]+)"')
				or js:match('clientId%s*[:=]%s*"([%w%-_]+)"')
			if id and #id >= 16 then
				_scClientId = id
				_scClientAt = tick()
				return id
			end
		end
	end

	return _scClientId
end

-- ── SoundCloud track search ────────────────────────────────────────────────

local function searchTracks(query, limit)
	limit = limit or 20
	local cid = fetchScClientId()
	if not cid then return nil, "Could not get SoundCloud client id" end

	local url = "https://api-v2.soundcloud.com/search/tracks?q="
		.. HttpService:UrlEncode(query)
		.. "&client_id=" .. tostring(cid)
		.. "&limit=" .. tostring(limit)
		.. "&offset=0&linked_partitioning=1&app_locale=en"

	local body = httpGet(url)
	if not body then
		-- Retry with refreshed client_id
		_scClientId = nil
		cid = fetchScClientId()
		if not cid then return nil, "Could not get SoundCloud client id" end
		url = url:gsub("client_id=[%w%-_]+", "client_id=" .. cid)
		body = httpGet(url)
	end
	if not body then return nil, "Search request failed" end

	local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
	if not ok or type(data) ~= "table" then return nil, "Bad search response" end

	local collection = data.collection
	if type(collection) ~= "table" then return nil, "No results" end

	local out = {}
	for _, tr in ipairs(collection) do
		if type(tr) == "table" and (tr.kind == "track" or (tr.id and tr.title)) then
			local user = tr.user or {}
			local media = tr.media or {}
			local trans = type(media.transcodings) == "table" and media.transcodings or {}
			local isProtected = false
			if #trans > 0 then
				isProtected = true
				for _, t in ipairs(trans) do
					if type(t) == "table" and type(t.format) == "table" then
						local proto = tostring(t.format.protocol or "")
						if proto == "progressive" or proto == "hls" then
							isProtected = false
							break
						end
					end
				end
			end

			out[#out + 1] = {
				id = tr.id,
				title = tostring(tr.title or "Untitled"),
				artist = tostring(user.username or user.full_name or "SoundCloud"),
				permalink = tostring(tr.permalink_url or ""),
				duration = tonumber(tr.duration) or 0,
				streamable = tr.streamable ~= false,
				policy = tostring(tr.policy or ""),
				media = media,
				artwork = tostring(tr.artwork_url or user.avatar_url or ""),
				protected = isProtected,
				raw = tr,
			}
		end
	end

	return out, nil
end

-- ── URL joining helper ─────────────────────────────────────────────────────

local function joinUrl(base, rel)
	rel = tostring(rel or "")
	if rel:find("^https?://") then return rel end
	base = tostring(base or "")
	if rel:sub(1, 1) == "/" then
		local host = base:match("^(https?://[^/]+)")
		if host then return host .. rel end
	end
	local dir = base:match("^(https?://.+)/[^%s?]*")
	if dir then return dir .. "/" .. rel end
	return rel
end

-- ── Resolve playable stream URL from track ─────────────────────────────────

local function resolveTranscodingUrl(t, cid)
	if type(t) ~= "table" or type(t.url) ~= "string" or t.url == "" then return nil end
	local url = t.url
	if not url:find("client_id=", 1, true) then
		local sep = url:find("?", 1, true) and "&" or "?"
		url = url .. sep .. "client_id=" .. tostring(cid)
	end
	local infoBody = httpGet(url)
	if not infoBody then return nil end
	local ok, info = pcall(HttpService.JSONDecode, HttpService, infoBody)
	if ok and type(info) == "table" and type(info.url) == "string" then
		return info.url
	end
	return nil
end

local function resolveStreamUrl(track)
	local ok, url, err, kind = pcall(function()
		local cid = fetchScClientId()
		if not cid then return nil, "No client id" end

		local media = track and track.media
		local trans = media and type(media.transcodings) == "table" and media.transcodings or {}

		-- If no transcodings, fetch full track data
		if type(trans) ~= "table" or #trans == 0 then
			if track and track.id then
				local body = httpGet("https://api-v2.soundcloud.com/tracks/" .. tostring(track.id) .. "?client_id=" .. tostring(cid))
				if not body and type(track.permalink) == "string" and track.permalink ~= "" then
					body = httpGet("https://api-v2.soundcloud.com/resolve?url=" .. HttpService:UrlEncode(track.permalink) .. "&client_id=" .. tostring(cid))
				end
				if body then
					local ok2, full = pcall(HttpService.JSONDecode, HttpService, body)
					if ok2 and type(full) == "table" then
						media = full.media
						trans = media and type(media.transcodings) == "table" and media.transcodings or {}
						track.media = media
						if full.policy then track.policy = tostring(full.policy) end
						if full.streamable ~= nil then track.streamable = full.streamable ~= false end
						if type(full) == "table" then track.raw = full end
					end
				end
			end
		end

		local progressiveUrl, hlsMp3Url, aacUrl, aacRank, onlyProtected = nil, nil, nil, 0, false
		if type(trans) == "table" then
			onlyProtected = #trans > 0
			for _, t in ipairs(trans) do
				if type(t) == "table" and type(t.url) == "string" then
					local fmt = t.format or {}
					local proto = tostring(fmt.protocol or "")
					local mime = tostring(fmt.mime_type or ""):lower()
					local isMp3 = mime:find("audio/mpeg", 1, true) ~= nil and not mime:find("mpegurl", 1, true)

					if proto == "progressive" or proto == "hls" then
						onlyProtected = false
					end

					if proto == "progressive" and isMp3 then
						progressiveUrl = progressiveUrl or t.url
					elseif proto == "hls" and isMp3 then
						hlsMp3Url = hlsMp3Url or t.url
					elseif proto == "hls" and mime:find("mp4a", 1, true) then
						local rank = tostring(t.preset or ""):find("160", 1, true) and 2 or 1
						if rank > aacRank then
							aacUrl, aacRank = t.url, rank
						end
					end
				end
			end
		end

		-- Try each candidate URL
		for _, pick in ipairs({ { progressiveUrl, "mp3" }, { hlsMp3Url, "hls-mp3" }, { aacUrl, "aac" } }) do
			if pick[1] then
				local direct = resolveTranscodingUrl({ url = pick[1] }, cid)
				if type(direct) == "string" and #direct > 0 then
					return direct, nil, pick[2]
				end
			end
		end

		if onlyProtected then
			return nil, "This track is DRM-protected"
		end
		return nil, "SoundCloud did not provide a playable stream"
	end)

	if not ok then return nil, "SoundCloud request failed" end
	return url, err, kind
end

-- ── Download audio bytes ───────────────────────────────────────────────────

local function downloadAudio(url)
	local body = httpGet(url)
	if type(body) == "string" and #body > 0 then
		return body
	end
	return nil
end

-- ── HLS playlist parsing (simple) ──────────────────────────────────────────

local function parseHlsSegments(playlistUrl, playlistBody)
	if type(playlistBody) ~= "string" or not playlistBody:find("#EXTM3U", 1, true) then
		return nil
	end

	-- Handle master playlist (references another playlist)
	local refs = {}
	for line in playlistBody:gmatch("[^\r\n]+") do
		line = line:match("^%s*(.-)%s*$") or line
		if line ~= "" and line:sub(1, 1) ~= "#" then
			refs[#refs + 1] = joinUrl(playlistUrl, line)
		end
	end

	if #refs == 0 then return nil end

	-- If first ref is another playlist, recurse
	if refs[1]:find("%.m3u8") or refs[1]:find("playlist", 1, true) then
		local subBody = httpGet(refs[1])
		if type(subBody) == "string" then
			return parseHlsSegments(refs[1], subBody)
		end
		return nil
	end

	-- These are media segments
	local chunks = {}
	local maxSeg = math.min(#refs, 180)
	for i = 1, maxSeg do
		local part = httpGet(refs[i])
		if type(part) == "string" and #part > 0 then
			chunks[#chunks + 1] = part
		end
	end
	if #chunks == 0 then return nil end

	return table.concat(chunks)
end

-- ── Track download + play ──────────────────────────────────────────────────

local function downloadAndCache(track)
	ensureMusicFolder()

	local streamUrl, err, kind = resolveStreamUrl(track)
	if not streamUrl then
		return nil, err or "Failed to resolve stream URL"
	end

	local body, ext
	if kind == "hls-mp3" or kind == "aac" then
		-- For HLS/AAC, get the playlist body then parse segments
		local playlistBody = httpGet(streamUrl)
		if type(playlistBody) ~= "string" then
			return nil, "Failed to fetch stream playlist"
		end
		body = parseHlsSegments(streamUrl, playlistBody)
		if not body then
			return nil, "Failed to parse HLS segments"
		end
		ext = ".mp3"
	else
		-- Progressive MP3 - direct download
		body = downloadAudio(streamUrl)
		if not body then
			return nil, "Failed to download audio"
		end
		ext = ".mp3"
	end

	if type(body) ~= "string" or #body < 100 then
		return nil, "Downloaded audio is too small or empty"
	end

	-- Save to local file
	local fileName = safeFileName(track.title) .. "_" .. tostring(track.id) .. ext
	local filePath = MUSIC_FOLDER .. "/" .. fileName

	pcall(function()
		writefile(filePath, body)
	end)

	-- Get rbxasset:// URL via getcustomasset
	local assetUrl = getAssetPath(filePath)
	if not assetUrl then
		return nil, "getcustomasset/getsynasset not available in your executor"
	end

	return assetUrl, nil
end

-- ── Playback control ───────────────────────────────────────────────────────

function musicplayer:play(track)
	if type(track) ~= "table" then
		-- Treat as direct asset URL or search query
		local query = tostring(track)
		if query:find("^rbxasset://") or query:find("^rbxassetid://") then
			local sound = Instance.new("Sound")
			sound.SoundId = query
			sound.Volume = volume
			sound.Looped = false
			sound.Parent = SoundService
			sound:Play()
			currentSound = sound
			currentTrack = { title = query, artist = "SoundCloud", url = query }
			isPlaying = true
			for _, cb in ipairs(listeners) do pcall(cb, "play", currentTrack) end
			return true
		else
			-- Search and play first result
			local tracks, err = searchTracks(query, 1)
			if not tracks or #tracks == 0 then
				return nil, err or "No tracks found"
			end
			return self:play(tracks[1])
		end
	end

	-- Stop current sound
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
		currentSound = nil
	end

	-- Download and cache
	local assetUrl, err = downloadAndCache(track)
	if not assetUrl then
		return nil, err or "Failed to prepare track"
	end

	-- Create and play sound
	local sound = Instance.new("Sound")
	sound.Name = "TetraMusic_" .. tostring(track.id or "track")
	sound.SoundId = assetUrl
	sound.Volume = volume
	sound.Looped = false
	sound.Parent = SoundService
	sound:Play()

	currentSound = sound
	currentTrack = track
	isPlaying = true

	sound.Ended:Connect(function()
		isPlaying = false
		for _, cb in ipairs(listeners) do pcall(cb, "ended") end
	end)

	for _, cb in ipairs(listeners) do pcall(cb, "play", track) end
	return true
end

function musicplayer:pause()
	if currentSound then currentSound:Pause() end
	isPlaying = false
end

function musicplayer:resume()
	if currentSound then currentSound:Resume() end
	isPlaying = true
end

function musicplayer:stop()
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
		currentSound = nil
	end
	currentTrack = nil
	isPlaying = false
end

function musicplayer:setVolume(v)
	volume = math.clamp(v or 0.5, 0, 1)
	if currentSound then currentSound.Volume = volume end
end

function musicplayer:getCurrent()
	return currentTrack
end

function musicplayer:isPlaying()
	return isPlaying
end

function musicplayer:onEvent(cb)
	if type(cb) == "function" then table.insert(listeners, cb) end
end

-- ── Search + play convenience ──────────────────────────────────────────────

function musicplayer.searchAndPlay(query, callback)
	if type(callback) ~= "function" then return end
	local tracks, err = searchTracks(query, 5)
	if not tracks or #tracks == 0 then
		callback(nil, err or "No tracks found")
		return
	end
	-- Play the first result
	local ok, playErr = musicplayer:play(tracks[1])
	callback(tracks[1], playErr)
end

-- ── Search only (for UI browsing) ──────────────────────────────────────────

function musicplayer.search(query, callback)
	if type(callback) ~= "function" then return end
	local tracks, err = searchTracks(query, 10)
	callback(tracks or {}, err)
end

return musicplayer
