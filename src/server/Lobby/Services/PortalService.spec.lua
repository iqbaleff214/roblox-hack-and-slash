--[[
	Requires a live Player — Studio Play Solo/Team Test, see S-1301. The
	actual reserved-server teleport can't be exercised at all until T-1402
	fills in Constants.PlaceIds.Battlefield (after S-001 publishes the real
	places) — these specs cover everything rejectable *before* that point:
	non-leader requests and the level gate.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("PortalService.HandleTeleportRequest", function()
		it("rejects a request for an unknown mapId", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local PortalService = Knit.GetService("PortalService")
			expect(PortalService:HandleTeleportRequest(player, "NotARealMap")).to.equal(false)
		end)

		it("rejects a non-leader's request when in a party (Team Test only, 2+ players)", function()
			local players = Players:GetPlayers()
			if #players < 2 then
				return -- needs Studio Team Test; covered by S-1301
			end

			local leader, member = players[1], players[2]
			local PartyService = Knit.GetService("PartyService")
			local PortalService = Knit.GetService("PortalService")

			PartyService:LeaveParty(leader)
			PartyService:LeaveParty(member)
			PartyService:InviteToParty(leader, member)
			PartyService:AcceptInvite(member)

			expect(PortalService:HandleTeleportRequest(member, "Okehazama")).to.equal(false)
		end)

		it("rejects an under-level solo player against the recommended level (T-303 tolerance)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local PortalService = Knit.GetService("PortalService")
			local DataService = Knit.GetService("DataService")
			local profile = DataService:GetProfile(player)
			if not profile then
				return
			end

			local originalLevel = profile.Data.Level
			profile.Data.Level = 1 -- Okehazama's recommendedLevel is 5, tolerance 3 -> min level 2

			local accepted = PortalService:HandleTeleportRequest(player, "Okehazama")
			expect(accepted).to.equal(false)

			profile.Data.Level = originalLevel
		end)
	end)
end
