--!strict
--[[
	Pure combo-tree walk (T-403). The server calls this on every attack input
	to determine the next combo node (and thus damage/hitbox, via that
	node's fields in ComboTrees.lua). No side effects — doesn't mutate the
	tree or any player state, just returns where `currentNodeId` leads for
	a given `input`.
]]

local ComboTrees = require(script.Parent.Parent.Data.ComboTrees)

local ComboResolver = {}

function ComboResolver.Resolve(currentNodeId: string, comboTreeId: string, input: "Light" | "Heavy"): string
	local tree = ComboTrees[comboTreeId]
	assert(tree, "ComboResolver: unknown comboTreeId " .. tostring(comboTreeId))

	local node = tree.nodes[currentNodeId]
	if not node then
		-- Stale/unknown node reference - reset to neutral.
		return tree.rootNodeId
	end

	local nextNodeId = if input == "Light" then node.light else node.heavy
	if not nextNodeId then
		-- No branch for this input at a finisher/dead-end - reset to neutral.
		return tree.rootNodeId
	end

	return nextNodeId
end

return ComboResolver
