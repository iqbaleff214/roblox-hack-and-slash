--[[
	`RandomPool` subset-selection distribution is already genuinely verified
	in `DestructibleBoxPool.spec.lua` (T-708's own pure formula, real `lune`
	execution). This exercises the service's break-once guarantee and
	`TryBreakNear`'s radius check directly, via the test-only
	`_RegisterForTest` hook (mirrors `EnemyRegistry._ClearAll` — `Initialize`
	is a real-map singleton a spec can't reliably re-trigger). Loot-grant-on-
	break needs a live Player as the grant target, covered by Studio Play
	Solo (S-1301).
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)
	local Constants = require(ReplicatedStorage.Shared.Constants)

	describe("DestructibleBoxService", function()
		it("breaks exactly once on a second TryBreak of the same box (Studio-only: needs a live Player)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- loot grant needs a live Player; covered by S-1301
			end

			local DestructibleBoxService = Knit.GetService("DestructibleBoxService")

			local part = Instance.new("Part")
			part:SetAttribute(Constants.Attributes.LootTableId, "DestructibleBox")
			part.Parent = ServerStorage
			DestructibleBoxService:_RegisterForTest(part)

			expect(DestructibleBoxService:TryBreak(part, player)).to.equal(true)
			expect(DestructibleBoxService:TryBreak(part, player)).to.equal(false)

			part:Destroy()
		end)

		it("TryBreakNear only breaks boxes within radius of the given origin", function()
			local DestructibleBoxService = Knit.GetService("DestructibleBoxService")

			local nearPart = Instance.new("Part")
			nearPart.Position = Vector3.new(0, 0, 0)
			nearPart.Parent = ServerStorage
			DestructibleBoxService:_RegisterForTest(nearPart)

			local farPart = Instance.new("Part")
			farPart.Position = Vector3.new(1000, 0, 0)
			farPart.Parent = ServerStorage
			DestructibleBoxService:_RegisterForTest(farPart)

			expect(function()
				DestructibleBoxService:TryBreakNear(nil :: any, { x = 0, y = 0, z = 0 }, 5)
			end).never.to.throw()

			expect(nearPart.Transparency).to.equal(1)
			expect(farPart.Transparency).never.to.equal(1)

			nearPart:Destroy()
			farPart:Destroy()
		end)
	end)
end
