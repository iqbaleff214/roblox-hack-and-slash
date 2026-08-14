--!strict
--[[
	T-409 (client half): drives camera/UI target-lock state only — no server
	authority needed here (the pure selection logic itself lives in
	shared/Formulas/TargetSelect.lua, fully unit-tested there). Reads live
	enemies via the `Enemy` CollectionService tag (Constants.Tags.Enemy),
	populated at runtime by Phase 7's EnemySpawnService — enemy Models
	replicate to the client the same as anything else in Workspace, so this
	doesn't need a privileged data channel to the server.

	Camera-turning / UI highlighting on top of the selected target id is
	Phase 6/11 territory; this controller only maintains the selection.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local TargetSelect = require(ReplicatedStorage.Shared.Formulas.TargetSelect)

local TargetLockController = Knit.CreateController({ Name = "TargetLockController" })

local currentTargetId: string? = nil

local function getEnemyCandidates(): { TargetSelect.EnemyCandidate }
	local candidates = {}
	for _, model in CollectionService:GetTagged(Constants.Tags.Enemy) do
		if model:IsA("Model") then
			local id = model:GetAttribute(Constants.Attributes.EnemyId)
			local tier = model:GetAttribute(Constants.Attributes.EnemyTier)
			local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
			if typeof(id) == "string" and typeof(tier) == "string" and primaryPart then
				local position = primaryPart.Position
				table.insert(candidates, {
					id = id,
					tier = tier,
					position = { x = position.X, y = position.Y, z = position.Z },
				})
			end
		end
	end
	return candidates
end

function TargetLockController:SwitchTarget()
	local character = Players.LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local playerPosition = { x = rootPart.Position.X, y = rootPart.Position.Y, z = rootPart.Position.Z }
	currentTargetId = TargetSelect.SelectTarget(playerPosition, getEnemyCandidates(), currentTargetId)
end

function TargetLockController:GetCurrentTargetId(): string?
	return currentTargetId
end

function TargetLockController:KnitStart()
	local InputController = Knit.GetController("InputController")
	InputController.TargetSwitch:Connect(function()
		self:SwitchTarget()
	end)
end

return TargetLockController
