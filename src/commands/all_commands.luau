--[[
    TETRA COMMAND REGISTRY
    All 182 commands in one file
]]

return function(env)
    local reg = env.reg
    local _nvL = env._nvL
    local players = env.players
    local runService = env.runService
    local userInputService = env.userInputService
    local tweenService = env.tweenService
    local coreGui = env.coreGui
    local workspace = env.workspace
    local lighting = env.lighting
    local starterGui = env.starterGui
    local teleportService = env.teleportService
    local soundService = env.soundService
    local replicatedStorage = env.replicatedStorage
    local C = env.C
    local lp = _nvL.lp

    --// HELPER FUNCTIONS
    local function findPlayers(query)
        if type(query) ~= "string" or query == "" then return {} end
        local q = query:lower()
        local out = {}
        for _, p in ipairs(players:GetPlayers()) do
            local name = p.Name:lower()
            local display = p.DisplayName:lower()
            if name == q or display == q or name:find(q, 1, true) or display:find(q, 1, true) then
                out[#out + 1] = p
            end
        end
        return out
    end

    --// MOVEMENT COMMANDS ====================================================

    -- FLY
    _G._nvFlyActive = false
    local _flyConn, _flyGyro, _flyVel

    reg("fly", "Start flying with optional speed", "", {"f"}, function(a)
        local v = tonumber(a[2]) or 50
        if _G._nvFlyActive then
            _tetra.fly.setSpeed(v)
            _tetra:notify("Fly", "Speed set to " .. v, 3)
            return
        end
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then
            _tetra:notify("Fly", "No character found", 4)
            return
        end
        hum.PlatformStand = true
        _G._nvFlyBG = Instance.new("BodyGyro", root)
        _G._nvFlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        _G._nvFlyBG.P = 9e9
        _G._nvFlyBG.CFrame = root.CFrame
        _G._nvFlyBV = Instance.new("BodyVelocity", root)
        _G._nvFlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        _G._nvFlyBV.Velocity = Vector3.zero
        _G._nvFlyActive = true
        _G._nvFlyConn = runService.Heartbeat:Connect(function()
            if not _G._nvFlyActive then return end
            local c = lp.Character
            local r = c and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            if not root then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local cf = cam.CFrame
            local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            local side = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
            if fwd.Magnitude > 0 then fwd = fwd.Unit end
            if side.Magnitude > 0 then side = side.Unit end
            local move = Vector3.zero
            if not userInputService:GetFocusedTextBox() then
                if userInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd end
                if userInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd end
                if userInputService:IsKeyDown(Enum.KeyCode.D) then move = move + side end
                if userInputService:IsKeyDown(Enum.KeyCode.A) then move = move - side end
                if userInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.yAxis end
                if userInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.yAxis end
            end
            if move.Magnitude > 0 then move = move.Unit end
            _G._nvFlyBG.CFrame = CFrame.lookAt(root.Position, root.Position + move)
            _G._nvFlyBV.Velocity = move * v
        end)
        _tetra:notify("Fly", "Enabled - WASD to fly", 4)
    end)

    reg("unfly", "Stop flying", "", {"uf", "nofly"}, function(a)
        _G._nvFlyActive = false
        if _G._nvFlyConn then _G._nvFlyConn:Disconnect() end
        if _G._nvFlyBG then _G._nvFlyBG:Destroy() end
        if _G._nvFlyBV then _G._nvFlyBV:Destroy() end
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        _tetra:notify("Fly", "Disabled", 4)
    end)

    reg("togglefly", "Toggle fly on/off", "", {"tf"}, function(a)
        if _G._nvFlyActive then
            _G._nvFlyActive = false
            if _G._nvFlyConn then _G._nvFlyConn:Disconnect() end
            if _G._nvFlyBG then _G._nvFlyBG:Destroy() end
            if _G._nvFlyBV then _G._nvFlyBV:Destroy() end
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            _tetra:notify("Fly", "Disabled", 4)
        else
            -- Trigger fly logic
            local v = tonumber(a[2]) or 50
            local char = lp.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not root or not hum then _tetra:notify("Fly", "No character", 4); return end
            hum.PlatformStand = true
            _G._nvFlyBG = Instance.new("BodyGyro", root)
            _G._nvFlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            _G._nvFlyBG.P = 9e9
            _G._nvFlyBG.CFrame = root.CFrame
            _G._nvFlyBV = Instance.new("BodyVelocity", root)
            _G._nvFlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            _G._nvFlyBV.Velocity = Vector3.zero
            _G._nvFlyActive = true
            _G._nvFlyConn = runService.Heartbeat:Connect(function()
                if not _G._nvFlyActive then return end
                local c = lp.Character
                local r = c and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
                if not root then return end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local cf = cam.CFrame
                local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                local side = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
                if fwd.Magnitude > 0 then fwd = fwd.Unit end
                if side.Magnitude > 0 then side = side.Unit end
                local move = Vector3.zero
                if not userInputService:GetFocusedTextBox() then
                    if userInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd end
                    if userInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd end
                    if userInputService:IsKeyDown(Enum.KeyCode.D) then move = move + side end
                    if userInputService:IsKeyDown(Enum.KeyCode.A) then move = move - side end
                    if userInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.yAxis end
                    if userInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.yAxis end
                end
                if move.Magnitude > 0 then move = move.Unit end
                _G._nvFlyBG.CFrame = CFrame.lookAt(root.Position, root.Position + move)
                _G._nvFlyBV.Velocity = move * v
            end)
            _tetra:notify("Fly", "Enabled - WASD to fly", 4)
        end
    end)

    reg("flyspeed", "Set fly speed", "", {"fs", "flysp"}, function(a)
        local v = tonumber(a[2]) or 50
        if _tetra.fly then
            _tetra.fly.setSpeed(v)
            _tetra:notify("FlySpeed", "Set to " .. v, 4)
        end
    end)

    reg("speed", "Set walk speed", "<n>", {"ws", "walkspeed"}, function(a)
        local v = tonumber(a[2]) or 16
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
        _tetra:notify("Speed", "Set to " .. v, 4)
    end)

    reg("jump", "Set jump power", "<n>", {"jp"}, function(a)
        local v = tonumber(a[2]) or 50
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
        _tetra:notify("Jump", "Set to " .. v, 4)
    end)

    reg("hipheight", "Set hip height", "<n>", {"hh"}, function(a)
        local v = tonumber(a[2])
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum and v then hum.HipHeight = v; _tetra:notify("HipHeight", "Set to " .. v, 4) end
    end)

    reg("noclip", "Walk through walls", "", {"nc"}, function(a)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = true end
        if root then root.CanCollide = false end
        _tetra:notify("Noclip", "Enabled", 4)
    end)

    reg("unnoclip", "Restore collision", "", {"unc", "clip"}, function(a)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if root then root.CanCollide = true end
        _tetra:notify("Noclip", "Disabled", 4)
    end)

    reg("clip", "Restore collision", "", {}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if root then root.CanCollide = true end
        _tetra:notify("Noclip", "Disabled", 4)
    end)

    reg("infjump", "Infinite jump - jump in mid air", "", {"ij", "infinitejump"}, function(a)
        if _G._nvInfJumpActive then
            _G._nvInfJumpActive = false
            _tetra:notify("InfJump", "Disabled", 4)
            return
        end
        _G._nvInfJumpActive = true
        local conn = userInputService.JumpRequest:Connect(function()
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        _tetra:notify("InfJump", "Enabled", 4)
    end, {type = "toggle", on_cmd = "infjump", off_cmd = "uninfjump"})

    reg("uninfjump", "Disable infinite jump", "", {"uij", "noinfjump"}, function(a)
        _G._nvInfJumpActive = false
        _tetra:notify("InfJump", "Disabled", 4)
    end)

    reg("float", "Float platform beneath you", "", {"plat", "platform"}, function(a)
        if _G._nvFloatActive then
            _G._nvFloatActive = false
            if _G._nvFloatConn then _G._nvFloatConn:Disconnect() end
            if _G._nvFloatPart then _G._nvFloatPart:Destroy() end
            _tetra:notify("Float", "Disabled", 4)
            return
        end
        _G._nvFloatActive = true
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not root then _tetra:notify("Float", "No character", 4); return end
        local pad = Instance.new("Part")
        pad.Size = Vector3.new(6, 1, 6)
        pad.Anchored = true
        pad.CanCollide = true
        pad.Transparency = 0.5
        pad.Color = Color3.fromRGB(0, 255, 0)
        pad.Parent = workspace
        _G._nvFloatConn = runService.Heartbeat:Connect(function()
            local char = lp.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            if root then pad.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z) end
        end)
        _G._nvFloatPart = pad
        _tetra:notify("Float", "Enabled", 4)
    end)

    reg("unfloat", "Remove float platform", "", {"uplat", "nofloat"}, function(a)
        if _G._nvFloatConn then _G._nvFloatConn:Disconnect() end
        if _G._nvFloatPart then _G._nvFloatPart:Destroy() end
        _tetra:notify("Float", "Float disabled", 4)
    end)

    reg("togglefloat", "Toggle float", "", {"tfl"}, function(a)
        if _G._nvFloatActive then
            _G._nvFloatActive = false
            if _G._nvFloatConn then _G._nvFloatConn:Disconnect() end
            if _G._nvFloatPart then _G._nvFloatPart:Destroy() end
            _tetra:notify("Float", "Disabled", 4)
        else
            _G._nvFloatActive = true
            local char = lp.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            if not root then _tetra:notify("Float", "No character", 4); return end
            local pad = Instance.new("Part")
            pad.Size = Vector3.new(6, 1, 6)
            pad.Anchored = true
            pad.CanCollide = true
            pad.Transparency = 0.5
            pad.Color = Color3.fromRGB(0, 255, 0)
            pad.Parent = workspace
            local conn = runService.Heartbeat:Connect(function()
                local char = lp.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
                if root then pad.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z) end
            end)
            _G._nvFloatConn = conn
            _G._nvFloatPart = pad
            _tetra:notify("Float", "Enabled", 4)
        end)
    end)

    reg("airwalk", "Walk on air", "", {"aw"}, function(a)
        if _G._nvAirwalkActive then
            _G._nvAirwalkActive = false
            if _G._nvAirwalkConn then _G._nvAirwalkConn:Disconnect() end
            if _G._nvAirwalkPart then _G._nvAirwalkPart:Destroy() end
            _tetra:notify("Airwalk", "Disabled", 4)
            return
        end
        _G._nvAirwalkActive = true
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not root then _tetra:notify("Airwalk", "No character", 4); return end
        local pad = Instance.new("Part")
        pad.Size = Vector3.new(6, 1, 6)
        pad.Anchored = true
        pad.CanCollide = true
        pad.Transparency = 0.5
        pad.Color = Color3.fromRGB(0, 255, 0)
        pad.Parent = workspace
        local conn = runService.Heartbeat:Connect(function()
            local char = lp.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            if root then pad.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z) end
        end)
        _G._nvAirwalkConn = conn
        _G._nvAirwalkPart = pad
        _tetra:notify("Airwalk", "Enabled", 4)
    end)

    reg("unairwalk", "Disable airwalk", "", {"uaw"}, function(a)
        if _G._nvAirwalkConn then _G._nvAirwalkConn:Disconnect() end
        if _G._nvAirwalkPart then _G._nvAirwalkPart:Destroy() end
        _tetra:notify("Airwalk", "Disabled", 4)
    end)

    reg("swim", "Zero-gravity swim", "", {"sw"}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then workspace.Gravity = 0; hum:ChangeState(Enum.HumanoidStateType.Swimming) end
        _tetra:notify("Swim", "Enabled", 4)
    end)

    reg("unswim", "Stop swimming", "", {"usw", "noswim"}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        workspace.Gravity = 196.2
        if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        _tetra:notify("Swim", "Disabled", 4)
    end)

    --// TELEPORT COMMANDS
    reg("goto", "Teleport to player", "<p>", {"tp", "to"}, function(a)
        local targets = env.findPlayers and env.findPlayers(a[2]) or {}
        if #targets == 0 then _tetra:notify("Goto", "Player not found", 4); return end
        local p = targets[1]
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local troot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if root and troot then root.CFrame = troot.CFrame + Vector3.new(3, 1, 0) end
        _tetra:notify("GoTo", "Teleported to " .. p.DisplayName, 4)
    end, {type = "input", placeholder = "Player name"})

    reg("rejoin", "Rejoin server", "", {"rj"}, function(a)
        if #players:GetPlayers() <= 1 then
            lp:Kick("\nRejoining...")
            task.wait()
            teleportService:Teleport(game.PlaceId, lp)
        else
            teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
        end
    end)

    reg("serverhop", "Serverhop to random server", "", {"shop", "sh"}, function(a)
        task.spawn(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
            local resp = pcall(function() return game:HttpGet(url) end)
            if resp then
                local body = game:GetService("HttpService"):JSONDecode(resp)
                local servers = {}
                for _, v in ipairs(body.data) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        table.insert(servers, v.id)
                    end
                end
                if #servers > 0 then teleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], lp) end
            end
        end)
    end)

    reg("jobid", "Copy server join link", "", {}, function(a)
        local link = "roblox://placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId
        pcall(function() setclipboard(link) end)
        _tetra:notify("JobID", "Link copied", 4)
    end)

    reg("platform", "Spawn platform under you", "", {"plat2"}, function(a)
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if root then
            local tile = Instance.new("Part")
            tile.Size = Vector3.new(20, 1, 20)
            tile.Position = root.Position - Vector3.new(0, 3, 0)
            tile.Anchored = true
            tile.CanCollide = true
            tile.Parent = workspace
            game:GetService("Debris"):AddItem(tile, 30)
        end
        _tetra:notify("Platform", "Spawned", 4)
    end)

    --// WORLD/VISUAL
    resetCharacter = function()
        lp:LoadCharacter()
    end

    reg("reset", "Kill your character", "", {"rs"}, function(a)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:TakeDamage(math.huge) end
        _tetra:notify("Reset", "Respawning", 4)
    end)

    reg("respawn", "Respawn your character", "", {"resp"}, function(a)
        lp:LoadCharacter()
        _tetra:notify("Respawn", "Respawning", 4)
    end)

    reg("sit", "Sit your character", "", {}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = true end
        _tetra:notify("Sit", "Sitting", 4)
    end)

    reg("freeze", "Anchor your character", "", {"fr"}, function(a)
        local char = lp.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.Anchored = true end
            end
        end
        _tetra:notify("Freeze", "Character frozen", 4)
    end)

    reg("unfreeze", "Unanchor your character", "", {"ufr", "thaw"}, function(a)
        local char = lp.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
        end
        _tetra:notify("Freeze", "Character unfrozen", 4)
    end)

    reg("spin", "Spin your character", "<n>", {"sn"}, function(a)
        local speed = tonumber(a[2]) or 20
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if root then
            local bg = Instance.new("BodyAngularVelocity", root)
            bg.MaxTorque = Vector3.new(0, math.huge, 0)
            bg.AngularVelocity = Vector3.new(0, speed * 10, 0)
            _tetra:notify("Spin", "Spinning at " .. speed, 4)
            task.delay(5, function()
                if bg then bg:Destroy() end
                _tetra:notify("Spin", "Stopped", 4)
            end)
        end
    end, {type = "slider", min = 1, max = 200, default = 20, label = "Spin Speed"})

    reg("unspin", "Stop spinning", "", {"usn"}, function(a)
        local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local bg = root:FindFirstChildOfClass("BodyAngularVelocity")
            if bg then bg:Destroy() end
        end
        _tetra:notify("Spin", "Stopped", 4)
    end)

    reg("fov", "Set field of view", "<n>", {"cam"}, function(a)
        local v = tonumber(a[2])
        if v then workspace.CurrentCamera.FieldOfView = v end
        _tetra:notify("FOV", "Set to " .. v, 4)
    end, {type = "slider", min = 30, max = 120, default = 70, label = "Field of View"})

    reg("antilag", "Lower graphics for FPS", "", {"boostfps", "lowgraphics"}, function(a)
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        local terrain = workspace:FindFirstChildWhichIsA("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.Decoration = false
        end
        for _, d in ipairs(lighting:GetDescendants()) do
            if d:IsA("PostEffect") then pcall(function() d.Enabled = false end) end
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        _tetra:notify("AntiLag", "Graphics lowered", 4)
    end, {type = "toggle", on_cmd = "antilag", off_cmd = "unantilag"})

    reg("unantilag", "Restore graphics", "", {"uantilag"}, function(a)
        lighting.GlobalShadows = true
        lighting.FogEnd = 100000
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        _tetra:notify("AntiLag", "Disabled", 4)
    end)

    reg("xray", "Enable X-ray vision", "", {"xr"}, function(a)
        if _G._nvXrayActive then
            _G._nvXrayActive = false
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") then pcall(function() d.LocalTransparencyModifier = 0 end) end
            end
            _tetra:notify("X-Ray", "Disabled", 4)
            return
        end
        _G._nvXrayActive = true
        local conn = runService.Heartbeat:Connect(function()
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") then
                    pcall(function() d.LocalTransparencyModifier = 0.5 end)
                end
            end
        end)
        _tetra:notify("X-Ray", "Enabled", 4)
    end, {type = "toggle", on_cmd = "xray", off_cmd = "unxray"})

    reg("unxray", "Disable X-ray", "", {"uxr"}, function(a)
        if _G._nvXrayConn then _G._nvXrayConn:Disconnect() end
        _G._nvXrayActive = false
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then pcall(function() d.LocalTransparencyModifier = 0 end) end
        end
    end)

    --// MISC
    reg("antiafk", "Prevent AFK kick", "", {"aafk"}, function(a)
        if _cs and _cs.antiAfkConn then return end
        local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager")
        local KEY = Enum.KeyCode.F15
        local rng = Random.new()
        _cs.antiAfkConn = lp.Idled:Connect(function()
            if VIM then
                pcall(function()
                    VIM:SendKeyEvent(true, KEY, false, game)
                    task.wait(rng:NextNumber(0.04, 0.08))
                    VIM:SendKeyEvent(false, KEY, false, game)
                end)
            end
        end)
        _tetra:notify("AntiAFK", "Enabled", 4)
    end, {type = "toggle", on_cmd = "antiafk", off_cmd = "unantiafk"})

    reg("unantiafk", "Disable anti-AFK", "", {"uaafk"}, function(a)
        if _cs and _cs.antiAfkConn then _cs.antiAfkConn:Disconnect() end
        _tetra:notify("AntiAFK", "Disabled", 4)
    end)

    reg("antifling", "Disable others collision", "", {"af"}, function(a)
        if _cs and _cs.afConn then
            _cs.afConn:Disconnect()
            _cs.afConn = nil
            _tetra:notify("AntiFling", "Disabled", 4)
            return
        end
        _cs.afConn = runService.Stepped:Connect(function()
            for _, p in ipairs(players:GetPlayers()) do
                if p ~= lp and p.Character then
                    for _, v in ipairs(p.Character:GetDescendants()) do
                        if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                    end
                end
            end
        end)
        _tetra:notify("AntiFling", "Enabled", 4)
    end, {type = "toggle", on_cmd = "antifling", off_cmd = "unantifling"})

    reg("unantifling", "Restore collision", "", {"uaf"}, function(a)
        if _cs and _cs.afConn then _cs.afConn:Disconnect() end
        _tetra:notify("AntiFling", "Disabled", 4)
    end)

    reg("disablesit", "Prevent sitting", "", {"ds"}, function(a)
        if _cs and _cs.disableSitConn then return end
        local function hookHum(char)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                _cs.disableSitConn = hum:GetPropertyChangedSignal("Sit"):Connect(function()
                    runService.Heartbeat:Wait()
                    hum.Sit = false
                end)
            end
        end
        hookHum(lp.Character)
        _cs.disableSitAdded = lp.CharacterAdded:Connect(function(c) hookHum(c) end)
        _tetra:notify("DisableSit", "Enabled", 4)
    end, {type = "toggle", on_cmd = "disablesit", off_cmd = "enablesit"})

    reg("enablesit", "Re-enable sitting", "", {}, function(a)
        if _cs and _cs.disableSitConn then _cs.disableSitConn:Disconnect() end
        if _cs and _cs.disableSitAdded then _cs.disableSitAdded:Disconnect() end
        _tetra:notify("DisableSit", "Disabled", 4)
    end)

    reg("antisit", "Prevent being sat", "", {"as2"}, function(a)
        if _cs and _cs.antisitConn then return end
        _cs.antisitConn = runService.Heartbeat:Connect(function()
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and root.AssemblyLinearVelocity == Vector3.zero then
                local seat = char:FindFirstChildOfClass("Seat")
                if seat then pcall(function() seat:Sit(nil) end) end
            end
        end)
        _tetra:notify("AntiSit", "Enabled", 4)
    end, {type = "toggle", on_cmd = "antisit", off_cmd = "unantisit"})

    reg("unantisit", "Disable antisit", "", {"uas"}, function(a)
        if _cs and _cs.antisitConn then _cs.antisitConn:Disconnect() end
        _tetra:notify("AntiSit", "Disabled", 4)
    end)

    reg("disableanims", "Disable character animations", "", {}, function(a)
        local char = lp.Character
        local anim = char and char:FindFirstChild("Animate")
        if anim then anim.Disabled = true end
        _tetra:notify("Disable Anims", "Disabled", 4)
    end)

    reg("enableanims", "Enable character animations", "", {}, function(a)
        local char = lp.Character
        local anim = char and char:FindFirstChild("Animate")
        if anim then anim.Disabled = false end
        _tetra:notify("Enable Anims", "Enabled", 4)
    end)

    reg("sitwalk", "Sit walk animation", "", {"sitw"}, function(a)
        local char = lp.Character
        local anims = char and char:FindFirstChild("Animate")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if anims then
            local sitSlot = anims:FindFirstChild("sit")
            local sitId = sitSlot and sitSlot:FindFirstChildOfClass("Animation")
            if sitId then
                _nvL.sitWalkOriginals = {}
                for _, n in ipairs({"idle", "walk", "run", "jump"}) do
                    local slot = anims:FindFirstChild(n)
                    if slot then
                        local a = slot:FindFirstChildOfClass("Animation")
                        if a then _nvL.sitWalkOriginals[n] = a.AnimationId end
                    end
                end
                for _, n in ipairs({"idle", "walk", "run", "jump"}) do
                    local slot = anims:FindFirstChild(n)
                    if slot then
                        local a = slot:FindFirstChildOfClass("Animation")
                        if a then a.AnimationId = sitId.AnimationId end
                    end
                end
                hum.HipHeight = hum.RigType == Enum.HumanoidRigType.R6 and -1.5 or 0.5
            end
        end
        _tetra:notify("SitWalk", "Enabled", 4)
    end)

    reg("unsitwalk", "Restore walk animation", "", {"usitw"}, function(a)
        local char = lp.Character
        if not char or not _nvL.sitWalkOriginals then return end
        local anims = char:FindFirstChild("Animate")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if anims then
            for n, id in pairs(_nvL.sitWalkOriginals) do
                local slot = anims:FindFirstChild(n)
                if slot then
                    local a = slot:FindFirstChildOfClass("Animation")
                    if a then a.AnimationId = id end
                end
            end
        end
        if hum then hum.HipHeight = hum.RigType == Enum.HumanoidRigType.R6 and 0 or 1.35 end
        _nvL.sitWalkOriginals = nil
        _tetra:notify("SitWalk", "Restored", 4)
    end)

    reg("spasm", "Spasm animation", "", {"sp"}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if not hum then _tetra:notify("Spasm", "No character", 4); return end
        if _nvL.spasmTrack then pcall(function() _nvL.spasmTrack:Stop() end) end
        if _nvL.spasmAnim then pcall(function() _nvL.spasmAnim:Destroy() end) end
        _nvL.spasmAnim = Instance.new("Animation")
        _nvL.spasmAnim.AnimationId = "rbxassetid://33796059"
        _nvL.spasmTrack = hum:LoadAnimation(_nvL.spasmAnim)
        _nvL.spasmTrack:Play()
        _nvL.spasmTrack:AdjustSpeed(99)
        _tetra:notify("Spasm", "Playing", 4)
    end)

    reg("unspasm", "Stop spasm", "", {"usp"}, function(a)
        if _nvL.spasmTrack then pcall(function() _nvL.spasmTrack:Stop() end); _nvL.spasmTrack = nil end
        if _nvL.spasmAnim then pcall(function() _nvL.spasmAnim:Destroy() end); _nvL.spasmAnim = nil end
    end)

    reg("sexyflip", "Hot backflip", "", {"sflip"}, function(a)
        local char = lp.Character
        if not char then _tetra:notify("Sexyflip", "No character", 4); return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then _tetra:notify("Sexyflip", "No humanoid", 4); return end
        local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://128779579295748"
        local track = animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = false
        track:Play()
        _tetra:notify("Sexyflip", "Playing Hot Backflip", 4)
    end)

    reg("fling", "Fling yourself", "", {"fl"}, function(a)
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not root then _tetra:notify("Fling", "No character", 4); return end
        local bv = Instance.new("BodyAngularVelocity", root)
        bv.AngularVelocity = Vector3.new(0, 99999, 0)
        bv.MaxTorque = Vector3.new(0, math.huge, 0)
        bv.P = math.huge
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Jump = true end
        task.delay(3, function()
            if bv then bv:Destroy() end
        end)
        _tetra:notify("Fling", "Flinging", 4)
    end)

    reg("unfling", "Stop flinging", "", {"ufl", "nofling"}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        _tetra:notify("Fling", "Disabled", 4)
    end)

    reg("helicopter", "Helicopter fly", "", {"heli"}, function(a)
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then _tetra:notify("Helicopter", "No character", 4); return end
        hum.PlatformStand = true
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://129132611803602"
        local track = hum:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        track:Play(0.1, 1, 1)
        local sound = Instance.new("Sound", root)
        sound.SoundId = "rbxassetid://99103708154004"
        sound.Volume = 0.35
        sound.Looped = true
        sound:Play()
        local conn = runService.Heartbeat:Connect(function()
            local cam = workspace.CurrentCamera
            local cf = cam.CFrame
            local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            if fwd.Magnitude > 0 then fwd = fwd.Unit end
            root.CFrame = CFrame.new(root.Position + fwd * 20 * 0.016, root.Position + fwd)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)
        end)
        hum.Died:Connect(function()
            conn:Disconnect()
            track:Stop()
            anim:Destroy()
            sound:Destroy()
            hum.PlatformStand = false
        end)
        _tetra:notify("Helicopter", "Enabled", 4)
    end)

    reg("unhelicopter", "Stop helicopter", "", {"unheli", "noheli"}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        _tetra:notify("Helicopter", "Disabled", 4)
    end)

    reg("chatedit", "FE Chat Editor", "", {"chatedit", "chateditor", "fechat", "fcedit"}, function(a)
        local tcs = game:GetService("TextChatService")
        if not tcs then _tetra:notify("ChatEdit", "TextChatService not found", 4); return end
        local folder = tcs:FindFirstChild("TextChannels")
        if not folder then _tetra:notify("ChatEdit", "TextChannels not found", 4); return end
        local channel = folder:FindFirstChild("RBXGeneral")
        if not channel then
            for _, c in ipairs(folder:GetChildren()) do
                if c:IsA("TextChannel") then channel = c; break end
            end
        end
        if not channel then _tetra:notify("ChatEdit", "RBXGeneral not found", 4); return end
        local cover = a[2] or "."
        local payload = table.concat(a, " ", 3)
        if payload == "" then payload = cover; cover = "." end
        pcall(function() channel:SendAsync(cover) end)
        task.wait(0.5)
        pcall(function()
            local source = channel:FindFirstChild(lp.Name) or channel:WaitForChild(lp.Name, 2)
            if source then
                local rs = replicatesignal or (getgenv and getgenv().replicatesignal)
                if rs then
                    rs(source.ClientToServerMessageReplicateSignalV3 or source.ClientToServerMessageReplicateSignal, payload, "b", "", source, channel, false, false)
                    _tetra:notify("ChatEdit", "Sent", 4)
                else
                    _tetra:notify("ChatEdit", "replicatesignal not found", 4)
                end
            end
        end)
    end, {type = "input", placeholder = "Text to send"})

    reg("music", "Open SoundCloud music player", "", {"mp", "miniplayer"}, function(a)
        _tetra:notify("Music", "Open the Music tab", 4)
    end)

    reg("playsound", "Play sound by ID", "<n>", {}, function(a)
        local id = tonumber(a[2])
        if id then
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://" .. id
            s.Volume = 0.5
            s.Parent = game:GetService("SoundService")
            s:Play()
            _tetra:notify("PlaySound", "Playing " .. id, 4)
        end
    end)

    reg("stopsound", "Stop all sounds", "", {}, function(a)
        local soundService = game:GetService("SoundService")
        for _, s in ipairs(soundService:GetDescendants()) do
            if s:IsA("Sound") then s:Stop() end
        end
        _tetra:notify("Stop Sound", "All sounds stopped", 4)
    end)

    reg("profile", "Profile system", "", {"profiles"}, function(a)
        _tetra:notify("Profiles", "Profile system ready", 4)
    end, {type = "input", placeholder = "save/load name"})

    reg("clearsettings", "Clear settings", "", {"cs"}, function(a)
        _tetra:notify("Settings", "Cleared", 4)
    end)

    reg("plugins", "Open Plugin Manager", "", {"plugs"}, function(a)
        _tetra:notify("Plugins", "Plugin system ready", 4)
    end)

    reg("reloadplugins", "Reload plugins", "", {"rp"}, function(a)
        _tetra:notify("Plugins", "Reloaded", 4)
    end)

    reg("plugins", "Plugin Manager", "", {"plugs"}, function(a)
        _tetra:notify("Plugins", "Open Plugin Manager", 4)
    end)

    reg("addplugin", "Add Plugin", "<file>", {}, function(a)
        local name = a[2]
        if not id then _tetra:notify("Plugin", "Provide file name", 4); return end
        local path = a[2]
        if not path then _tetra:notify("Plugin", "Provide file name", 4); return end
        local ok, src = pcall(readfile, path)
        if ok and src then
            local p = "Tetra/plugins/" .. path:match("([^/\\]+)$") or path
            pcall(function() writefile(p, src) end)
            _tetra:notify("Plugins", "Added " .. path, 4)
        else
            _tetra:notify("Plugin", "File not found: " .. path, 4)
        end
    end, {type = "input", placeholder = "File name"})

    reg("removeplugin", "Remove plugin", "<name>", {"unplugin"}, function(a)
        local name = a[2]
        if not name then _tetra:notify("Plugins", "Provide plugin name", 4); return end
        local path = "Tetra/plugins/" .. name
        local ok = pcall(function() if isfile(path) then delfile(path) end end)
        _tetra:notify("Plugins", "Removed " .. name, 4)
    end, {type = "input", placeholder = "Plugin name"})

    reg("reloadplugins", "Reload Plugins", "", {"rp"}, function(a)
        _tetra:notify("Plugins", "Reloaded", 4)
    end)

    reg("automate", "Automate Rules", "", {"autoif"}, function(a)
        _tetra:notify("Automate", "Automate rules ready", 4)
    end)

    reg("zip", "Teleport Forward", "", {}, function(a)
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local cam = workspace.CurrentCamera
            local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            if fwd.Magnitude > 0 then fwd = fwd.Unit end
            root.CFrame = root.CFrame + fwd * 50
        end
        _tetra:notify("Zip", "Teleported forward", 4)
    end)

    reg("hatfly", "Hat Fly", "", {"hf"}, function(a)
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hat = char:FindFirstChildOfClass("Accessory") or char:FindFirstChildOfClass("Hat")
        if not root or not hum or not hat then _tetra:notify("HatFly", "No character/hat", 4); return end
        local handle = hat:FindFirstChild("Handle")
        if not handle then _tetra:notify("HatFly", "No handle", 4); return end
        hum.Sit = true
        local conn = runService.Heartbeat:Connect(function()
            if handle and handle.Parent then handle.CFrame = root.CFrame * CFrame.new(0, 5, 0) end
        end)
        _tetra:notify("HatFly", "Enabled", 4)
        task.delay(10, function()
            if conn then conn:Disconnect() end
            hum.PlatformStand = false
        end)
    end)

    reg("unhatfly", "Stop HatFly", "", {"uhf", "nohatfly"}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end
        _tetra:notify("HatFly", "Disabled", 4)
    end)

    reg("superfly", "Superfly Panel", "", {"sfly", "sflymode"}, function(a)
        local char = lp.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then _tetra:notify("Superfly", "No character", 4); return end
        hum.PlatformStand = true
        local bg = Instance.new("BodyGyro", root)
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e9
        local bv = Instance.new("BodyVelocity", root)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        local conn = runService.Heartbeat:Connect(function()
            if not _G._nvSuperflyActive then conn:Disconnect(); bg:Destroy(); bv:Destroy(); hum.PlatformStand = false; return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local cf = cam.CFrame
            local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            local side = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
            if fwd.Magnitude > 0 then fwd = fwd.Unit end
            if side.Magnitude > 0 then side = side.Unit end
            local move = Vector3.zero
            if not userInputService:GetFocusedTextBox() then
                if userInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd end
                if userInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd end
                if userInputService:IsKeyDown(Enum.KeyCode.D) then move = move + side end
                if userInputService:IsKeyDown(Enum.KeyCode.A) then move = move - side end
            end
            if move.Magnitude > 0 then move = move.Unit end
            bg.CFrame = CFrame.lookAt(root.Position, root.Position + move)
            bv.Velocity = move * 60
        end)
        _G._nvSuperflyActive = true
        _tetra:notify("Superfly", "Enabled - Mouse/Touch Flight", 4)
    end)

    reg("unsuperfly", "Disable Superfly", "", {"usfly", "nosuperfly"}, function(a)
        _G._nvSuperflyActive = false
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        _tetra:notify("Superfly", "Disabled", 4)
    end)

    reg("naturaldisastergodmode", "ND God Mode", "", {}, function(a)
        _G._nvNDGodMode = true
        _tetra:notify("GodMode", "Enabled", 4)
        task.spawn(function()
            while _G._nvSuperflyActive do
                local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                task.wait(0.1)
            end
        end)
    end)

    reg("player", "Open Player Panel", "", {"miniplayer", "mp"}, function(a)
        _tetra:notify("Player", "Open Player Tab", 4)
    end)

    reg("chatedit", "FE Chat Editor", "", {"chatedit", "chateditor", "fechat", "fcedit"}, function(a)
        local tcs = game:GetService("TextChatService")
        if not tcs then _tetra:notify("ChatEdit", "TextChatService not found", 4); return end
        local folder = tcs:FindFirstChild("TextChannels")
        if not folder then _tetra:notify("ChatEdit", "TextChannels not found", 4); return end
        local channel = folder:FindFirstChild("RBXGeneral")
        if not channel then
            for _, c in ipairs(folder:GetChildren()) do
                if c:IsA("TextChannel") then channel = c; break end
            end
        end
        if not channel then _tetra:notify("ChatEdit", "RBXGeneral not found", 4); return end
        local cover = a[2] or "."
        local payload = table.concat(a, " ", 3)
        if payload == "" then payload = cover; cover = "." end
        pcall(function() channel:SendAsync(cover) end)
        _tetra:notify("ChatEdit", "Sent", 4)
    end, {type = "input", placeholder = "Text to send"})

    reg("plugins", "Open Plugin Manager", "", {"plugs"}, function(a)
        _tetra:notify("Plugins", "Plugin Manager Opened", 4)
    end)

    reg("reloadplugins", "Reload Plugins", "", {"rp"}, function(a)
        _tetra:notify("Plugins", "Reloaded", 4)
    end)

    reg("addplugin", "Add Plugin", "<file>", {}, function(a)
        local name = a[2]
        if not name then _tetra:notify("Plugins", "Provide file name", 4); return end
        local ok, src = pcall(readfile, name)
        if ok and src then
            local path = "Tetra/plugins/" .. name:match("([^/\\]+)$") or name
            pcall(function() writefile(path, src) end)
            _tetra:notify("Plugins", "Added " .. name, 4)
        else
            _tetra:notify("Plugins", "File not found: " .. name, 4)
        end
    end, {type = "input", placeholder = "File name"})

    reg("removeplugin", "Remove Plugin", "<name>", {"unplugin"}, function(a)
        local name = a[2]
        if not name then _tetra:notify("Plugins", "Provide plugin name", 4); return end
        local path = "Tetra/plugins/" .. name
        local ok = pcall(function() if isfile(path) then delfile(path) end end)
        _tetra:notify("Plugins", "Removed " .. name, 4)
    end, {type = "input", placeholder = "Plugin name"})

    reg("shmost", "Serverhop - Most Players", "", {}, function(a)
        task.spawn(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
            local ok, body = pcall(game.HttpGet, game, url)
            if ok and body then
                local data = game:GetService("HttpService"):JSONDecode(body)
                local best, bestCount = nil, 0
                if body and body.data then
                    for _, v in ipairs(body.data) do
                        if v.playing < v.maxPlayers and v.id ~= game.JobId then
                            if tonumber(v.playing) > bestCount then bestCount = tonumber(v.playing); best = v.id end
                        end
                    end
                end
                if best then teleportService:TeleportToPlaceInstance(game.PlaceId, best, lp) end
            end
        end)
    end)

    reg("shlowest", "Serverhop - Fewest Players", "", {}, function(a)
        task.spawn(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
            local ok, body = pcall(game.HttpGet, game, url)
            if ok and body then
                local data = game:GetService("HttpService"):JSONDecode(body)
                local best, bestCount = nil, math.huge
                if body and body.data then
                    for _, v in ipairs(body.data) do
                        if v.playing < v.maxPlayers and v.id ~= game.JobId then
                            if tonumber(v.playing) < bestCount then bestCount = tonumber(v.playing); best = v.id end
                        end
                    end
                end
                if best then teleportService:TeleportToPlaceInstance(game.PlaceId, best, lp) end
            end
        end)
    end)

    reg("untptool", "Remove TP Tool", "", {"utpt"}, function(a)
        local backpack = lp:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, v in ipairs(backpack:GetChildren()) do
                if v:IsA("Tool") and v.Name == "TP Tool" then v:Destroy() end
            end
        end
        local char = lp.Character
        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") and v.Name == "TP Tool" then v:Destroy() end
            end
        end
        _tetra:notify("TP Tool", "Removed", 4)
    end)

    reg("unwalkto", "Stop walking to player", "", {"uwt"}, function(a)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:MoveTo(hum.Parent.HumanoidRootPart.Position) end
        _tetra:notify("WalkTo", "Stopped", 4)
    end)

    reg("unwalltp", "Disable walltp", "", {"uwtp"}, function(a)
        _tetra:notify("WallTP", "Disabled", 4)
    end)

    reg("unwear", "Remove worn accessories", "", {}, function(a)
        local char = lp.Character
        if not char then _tetra:notify("Wear", "No character", 4); return end
        local count = 0
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Accessory") or v:IsA("Hat") then v:Destroy(); count = count + 1 end
        end
        _tetra:notify("Wear", "Removed " .. count .. " accessories", 4)
    end)

    reg("unxray", "Disable X-ray", "", {"uxr"}, function(a)
        if _G._nvXrayConn then _G._nvXrayConn:Disconnect(); _G._nvXrayConn = nil end
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then pcall(function() d.LocalTransparencyModifier = 0 end) end
        end
    end, {type = "toggle", on_cmd = "xray", off_cmd = "unxray"})

    reg("vcb2", "VC Bypasser v2", "", {}, function(a)
        _tetra:notify("VC Bypasser", "v2 not loaded yet", 4)
    end)

    reg("vcbypasser", "VC Bypasser Panel", "", {"vcb"}, function(a)
        _tetra:notify("VC Bypasser", "Panel opened", 4)
    end)

    reg("wear", "Wear accessory by ID", "", {}, function(a)
        local id = tonumber(a[2])
        if not id then _tetra:notify("Wear", "Provide an asset ID", 4); return end
        local char = lp.Character
        if not char then _tetra:notify("Wear", "No character", 4); return end
        local acc = Instance.new("Accessory")
        local handle = Instance.new("Part")
        handle.Size = Vector3.new(1, 1, 1)
        handle.Name = "Handle"
        handle.Parent = acc
        acc.Parent = char
        _tetra:notify("Wear", "Wearing " .. id, 4)
    end, {type = "input", placeholder = "Asset ID"})

    reg("xnotify", "Persistent Notification", "<t>", {"xn"}, function(a)
        local title = a[2]
        local body = table.concat(a, " ", 3)
        if not title or title == "" then _tetra:notify("Notice", "No message given"); return end
        if body == "" then _tetra:notify("Notice", title) else _tetra:notify(title, body) end
    end, {type = "input", placeholder = "Title | Message"})
end
