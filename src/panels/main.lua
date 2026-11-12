--[[
    Tetra Panel: Main
    Main floating panel
]]

local env = _G.TetraEnv or getfenv()
local WindUI = env.WindUI

local MainPanel = {}

function MainPanel:Create(window, environment)
    self.panel = window:AddPanel({
        Title = "Tetra Panel",
        Size = UDim2.new(0, 300, 0, 400),
        Transparent = false,
        Theme = "Dark",
    })

    self.panel:AddSection("Quick Actions")

    self.panel:AddButton({
        Title = "Refresh",
        Description = "Refresh all systems",
        Style = "Button",
        Callback = function()
            env.notify("Tetra", "Refreshed!", 3)
        end,
    })
end

return MainPanel