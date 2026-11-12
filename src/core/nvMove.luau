return function(env)
    local _nvL = env._nvL
    local players = env.players
    local runService = env.runService
    local userInputService = env.userInputService
    local coreGui = env.coreGui
    local workspace = env.workspace
    local lp = _nvL.lp

    local nvMove = {}
    local noclipConn = nil

    function nvMove.setNoclip(mode, enabled)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if enabled then
            if hum then hum.PlatformStand = true end
            if root then root.CanCollide = false end
        else
            if hum then hum.PlatformStand = false end
            if root then root.CanCollide = true end
        end
    end

    _G._nvMove = nvMove
    return nvMove
end
