--!strict
--[[
	Daily/weekly quest templates (GDD §8.3). An array of `Types.QuestDefinition`
	records. `rewards` is a plain currency/XP grant table, consumed by
	QuestService (T-904) the same way MapClearRewardService (T-903) grants
	its bundles.
]]

local Constants = require(script.Parent.Parent.Constants)

local Soft = Constants.Currency.Soft

local QuestDefinitions = {
	{
		id = "DailyClear3Maps",
		cadence = "Daily",
		goalType = "ClearMap",
		targetCount = 3,
		rewards = { { currency = Soft, amount = 200 } },
	},
	{
		id = "DailyDefeat20FootSoldiers",
		cadence = "Daily",
		goalType = "DefeatEnemyTier",
		targetCount = 20,
		rewards = { { currency = Soft, amount = 100 } },
	},
	{
		id = "DailyDefeat5Commanders",
		cadence = "Daily",
		goalType = "DefeatEnemyTier",
		targetCount = 5,
		rewards = { { currency = Soft, amount = 150 } },
	},
	{
		id = "WeeklyClear10Maps",
		cadence = "Weekly",
		goalType = "ClearMap",
		targetCount = 10,
		rewards = { { currency = Soft, amount = 1000 } },
	},
	{
		id = "WeeklyDefeat3MidBosses",
		cadence = "Weekly",
		goalType = "DefeatEnemyTier",
		targetCount = 3,
		rewards = { { currency = Soft, amount = 600 } },
	},
}

return QuestDefinitions
