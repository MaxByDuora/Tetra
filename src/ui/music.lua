--[[
    Tetra Music System
    Sound playback panel with WindUI
]]

local env = _G.TetraEnv or getfenv()
local WindUI = env.WindUI
local SoundService = env.SoundService

local MusicSystem = {}
MusicSystem.isOpen = false
MusicSystem.currentTrack = nil
MusicSystem.isPlaying = false
MusicSystem.volume = 0.5
MusicSystem.sound = nil
MusicSystem.panel = nil

function MusicSystem:Init(environment)
    env.musicSystem = self

    self.panel = WindUI:CreateWindow({
        Title = "Tetra Music",
        Folder = "Tetra",
        Size = UDim2.new(0, 360, 0, 500),
        Transparent = false,
        Theme = "Dark",
        HideOnToggle = false,
        Resizable = true,
    })

    self:BuildUI()

    env.notify("Tetra", "Music system initialized", 3)
    return self
end

function MusicSystem:BuildUI()
    local panel = self.panel

    panel:AddSection("Now Playing")

    self.nowPlayingLabel = panel:AddButton({
        Title = "No track playing",
        Description = "Select or add a track to play",
        Style = "Button",
        Callback = function()
            self:PromptTrack()
        end,
    })

    panel:AddSection("Controls")

    self.playBtn = panel:AddButton({
        Title = "Play",
        Description = "Start playback",
        Style = "Button",
        Callback = function()
            self:TogglePlay()
        end,
    })

    self.prevBtn = panel:AddButton({
        Title = "Previous",
        Description = "Previous track",
        Style = "Button",
        Callback = function() self:PreviousTrack() end,
    })

    self.nextBtn = panel:AddButton({
        Title = "Next",
        Description = "Next track",
        Style = "Button",
        Callback = function() self:NextTrack() end,
    })

    panel:AddSection("Volume")

    panel:AddSlider({
        Title = "Volume",
        Description = "Adjust music volume",
        Min = 0,
        Max = 100,
        Default = 50,
        Callback = function(val) self:SetVolume(val / 100) end,
    })

    panel:AddSection("Playlist")

    self.playlistDropdown = panel:AddDropdown({
        Title = "Select Track",
        Description = "Choose from playlist",
        Values = {},
        Default = "",
        Callback = function(selected) self:PlayTrack(selected) end,
    })

    panel:AddButton({
        Title = "Add Track",
        Description = "Add Sound ID or URL",
        Style = "Button",
        Callback = function() self:PromptTrack() end,
    })
end

function MusicSystem:Show()
    if self.panel then
        self.panel.Visible = true
        self.isOpen = true
    end
end

function MusicSystem:Hide()
    if self.panel then
        self.panel.Visible = false
        self.isOpen = false
    end
end

function MusicSystem:Toggle()
    if self.panel then
        self.panel.Visible = not self.panel.Visible
        self.isOpen = self.panel.Visible
    end
end

function MusicSystem:PromptTrack()
    local input = self.panel:Prompt and self.panel:Prompt({
        Title = "Add Track",
        Content = "Enter Sound ID or SoundCloud URL:",
        Default = "",
    })
    if input and input ~= "" then
        self:AddTrack(input, input)
    end
end

function MusicSystem:PlayTrack(trackInput)
    if not trackInput or trackInput == "" then return end

    if self.sound then
        self.sound:Stop()
        self.sound:Destroy()
        self.sound = nil
    end

    local soundId = trackInput
    if string.find(trackInput, "%d+") and not string.find(trackInput, "http") then
        soundId = "rbxassetid://" .. trackInput
    elseif string.find(trackInput, "http") then
        soundId = trackInput
    end

    local sound = Instance.new("Sound")
    sound.Name = "TetraMusic"
    sound.Volume = self.volume
    sound.Looped = false
    sound.SoundId = soundId
    sound.Parent = SoundService

    self.sound = sound
    self.currentTrack = trackInput
    self.isPlaying = true
    sound:Play()

    self.nowPlayingLabel.Title = "Now Playing: " .. trackInput
    env.notify("Tetra", "Playing: " .. trackInput, 4)

    sound.Ended:Connect(function()
        self.isPlaying = false
    end)
end

function MusicSystem:TogglePlay()
    if not self.sound then return end
    if self.isPlaying then
        self.sound:Pause()
        self.isPlaying = false
    else
        self.sound:Resume()
        self.isPlaying = true
    end
end

function MusicSystem:PreviousTrack()
    env.notify("Tetra", "Previous track", 3)
end

function MusicSystem:NextTrack()
    env.notify("Tetra", "Next track", 3)
end

function MusicSystem:SetVolume(vol)
    self.volume = vol
    if self.sound then self.sound.Volume = vol end
end

function MusicSystem:AddTrack(url, name)
    table.insert(self.playlist, {name = name or url, url = url})

    local values = {}
    for _, track in ipairs(self.playlist) do table.insert(values, track.name) end
    if self.playlistDropdown then self.playlistDropdown.Values = values end

    env.notify("Tetra", "Added track: " .. name, 3)
end

return MusicSystem