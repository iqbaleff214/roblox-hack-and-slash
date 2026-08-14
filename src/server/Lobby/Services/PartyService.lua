--!strict
--[[
	T-604: ephemeral (not DataStore-persisted — dissolves on disconnect,
	which is correct, parties are a session-social concept) Lobby-only
	party grouping, capped per `Constants.Party.MaxSize` (GDD §6.1).

	`InviteToParty` auto-creates a party for a solo inviter — the task text
	only explicitly leader-restricts `KickMember` ("only the leader can
	kick"), so this matches common party-game UX without contradicting the
	spec. Cap/leader checks delegate to the pure `PartyRules` module.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local PartyRules = require(ReplicatedStorage.Shared.Formulas.PartyRules)

local PartyService = Knit.CreateService({
	Name = "PartyService",
	Client = {
		PartyUpdated = Knit.CreateSignal(),
		PartyInviteReceived = Knit.CreateSignal(),
	},
})

export type Party = {
	leader: Player,
	members: { Player },
}

local partyByPlayer: { [Player]: Party } = {}
local pendingInvites: { [Player]: Player } = {} -- targetPlayer -> inviter

local function snapshot(party: Party): Party
	return { leader = party.leader, members = table.clone(party.members) }
end

local function soloSnapshot(player: Player): Party
	return { leader = player, members = { player } }
end

local function broadcastPartyUpdate(party: Party)
	local data = snapshot(party)
	for _, member in party.members do
		PartyService.Client.PartyUpdated:Fire(member, data)
	end
end

function PartyService:CreateParty(player: Player): boolean
	if partyByPlayer[player] then
		return false -- already in a party
	end
	local party: Party = { leader = player, members = { player } }
	partyByPlayer[player] = party
	broadcastPartyUpdate(party)
	return true
end

function PartyService.Client:CreateParty(player: Player): boolean
	return self.Server:CreateParty(player)
end

function PartyService:InviteToParty(player: Player, targetPlayer: Player): boolean
	if player == targetPlayer then
		return false
	end
	if partyByPlayer[targetPlayer] then
		return false -- target already in a party
	end

	local party = partyByPlayer[player]
	if not party then
		self:CreateParty(player)
		party = partyByPlayer[player]
	end
	if not party then
		return false
	end

	if not PartyRules.CanAddMember(#party.members, Constants.Party.MaxSize) then
		return false
	end

	pendingInvites[targetPlayer] = player
	self.Client.PartyInviteReceived:Fire(targetPlayer, player)
	return true
end

function PartyService.Client:InviteToParty(player: Player, targetPlayer: Player): boolean
	return self.Server:InviteToParty(player, targetPlayer)
end

function PartyService:AcceptInvite(player: Player): boolean
	local inviter = pendingInvites[player]
	if not inviter then
		return false
	end
	pendingInvites[player] = nil

	if partyByPlayer[player] then
		return false -- already in a party
	end

	local party = partyByPlayer[inviter]
	if not party then
		return false -- inviter's party dissolved before this was accepted
	end
	if not PartyRules.CanAddMember(#party.members, Constants.Party.MaxSize) then
		return false
	end

	table.insert(party.members, player)
	partyByPlayer[player] = party
	broadcastPartyUpdate(party)
	return true
end

function PartyService.Client:AcceptInvite(player: Player): boolean
	return self.Server:AcceptInvite(player)
end

local function removeMember(party: Party, player: Player): boolean
	local index = table.find(party.members, player)
	if not index then
		return false
	end
	table.remove(party.members, index)
	partyByPlayer[player] = nil
	return true
end

function PartyService:LeaveParty(player: Player): boolean
	local party = partyByPlayer[player]
	if not party then
		return false
	end

	removeMember(party, player)

	if #party.members <= 1 then
		if #party.members == 1 then
			partyByPlayer[party.members[1]] = nil
		end
		return true
	end

	if party.leader == player then
		party.leader = party.members[1]
	end
	broadcastPartyUpdate(party)
	return true
end

function PartyService.Client:LeaveParty(player: Player): boolean
	return self.Server:LeaveParty(player)
end

function PartyService:KickMember(player: Player, targetPlayer: Player): boolean
	local party = partyByPlayer[player]
	if not party then
		return false
	end
	if not PartyRules.CanKick(party.leader, player, targetPlayer) then
		return false
	end
	if not table.find(party.members, targetPlayer) then
		return false
	end

	removeMember(party, targetPlayer)
	self.Client.PartyUpdated:Fire(targetPlayer, soloSnapshot(targetPlayer))

	if #party.members == 1 then
		partyByPlayer[party.members[1]] = nil
	else
		broadcastPartyUpdate(party)
	end

	return true
end

function PartyService.Client:KickMember(player: Player, targetPlayer: Player): boolean
	return self.Server:KickMember(player, targetPlayer)
end

function PartyService:GetParty(player: Player): Party?
	local party = partyByPlayer[player]
	return party and snapshot(party)
end

function PartyService.Client:GetParty(player: Player): Party?
	return self.Server:GetParty(player)
end

function PartyService:KnitInit()
	Players.PlayerRemoving:Connect(function(player: Player)
		self:LeaveParty(player)
		pendingInvites[player] = nil
	end)
end

return PartyService
