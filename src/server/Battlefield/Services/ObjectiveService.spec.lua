--[[
	The gate-open decision itself (all required complete, side objectives
	never gate it) is already genuinely verified in `ObjectiveGate.spec.lua`
	(T-709's own pure formula). This exercises the service's bookkeeping:
	completion is idempotent and fires its signal, via the test-only
	`_InjectObjectiveForTest` hook (mirrors `EnemyRegistry._ClearAll` —
	`Initialize` is a real-map singleton a spec can't reliably re-trigger).
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("ObjectiveService", function()
		it("completes an objective exactly once, firing its signal only on the first call", function()
			local ObjectiveService = Knit.GetService("ObjectiveService")

			local objectiveId = "__TestObjective_" .. tostring(os.clock())
			ObjectiveService:_InjectObjectiveForTest({ id = objectiveId, required = true, complete = false })

			local fireCount = 0
			local connection = ObjectiveService.ObjectiveUpdated:Connect(function(firedId: string)
				if firedId == objectiveId then
					fireCount += 1
				end
			end)

			ObjectiveService:ReportObjectiveComplete(objectiveId)
			ObjectiveService:ReportObjectiveComplete(objectiveId)
			connection:Disconnect()

			expect(fireCount).to.equal(1)
			expect(ObjectiveService:GetObjectives()[objectiveId].complete).to.equal(true)
		end)
	end)
end
