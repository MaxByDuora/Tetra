--[[
	Tetra Island — Notifications
	Toast-style notification system via WindUI
]]

return function(env)
	local _tetra = env._tetra

	local notifications = {}

	function notifications:notify(title, text, duration)
		if _tetra and _tetra.WindUI then
			_tetra.WindUI:Notify({
				Title = title or "Tetra",
				Text = text or "",
				Duration = duration or 5,
			})
		end
	end

	return notifications
end
