--[[
	Cap/leader rules are unit-tested standalone in PartyRules.spec.lua (no
	Player/Studio needed). Multi-player flows here (invite/accept/kick)
	need at least two live players — Studio Team Test, not just Play Solo;
	the two-or-more-player cases are skipped gracefully when only one
	player is present, same pattern as everywhere else in this backlog
	that needs a live session (S-1301).
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("PartyService", function()
		it("CreateParty makes a solo party with the creator as leader", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local PartyService = Knit.GetService("PartyService")
			PartyService:LeaveParty(player) -- clean slate

			local created = PartyService:CreateParty(player)
			expect(created).to.equal(true)

			local party = PartyService:GetParty(player)
			expect(party).never.to.equal(nil)
			expect((party :: any).leader).to.equal(player)
			expect(#(party :: any).members).to.equal(1)

			PartyService:LeaveParty(player)
		end)

		it("invite/accept/kick full flow (Team Test only, 2+ players)", function()
			local players = Players:GetPlayers()
			if #players < 2 then
				return -- needs Studio Team Test; covered by S-1301
			end

			local leader, invitee = players[1], players[2]
			local PartyService = Knit.GetService("PartyService")
			PartyService:LeaveParty(leader)
			PartyService:LeaveParty(invitee)

			expect(PartyService:InviteToParty(leader, invitee)).to.equal(true)
			expect(PartyService:AcceptInvite(invitee)).to.equal(true)

			local party = PartyService:GetParty(leader)
			expect(#(party :: any).members).to.equal(2)

			-- Non-leader kick rejected.
			expect(PartyService:KickMember(invitee, leader)).to.equal(false)

			-- Leader kick succeeds.
			expect(PartyService:KickMember(leader, invitee)).to.equal(true)
			expect(PartyService:GetParty(invitee)).to.equal(nil)
		end)
	end)
end
