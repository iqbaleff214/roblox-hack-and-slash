--!strict
--[[
	Connective tissue between T-401's local input intents and the
	server-side combat services (T-402/405/406/407) — not itself a separate
	task id, but necessary for the phase to actually function: T-401's
	intents have to go somewhere, and T-402 through T-407 all expose their
	request methods under `.Client`, meaning something on the client has to
	call them. Deliberately thin: no local prediction/animation here, every
	request just goes straight to the server, which is the sole authority
	on whether it actually happens (T-404's DoD).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CombatController = Knit.CreateController({ Name = "CombatController" })

function CombatController:KnitStart()
	local InputController = Knit.GetController("InputController")
	local CombatService = Knit.GetService("CombatService")
	local DashService = Knit.GetService("DashService")
	local SpecialAttackService = Knit.GetService("SpecialAttackService")
	local UltimateGaugeService = Knit.GetService("UltimateGaugeService")

	InputController.LightAttack:Connect(function()
		CombatService:RequestAttack("Light")
	end)

	InputController.HeavyAttack:Connect(function()
		CombatService:RequestAttack("Heavy")
	end)

	InputController.Special:Connect(function()
		SpecialAttackService:RequestSpecial()
	end)

	InputController.Dash:Connect(function()
		DashService:RequestDash()
	end)

	InputController.Ultimate:Connect(function()
		UltimateGaugeService:RequestUltimate()
	end)
end

return CombatController
