--[[
	Core geometry is unit-tested standalone in HitboxGeometry.spec.lua (no
	Player/Studio needed). This spec covers the Knit-wrapper integration
	(EnemyRegistry lookup, damage application) and requires a live Player
	with a spawned Character — Studio Play Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Knit = require(ReplicatedStorage.Packages.Knit)
	local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)

	describe("HitboxService", function()
		it("applies damage to an enemy directly in front of the player", function()
			local player = Players:GetPlayers()[1]
			local character = player and player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not player or not rootPart then
				return -- no live player/character in this run context; covered by S-1301
			end

			local totalDamage = 0
			local inFrontPosition = rootPart.Position + rootPart.CFrame.LookVector * 5
			EnemyRegistry.Register({
				id = "HitboxSpecEnemy",
				tier = "FootSoldier",
				poiseMax = 0,
				position = { x = inFrontPosition.X, y = inFrontPosition.Y, z = inFrontPosition.Z },
				takeDamage = function(amount)
					totalDamage += amount
				end,
			})

			local HitboxService = Knit.GetService("HitboxService")
			local hitIds = HitboxService:ResolveAndApplyHit(player, "Arc", 25, 0)

			expect(#hitIds).to.equal(1)
			expect(totalDamage).to.equal(25)

			EnemyRegistry.Unregister("HitboxSpecEnemy")
		end)
	end)
end
