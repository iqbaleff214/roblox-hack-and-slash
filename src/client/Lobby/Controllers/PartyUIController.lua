--!strict
--[[
	T-605: party member list, an invite flow (lists other players currently
	in the server), and the "wait for more" vs "Launch Now" choice — reading
	whichever map `MapSelectController` currently has selected (T-603).
	"Launch Now" only ever fires from this explicit button click, never a
	timer or automatically, satisfying T-605's DoD verbatim.

	The ready-toggle is local-only, not server-synced — `PartyService` has
	no concept of "ready" (GDD §6.1's actual mechanic is just "leader
	triggers the portal when ready," no per-member ready state), so this is
	a lobby-social affordance only, not something that gates anything.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local UIBuilder = require(script.Parent.UI.UIBuilder)

local PartyUIController = Knit.CreateController({ Name = "PartyUIController" })

local screenGui: ScreenGui
local memberListFrame: ScrollingFrame
local inviteListFrame: ScrollingFrame
local statusLabel: TextLabel
local readyState: { [number]: boolean } = {} -- UserId -> local-only ready flag

local function rebuildMemberList()
	local PartyService = Knit.GetService("PartyService")
	local party = PartyService:GetParty()

	for _, child in memberListFrame:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local members = if party then party.members else { Players.LocalPlayer }
	local leader = if party then party.leader else Players.LocalPlayer

	local order = 0
	for _, member in members do
		order += 1
		local row = UIBuilder.CreateRow(memberListFrame, order)
		local label = if member == leader then (member.Name .. " (Leader)") else member.Name
		UIBuilder.CreateLabel(row, label, UDim2.fromScale(0.45, 1))

		local readyButton = UIBuilder.CreateButton(
			row,
			if readyState[member.UserId] then "Ready" else "Not Ready",
			UDim2.fromScale(0.25, 0.8),
			UDim2.fromScale(0.45, 0.1)
		)
		if member == Players.LocalPlayer then
			readyButton.Activated:Connect(function()
				readyState[member.UserId] = not readyState[member.UserId]
				rebuildMemberList()
			end)
		else
			readyButton.Active = false
			readyButton.AutoButtonColor = false
		end

		if leader == Players.LocalPlayer and member ~= Players.LocalPlayer then
			local kickButton = UIBuilder.CreateButton(row, "Kick", UDim2.fromScale(0.25, 0.8), UDim2.fromScale(0.72, 0.1))
			kickButton.Activated:Connect(function()
				PartyService:KickMember(member)
			end)
		end
	end
end

local function rebuildInviteList()
	local PartyService = Knit.GetService("PartyService")
	local party = PartyService:GetParty()
	local members = if party then party.members else { Players.LocalPlayer }

	for _, child in inviteListFrame:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local order = 0
	for _, otherPlayer in Players:GetPlayers() do
		if not table.find(members, otherPlayer) then
			order += 1
			local row = UIBuilder.CreateRow(inviteListFrame, order)
			UIBuilder.CreateLabel(row, otherPlayer.Name, UDim2.fromScale(0.6, 1))
			local inviteButton = UIBuilder.CreateButton(row, "Invite", UDim2.fromScale(0.3, 0.8), UDim2.fromScale(0.68, 0.1))
			inviteButton.Activated:Connect(function()
				PartyService:InviteToParty(otherPlayer)
			end)
		end
	end
end

function PartyUIController:Open()
	screenGui.Enabled = true
	rebuildMemberList()
	rebuildInviteList()
end

function PartyUIController:Close()
	screenGui.Enabled = false
end

function PartyUIController:KnitStart()
	screenGui = UIBuilder.CreateScreenGui("PartyUI")
	local panel, content, closeButton = UIBuilder.CreatePanel(screenGui, "Party")
	closeButton.Activated:Connect(function()
		self:Close()
	end)

	Knit.GetController("ResponsiveUIController"):Apply(panel) -- T-1103

	local memberContainer = Instance.new("Frame")
	memberContainer.Name = "MemberContainer"
	memberContainer.BackgroundTransparency = 1
	memberContainer.Size = UDim2.new(1, -16, 0.4, 0)
	memberContainer.Position = UDim2.fromOffset(8, 4)
	memberContainer.Parent = content
	memberListFrame = UIBuilder.CreateScrollingList(memberContainer)

	local inviteContainer = Instance.new("Frame")
	inviteContainer.Name = "InviteContainer"
	inviteContainer.BackgroundTransparency = 1
	inviteContainer.Size = UDim2.new(1, -16, 0.35, 0)
	inviteContainer.Position = UDim2.new(0, 8, 0.42, 0)
	inviteContainer.Parent = content
	inviteListFrame = UIBuilder.CreateScrollingList(inviteContainer)

	statusLabel = UIBuilder.CreateLabel(content, "", UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 1, -76))

	local waitButton = UIBuilder.CreateButton(content, "Wait for More", UDim2.new(0.48, 0, 0, 32), UDim2.new(0, 8, 1, -36))
	waitButton.Activated:Connect(function()
		self:Close()
	end)

	local launchButton = UIBuilder.CreateButton(content, "Launch Now", UDim2.new(0.48, 0, 0, 32), UDim2.new(0.52, 0, 1, -36))
	launchButton.Activated:Connect(function()
		local MapSelectController = Knit.GetController("MapSelectController")
		local mapId = MapSelectController:GetSelectedMapId()
		if not mapId then
			statusLabel.Text = "Select a map first."
			return
		end

		local PortalService = Knit.GetService("PortalService")
		local accepted = PortalService:RequestTeleport(mapId)
		statusLabel.Text = if accepted
			then "Launching..."
			else "Couldn't launch (not party leader, or under the map's level requirement)."
	end)

	local PartyService = Knit.GetService("PartyService")
	PartyService.PartyUpdated:Connect(function()
		rebuildMemberList()
		rebuildInviteList()
	end)

	Players.PlayerAdded:Connect(rebuildInviteList)
	Players.PlayerRemoving:Connect(rebuildInviteList)
end

return PartyUIController
