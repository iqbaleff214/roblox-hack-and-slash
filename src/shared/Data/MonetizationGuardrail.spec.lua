--[[
	T-1004: codifies GDD §9.5 as a test, not just policy — "**the most
	important test in the backlog**" per the task's own flag. Wired into the
	same TestEZ suite T-1301 runs, so it fails the build the instant a
	future catalog entry accidentally ships stat-affecting and
	premium-currency-exclusive (pay-to-win).

	`ItemDefinitions` has the real `cosmeticOnly`/`statBonus` fields this
	guardrail's literal DoD formula names:
		not (premiumExclusive and statBonus ~= 0) or cosmeticOnly == true
	`WeaponDefinitions`/`UltimateDefinitions` have neither field — every
	entry in those two catalogs *is* inherently stat-affecting (a weapon's
	`baseDamage`/an ultimate's `damage` isn't a bonus on top of some
	cosmetic baseline, it's the whole item), so there's no possible
	cosmetic-only weapon/ultimate. The guardrail's principle still applies
	to them, just simplified to its only possible form: neither catalog may
	ever price an entry in PremiumCurrency at all — GDD §9.1 only lists
	"weapon/ultimate unlock skips" (grind-skip convenience) for Robux, never
	the catalog price itself, so this isn't a new rule, just this test
	covering it too.
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Constants = require(ReplicatedStorage.Shared.Constants)
	local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
	local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
	local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

	local Premium = Constants.Currency.Premium

	describe("Monetization guardrail (T-1004, GDD §9.5)", function()
		describe("ItemDefinitions (accessories)", function()
			for _, item in ItemDefinitions do
				it(("%s: not premium-exclusive stat power unless cosmeticOnly"):format(item.id), function()
					local premiumExclusive = item.price.currency == Premium
					local statAffecting = item.statBonus ~= 0
					local violatesGuardrail = premiumExclusive and statAffecting and not item.cosmeticOnly
					expect(violatesGuardrail).to.equal(false)
				end)
			end
		end)

		describe("WeaponDefinitions (inherently stat-affecting, no cosmetic-only form)", function()
			for _, weapon in WeaponDefinitions do
				it(("%s: never premium-currency-priced"):format(weapon.id), function()
					expect(weapon.price.currency).never.to.equal(Premium)
				end)
			end
		end)

		describe("UltimateDefinitions (inherently stat-affecting, no cosmetic-only form)", function()
			for _, ultimate in UltimateDefinitions do
				it(("%s: never premium-currency-priced"):format(ultimate.id), function()
					expect(ultimate.price.currency).never.to.equal(Premium)
				end)
			end
		end)
	end)
end
