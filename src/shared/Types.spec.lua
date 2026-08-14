return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)

	describe("Types.Loadout", function()
		it("accepts a fully-populated loadout", function()
			expect(function()
				Types.Loadout({
					weaponId = "Katana",
					ultimateId = "SkyRendingBlow",
					accessories = { Head = "Kabuto", Body = nil, Arm = nil, Leg = nil },
				})
			end).never.to.throw()
		end)

		it("rejects a loadout missing the accessories field", function()
			expect(function()
				Types.Loadout({
					weaponId = "Katana",
					ultimateId = "SkyRendingBlow",
				})
			end).to.throw()
		end)
	end)

	describe("Types.Profile", function()
		local function validProfile()
			return {
				version = 1,
				Level = 1,
				XP = 0,
				SoftCurrency = 0,
				PremiumCurrency = 0,
				OwnedItems = {},
				Loadout = {},
				LoadoutPresets = {},
				QuestProgress = {},
				BattlePassProgress = {},
				MapStats = {},
				Settings = {},
			}
		end

		it("accepts a default new-player profile", function()
			expect(function()
				Types.Profile(validProfile())
			end).never.to.throw()
		end)

		it("rejects a profile missing XP", function()
			local profile = validProfile()
			profile.XP = nil
			expect(function()
				Types.Profile(profile)
			end).to.throw()
		end)

		it("rejects a profile with a wrong-typed field", function()
			local profile = validProfile()
			profile.Level = "1"
			expect(function()
				Types.Profile(profile)
			end).to.throw()
		end)
	end)

	describe("Types.Item", function()
		local function validItem()
			return {
				id = "Kabuto",
				slot = "Head",
				rarity = "Common",
				statBonus = 0,
				cosmeticOnly = false,
				price = { currency = "SoftCurrency", amount = 100 },
			}
		end

		it("accepts a valid accessory", function()
			expect(function()
				Types.Item(validItem())
			end).never.to.throw()
		end)

		it("rejects an item with an invalid slot", function()
			local item = validItem()
			item.slot = "Chest"
			expect(function()
				Types.Item(item)
			end).to.throw()
		end)
	end)

	describe("Types.EnemyDefinition", function()
		local function validEnemy()
			return {
				id = "Swordsman",
				tier = "FootSoldier",
				hp = 20,
				damage = 5,
				poiseMax = 0,
				behaviorModule = "Swordsman",
				lootTableId = "FootSoldier",
			}
		end

		it("accepts a valid Foot Soldier definition", function()
			expect(function()
				Types.EnemyDefinition(validEnemy())
			end).never.to.throw()
		end)

		it("rejects an enemy with an invalid tier", function()
			local enemy = validEnemy()
			enemy.tier = "Boss"
			expect(function()
				Types.EnemyDefinition(enemy)
			end).to.throw()
		end)
	end)

	describe("Types.MapDefinition", function()
		local function validMap()
			return {
				id = "Okehazama",
				displayName = "Okehazama",
				recommendedLevel = 5,
				mainRewardItemId = "Kabuto",
				waveConfig = {},
				objectiveList = {},
				midBossIds = {},
				finalBossId = "Yoshimoto",
			}
		end

		it("accepts a valid map definition", function()
			expect(function()
				Types.MapDefinition(validMap())
			end).never.to.throw()
		end)

		it("rejects a map missing finalBossId", function()
			local map = validMap()
			map.finalBossId = nil
			expect(function()
				Types.MapDefinition(map)
			end).to.throw()
		end)
	end)

	describe("Types.QuestDefinition", function()
		local function validQuest()
			return {
				id = "DailyClear3Maps",
				cadence = "Daily",
				goalType = "ClearMap",
				targetCount = 3,
				rewards = {},
			}
		end

		it("accepts a valid quest definition", function()
			expect(function()
				Types.QuestDefinition(validQuest())
			end).never.to.throw()
		end)

		it("rejects a quest with an invalid cadence", function()
			local quest = validQuest()
			quest.cadence = "Monthly"
			expect(function()
				Types.QuestDefinition(quest)
			end).to.throw()
		end)
	end)
end
