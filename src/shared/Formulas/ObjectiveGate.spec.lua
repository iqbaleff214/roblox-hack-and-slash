return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ObjectiveGate = require(ReplicatedStorage.Shared.Formulas.ObjectiveGate)

	describe("ObjectiveGate.IsGateOpen", function()
		it("stays closed while a required objective is incomplete", function()
			local objectives = {
				{ id = "CaptureCampA", required = true, complete = true },
				{ id = "CaptureCampB", required = true, complete = false },
			}
			expect(ObjectiveGate.IsGateOpen(objectives)).to.equal(false)
		end)

		it("opens once every required objective is complete", function()
			local objectives = {
				{ id = "CaptureCampA", required = true, complete = true },
				{ id = "CaptureCampB", required = true, complete = true },
			}
			expect(ObjectiveGate.IsGateOpen(objectives)).to.equal(true)
		end)

		it("a completed side objective alone does not open the gate", function()
			local objectives = {
				{ id = "CaptureCampA", required = true, complete = false },
				{ id = "RescueOfficer", required = false, complete = true },
			}
			expect(ObjectiveGate.IsGateOpen(objectives)).to.equal(false)
		end)

		it("an incomplete side objective never blocks the gate", function()
			local objectives = {
				{ id = "CaptureCampA", required = true, complete = true },
				{ id = "RescueOfficer", required = false, complete = false },
			}
			expect(ObjectiveGate.IsGateOpen(objectives)).to.equal(true)
		end)
	end)
end
