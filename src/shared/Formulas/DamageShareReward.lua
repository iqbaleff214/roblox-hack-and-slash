--!strict
--[[
	T-901: pure proportional-split formula for co-op enemy-kill rewards.
	"Damage-share, not killer-only" is the documented DoD decision — every
	player who landed damage on the kill gets a cut proportional to their
	share, so a party doesn't get punished (or a single tank-and-spank
	player over-rewarded) for splitting aggro. Chosen over killer-only
	because killer-only would make the *last hit* the only thing that
	matters, actively discouraging players from engaging support-role
	targets (Thrower, Bomber) that a teammate is about to finish off.

	Takes plain `{id, damage}` pairs rather than `Player` instances so this
	stays genuinely dependency-free — the calling service resolves
	`Player -> id` (`tostring(player.UserId)`) and back at the boundary.

	Uses the largest-remainder method (not naive `floor` per share) so the
	split always sums to exactly `totalAmount` — the DoD's "no reward
	inflation from party size" requirement, satisfied exactly rather than
	approximately: a naive floor-per-share split can silently lose 1-3
	points to rounding on every kill, which compounds over a full run.
]]

local DamageShareReward = {}

export type Contribution = { id: string, damage: number }

function DamageShareReward.Split(totalAmount: number, contributions: { Contribution }): { [string]: number }
	local result: { [string]: number } = {}
	if totalAmount <= 0 or #contributions == 0 then
		return result
	end

	local totalDamage = 0
	for _, contribution in contributions do
		totalDamage += contribution.damage
	end
	if totalDamage <= 0 then
		return result
	end

	local remainders: { { id: string, remainder: number } } = {}
	local distributed = 0

	for _, contribution in contributions do
		local exact = totalAmount * (contribution.damage / totalDamage)
		local flooredShare = math.floor(exact)
		result[contribution.id] = flooredShare
		distributed += flooredShare
		table.insert(remainders, { id = contribution.id, remainder = exact - flooredShare })
	end

	table.sort(remainders, function(a, b)
		if a.remainder == b.remainder then
			return a.id < b.id -- deterministic tiebreak, no flicker across identical reruns
		end
		return a.remainder > b.remainder
	end)

	local leftover = totalAmount - distributed
	for i = 1, leftover do
		local id = remainders[i].id
		result[id] += 1
	end

	return result
end

return DamageShareReward
