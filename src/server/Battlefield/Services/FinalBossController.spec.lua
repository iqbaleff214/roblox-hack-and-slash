--[[
	Full gate/spawn/phase/defeat flow needs a real `FinalBossSpawn` +
	`FinalBossArenaGate` placement (S-706, not built yet) plus completing
	every required objective with live players — Studio Play Solo/Team Test
	(S-1301/S-1303), not here. The phase-transition math itself (the part
	T-707's DoD actually cares about — "no flicker near a threshold") is
	already genuinely verified in `BossPhaseFSM.spec.lua`.
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("FinalBossController", function()
		it("does not spawn while the arena gate is closed", function()
			local FinalBossController = Knit.GetService("FinalBossController")
			expect(function()
				FinalBossController:TrySpawn({ finalBossId = "ImagawaYoshimoto" })
			end).never.to.throw()
		end)
	end)
end
