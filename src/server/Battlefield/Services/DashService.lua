--!strict
--[[
	T-405: validates a dash request through CombatService's shared state
	machine, grants an i-frame window (CombatService:SetInvulnerable — the
	actual "is this damage voided" check lives there, since that's the
	single source of truth for a player's combat state; Phase 7's
	enemy-attacks-player code will call `CombatService:IsInvulnerable`
	before applying damage once it exists), and moves the character.

	Movement uses a LinearVelocity constraint (respects collision, so a dash
	won't clip through walls) rather than an instant CFrame offset.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local RateLimiter = require(ReplicatedStorage.Shared.Formulas.RateLimiter)

local DashService = Knit.CreateService({
	Name = "DashService",
	Client = {},
})

local CombatService
local dashTimestamps: { [Player]: { number } } = {}

local function moveCharacterForward(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local attachment = rootPart:FindFirstChild("DashAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "DashAttachment"
		attachment.Parent = rootPart
	end

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "DashVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = rootPart.CFrame.LookVector * Constants.Combat.DashSpeed
	linearVelocity.Parent = rootPart

	task.delay(Constants.Combat.DashIFrameSeconds, function()
		linearVelocity:Destroy()
	end)
end

function DashService:HandleDashRequest(player: Player): boolean
	local timestamps = dashTimestamps[player]
	if not timestamps then
		timestamps = {}
		dashTimestamps[player] = timestamps
	end
	if not RateLimiter.TryConsume(timestamps, Constants.Combat.RateLimitMaxPerSecond, Constants.Combat.RateLimitWindowSeconds, os.clock()) then
		return false
	end

	if not CombatService:TryTransition(player, "Dash") then
		return false
	end

	CombatService:SetInvulnerable(player, Constants.Combat.DashIFrameSeconds)
	moveCharacterForward(player)
	return true
end

function DashService.Client:RequestDash(player: Player): boolean
	return self.Server:HandleDashRequest(player)
end

function DashService:KnitInit()
	CombatService = Knit.GetService("CombatService")

	game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
		dashTimestamps[player] = nil
	end)
end

return DashService
