return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)

	afterEach(function()
		EnemyRegistry._ClearAll()
	end)

	describe("EnemyRegistry", function()
		it("registers and retrieves an entry", function()
			local calls = 0
			EnemyRegistry.Register({
				id = "Enemy1",
				tier = "FootSoldier",
				poiseMax = 0,
				position = { x = 1, y = 2, z = 3 },
				takeDamage = function()
					calls += 1
				end,
			})

			local entry = EnemyRegistry.Get("Enemy1")
			expect(entry).never.to.equal(nil)
			expect((entry :: any).position.x).to.equal(1)

			(entry :: any).takeDamage(10)
			expect(calls).to.equal(1)
		end)

		it("GetAll returns every registered entry", function()
			EnemyRegistry.Register({ id = "A", tier = "FootSoldier", poiseMax = 0, position = { x = 0, y = 0, z = 0 }, takeDamage = function() end })
			EnemyRegistry.Register({ id = "B", tier = "Commander", poiseMax = 50, position = { x = 0, y = 0, z = 0 }, takeDamage = function() end })

			expect(#EnemyRegistry.GetAll()).to.equal(2)
		end)

		it("unregister removes the entry", function()
			EnemyRegistry.Register({ id = "A", tier = "FootSoldier", poiseMax = 0, position = { x = 0, y = 0, z = 0 }, takeDamage = function() end })
			EnemyRegistry.Unregister("A")
			expect(EnemyRegistry.Get("A")).to.equal(nil)
		end)

		it("Get returns nil for an unknown id", function()
			expect(EnemyRegistry.Get("DoesNotExist")).to.equal(nil)
		end)
	end)
end
