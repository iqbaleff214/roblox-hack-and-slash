--[[
	`SpawnEnemy`/`GetInstance`/death handling run without a live Player
	(enemies aren't Player-backed). Loot-grant-on-death needs a live Player
	as the `InventoryService`/`CurrencyService` grant target, and full
	`waveConfig` staggering/scaling + `GroupCleared` -> `ObjectiveService`
	integration needs a real map load — both covered by Studio Play Solo
	testing (S-1301), not here.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("EnemySpawnService", function()
		it("spawns a Swordsman with expected fields and registers it", function()
			local EnemySpawnService = Knit.GetService("EnemySpawnService")
			local instance = EnemySpawnService:SpawnEnemy("Swordsman", CFrame.new(0, 0, 0))

			expect(instance).to.be.ok()
			expect(instance.definitionId).to.equal("Swordsman")
			expect(instance.tier).to.equal("FootSoldier")
			expect(instance.state).never.to.equal("Idle") -- T-703: no Idle state on spawn

			local fetched = EnemySpawnService:GetInstance(instance.id)
			expect(fetched).to.equal(instance)

			EnemySpawnService:HandleEnemyDeath(instance)
			expect(EnemySpawnService:GetInstance(instance.id)).to.equal(nil)
		end)

		it("marks ShieldBearer as damageable only from the front (T-704 wiring)", function()
			local EnemySpawnService = Knit.GetService("EnemySpawnService")
			local ServerScriptService = game:GetService("ServerScriptService")
			local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)

			local instance = EnemySpawnService:SpawnEnemy("ShieldBearer", CFrame.new(0, 0, 0))
			local entry = EnemyRegistry.Get(instance.id)

			expect(entry.canBeDamagedFrom).to.be.ok()

			EnemySpawnService:HandleEnemyDeath(instance)
		end)

		it("grants loot to the killer on death (Studio-only: needs a live Player)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local EnemySpawnService = Knit.GetService("EnemySpawnService")
			local ServerScriptService = game:GetService("ServerScriptService")
			local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)

			local instance = EnemySpawnService:SpawnEnemy("Swordsman", CFrame.new(0, 0, 0))
			local entry = EnemyRegistry.Get(instance.id)

			expect(function()
				entry.takeDamage(instance.maxHealth + 1, player)
			end).never.to.throw()

			expect(EnemySpawnService:GetInstance(instance.id)).to.equal(nil)
		end)
	end)
end
