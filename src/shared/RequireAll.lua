--!strict
--[[
	Requires every ModuleScript directly under `container`. Used by each place's
	Knit bootstrap (server + client) so dropping a new Service/Controller module
	into its folder is picked up automatically — no edits to the bootstrap needed.
]]

local function requireAll(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("ModuleScript") then
			require(child)
		end
	end
end

return requireAll
