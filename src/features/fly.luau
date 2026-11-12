return function(env)
    local _tetra = env._tetra
    local kit = env.kit
    local configs = env.configs
    local windui = env.windui

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = env.userInputService
    local LocalPlayer = Players.LocalPlayer

    local flying = false
    local flyConn = nil
    local flySpeed = configs and configs:read("flySpeed", 50) or 50
    local bg, bv

    local function startFly()
        if flying then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        bg = Instance.new("BodyGyro", root)
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e9
        bg.CFrame = root.CFrame
        bv = Instance.new("BodyVelocity", root)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero

        flying = true
        _tetra:notify("Fly", "Enabled", 3)

        flyConn = RunService.Heartbeat:Connect(function()
            if not flying then return end
            local char2 = LocalPlayer.Character
            local root2 = char2 and (char2:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            if not root2 then return end
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
            bg.CFrame = CFrame.lookAt(root2.Position, root2.Position + move)
            bv.Velocity = move * flySpeed
        end)
    end

    local function stopFly()
        if not flying then return end
        flying = false
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if bg then bg:Destroy(); bg = nil end
        if bv then bv:Destroy(); bv = nil end
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
        _tetra:notify("Fly", "Disabled", 3)
    end

    return {
        enable = startFly,
        disable = stopFly,
        toggle = function() if flying then stopFly() else startFly() end end,
        setSpeed = function(v) flySpeed = v end,
        isFlying = function() return flying end
    }
end
