--!strict
--[[
	Thin Roblox-API movement/targeting glue shared by every enemy behavior
	module (T-704/705). No distinguishing algorithmic content of its own —
	basic vector subtraction and CFrame construction — so unlike
	HitboxGeometry/TargetSelect this isn't split into a separately-tested
	pure module; the geometry patterns it uses are already covered there.
]]

local Players = game:GetService("Players")

local EnemyMovement = {}

function EnemyMovement.FindNearestPlayer(position: Vector3): Player?
	local nearest: Player? = nil
	local nearestDistance = math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			local distance = (rootPart.Position - position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearest = player
			end
		end
	end
	return nearest
end

-- Used by Bomber's AoE detonation (GDD §7.1: "detonates (AoE)").
function EnemyMovement.GetPlayersInRadius(position: Vector3, radius: number): { Player }
	local playersInRadius = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart and (rootPart.Position - position).Magnitude <= radius then
			table.insert(playersInRadius, player)
		end
	end
	return playersInRadius
end

function EnemyMovement.MoveToward(rootPart: BasePart, targetPosition: Vector3, speed: number, dt: number)
	local currentPosition = rootPart.Position
	local offset = targetPosition - currentPosition
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	if flatOffset.Magnitude < 0.1 then
		return
	end
	local direction = flatOffset.Unit
	local newPosition = currentPosition + direction * speed * dt
	rootPart.CFrame = CFrame.new(newPosition, newPosition + direction)
end

function EnemyMovement.MoveAway(rootPart: BasePart, threatPosition: Vector3, speed: number, dt: number)
	local currentPosition = rootPart.Position
	local offset = currentPosition - threatPosition
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	if flatOffset.Magnitude < 0.1 then
		flatOffset = Vector3.new(1, 0, 0) -- arbitrary direction if exactly on top of the threat
	end
	local direction = flatOffset.Unit
	local newPosition = currentPosition + direction * speed * dt
	rootPart.CFrame = CFrame.new(newPosition, newPosition + direction * -1)
end

function EnemyMovement.ToPlainPosition(position: Vector3): { x: number, y: number, z: number }
	return { x = position.X, y = position.Y, z = position.Z }
end

return EnemyMovement
