--[[
    Tetra Dynamic Island - UI Panel Module
    Built with WindUI
]]

local env = _G.TetraEnv or getfenv()
local WindUI = env.WindUI

local DynamicIsland = {}
DynamicIsland.panel = nil

function DynamicIsland:Init(window, environment)
    self.window = window
    env.dynamicIsland = self

    local panel = window:AddPanel({
        Title = "Dynamic Island",
        Size = UDim2.new(0, 300, 0, 400),
        Transparent = false,
        Theme = "Dark",
    })

    self.panel = panel

    panel:AddSection("Dynamic Island")

    panel:AddButton({
        Title = "Show Island",
        Description = "Show dynamic island panel",
        Style = "Button",
        Callback = function()
            env.notify("Dynamic Island", "Panel shown", 3)
        end,
    })

    panel:AddButton({
        Title = "Hide Island",
        Description = "Hide dynamic island panel",
        Style = "Button",
        Callback = function()
            env.notify("Dynamic Island", "Panel hidden", 3)
        end,
    })

    return self
end

function DynamicIsland:Show()
    if self.panel then
        self.panel.Visible = true
    end
end

function DynamicIsland:Hide()
    if self.panel then
        self.panel.Visible = false
    end
end

function DynamicIsland:Toggle()
    if self.panel then
        self.panel.Visible = not self.panel.Visible
    end
end

return DynamicIsland