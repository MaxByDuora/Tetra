--[[
    Tetra Feature: Fly
]]

local env = _G.TetraEnv or getfenv()
local Players = env.Players
local lp = env.lp
local RunService = env.RunService

local Fly = {}
Fly.enabled = false
Fly.connection = nil

function Fly:Toggle()
    self.enabled = not self.enabled

    if self.enabled then
        self.connection = RunService.Heartbeat:Connect(function()
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(0, 50, 0)
            end
        end)
        env.notify("Fly", "ON", 3)
    else
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        env.notify("Fly", "OFF", 3)
    end
end

return Fly