--[[
	Tetra Core — HTTP Layer
	All external connections stubbed EXCEPT SoundCloud music
]]

local HttpService = game:GetService("HttpService")

local http = {}

-- SoundCloud is the only allowed external source
local ALLOWED_HOSTS = {
	"soundcloud.com",
	"sndcdn.com",
	"api.soundcloud.com",
}

local function isAllowed(url)
	if type(url) ~= "string" then return false end
	local low = url:lower()
	for _, host in ipairs(ALLOWED_HOSTS) do
		if low:find(host, 1, true) then return true end
	end
	return false
end

function http.get(url, opts)
	opts = opts or {}
	if not isAllowed(url) then
		return nil, "blocked: external connection not allowed (Tetra)"
	end
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if ok then return res end
	return nil, tostring(res)
end

function http.post(url, body, opts)
	opts = opts or {}
	if not isAllowed(url) then
		return nil, "blocked: external connection not allowed (Tetra)"
	end
	local ok, res = pcall(function()
		return game:HttpPost(url, body)
	end)
	if ok then return res end
	return nil, tostring(res)
end

function http.jsonGet(url, opts)
	local body, err = http.get(url, opts)
	if not body then return nil, err end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
	if ok then return data end
	return nil, "json decode failed"
end

return http
