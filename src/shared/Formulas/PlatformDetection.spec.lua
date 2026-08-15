return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PlatformDetection = require(ReplicatedStorage.Shared.Formulas.PlatformDetection)

	local DESKTOP_VIEWPORT = { viewportWidth = 1920, viewportHeight = 1080 }
	local PHONE_VIEWPORT = { viewportWidth = 375, viewportHeight = 667 }
	local TABLET_VIEWPORT = { viewportWidth = 1024, viewportHeight = 1366 }

	local function detect(lastInputTypeName: string, isTenFootInterface: boolean, viewport: { viewportWidth: number, viewportHeight: number })
		return PlatformDetection.DetectPlatform({
			lastInputTypeName = lastInputTypeName,
			isTenFootInterface = isTenFootInterface,
			viewportWidth = viewport.viewportWidth,
			viewportHeight = viewport.viewportHeight,
		})
	end

	describe("PlatformDetection.DetectPlatform", function()
		it("classifies keyboard/mouse input types as Desktop", function()
			for _, inputType in { "Keyboard", "MouseButton1", "MouseButton2", "MouseMovement", "MouseWheel" } do
				expect(detect(inputType, false, DESKTOP_VIEWPORT)).to.equal("Desktop")
			end
		end)

		it("classifies any Gamepad* input type as Console", function()
			expect(detect("Gamepad1", false, DESKTOP_VIEWPORT)).to.equal("Console")
			expect(detect("Gamepad4", false, DESKTOP_VIEWPORT)).to.equal("Console")
		end)

		it("isTenFootInterface always wins as Console, even mid-keyboard-session", function()
			expect(detect("Keyboard", true, DESKTOP_VIEWPORT)).to.equal("Console")
		end)

		it("classifies Touch on a small viewport as Mobile, on a large one as Tablet", function()
			expect(detect("Touch", false, PHONE_VIEWPORT)).to.equal("Mobile")
			expect(detect("Touch", false, TABLET_VIEWPORT)).to.equal("Tablet")
		end)

		it("produces the expected sequence across a scripted input-type-changed event stream", function()
			local stream = {
				{ "Keyboard", false, DESKTOP_VIEWPORT },
				{ "Gamepad1", false, DESKTOP_VIEWPORT }, -- plugged in a controller
				{ "MouseMovement", false, DESKTOP_VIEWPORT }, -- back to mouse
				{ "Touch", false, PHONE_VIEWPORT }, -- (hypothetical) touch session
			}
			local expectedSequence = { "Desktop", "Console", "Desktop", "Mobile" }

			for i, event in stream do
				local inputType, isTenFoot, viewport = event[1], event[2], event[3]
				expect(detect(inputType, isTenFoot, viewport)).to.equal(expectedSequence[i])
			end
		end)
	end)
end
