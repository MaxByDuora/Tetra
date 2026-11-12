return function(env)
    local _tetra = env._tetra
    local kit = env.kit

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local enabled = false
    local entries = {}
    local conn = nil

    local function createESP(player)
        if player == LocalPlayer then return end
        local entry = { highlight = nil, label = nil, charConn = nil, leaveConn = nil }

        local function apply(char)
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            local head = char:FindFirstChild("Head") or root
            if not root then return end

            if not entry.highlight then
                entry.highlight = Instance.new("Highlight")
                entry.highlight.Name = "TetraESP_" .. player.UserId
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillColor = kit.C.accent
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.FillTransparency = 0.7
                hl.OutlineTransparency = 0.2
                hl.Parent = game:GetService("CoreGui")
            end
            highlight.Adorn e = char

            if not entry.label then
                local bb = Instance.new("BillboardGui")
                bb.Name = "TetraESPLabel_" .. player.UserId
                bb.AlwaysOnTop = true
                bb.Size = UDim2.fromOffset(200, 40)
                bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
                bb.Adorn e = head
                bb.Parent = game:GetService("CoreGui")
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.fromScale(1, 1)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 12
                lbl.TextColor3 = kit.C.text
                lbl.Text = player.DisplayName
                lbl.Parent = bb
                entry.label = bb
            end
            entry.label.Adornee = head

            entry.label.Text = player.DisplayName .. "\n" .. tostring(math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude or 0)) .. "m")
        end

        entry.charConn = player.CharacterAdded:Connect(function(c) apply(c) end)
        entry.leaveConn = Players.PlayerRemoving:Connect(function(p)
            if p == player then
                if entry.highlight then entry.highlight:Destroy() end
                if entry.label then entry.label:Destroy() end
                if entry.charConn then entry.charConn:Disconnect() end
                if entry.leaveConn then entry.leaveConn:Disconnect() end
                entries[player] = nil
            end
        end)
        apply(player.Character)
        entries[player] = entry
        return entry
    end

    local function refresh()
        for _, p in ipairs(Players:GetPlayers()) do
            if not entries[p] then createESP(p) end
        end
    end

    return {
        enable = function()
            enabled = true
            refresh()
            conn = RunService.Heartbeat:Connect(function()
                if not enabled then return end
                refresh()
                for p, entry in pairs(entries) do
                    if p.Character and entry.label then
                        local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
                        if root and entry.highlight then
                            entry.highlight.Adornee = p.Character
                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                                entry.label.Text = p.DisplayName .. "\n" .. dist .. "m"
                            end
                        end
                    end
                end
            end)
            _tetra:notify("ESP", "Enabled", 3)
        end,
        disable = function()
            enabled = false
            if conn then conn:Disconnect(); conn = nil end
            for p, entry in pairs(entries) do
                if entry.highlight then entry.highlight:Destroy() end
                if entry.label then entry.label:Destroy() end
                if entry.charConn then entry.charConn:Disconnect() end
                if entry.leaveConn then entry.leaveConn:Disconnect() end
            end
            entries = {}
            _tetra:notify("ESP", "Disabled", 3)
        end,
        toggle = function()
            if enabled then entries.disable() else entries.enable() end
        end,
        isEnabled = function() return enabled end
    }
end
