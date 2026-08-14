--!strict
--[[
	Per-weapon combo node graphs (GDD §6.4). Dict keyed by weapon id (matching
	`WeaponDefinitions.comboTreeId`). Each tree is `{ rootNodeId, nodes }`,
	where `nodes` maps nodeId -> `{ light, heavy, damageMult, poiseDamage,
	hitboxShape, isFinisher }`. `light`/`heavy` are the next nodeId for that
	input, or absent (nil) at a finisher — Lua doesn't store nil-valued keys,
	so an absent `light`/`heavy` field IS the "no such branch" case.

	Every tree follows the same canonical shape so the three GDD-required
	combo strings resolve to three distinct finishers:
		L        -> Root -> L1                        (not a finisher, continue)
		L,H      -> Root -> L1 -> H1                   (finisher)
		L,L      -> Root -> L1 -> L2                   (not a finisher, continue)
		L,L,H    -> Root -> L1 -> L2 -> H2              (finisher)
		L,L,L    -> Root -> L1 -> L2 -> L3               (finisher)
		H        -> Root -> H0                         (finisher)
	`buildComboTree` is local — ComboResolver (T-403) and anything else that
	needs to walk a tree consumes the exported dict, not this builder.
]]

type ComboNode = {
	light: string?,
	heavy: string?,
	damageMult: number,
	poiseDamage: number,
	hitboxShape: string,
	isFinisher: boolean,
}

type ComboTree = {
	rootNodeId: string,
	nodes: { [string]: ComboNode },
}

local function buildComboTree(weaponId: string, damageScale: number, hitboxShape: string): ComboTree
	local p = weaponId .. "_"

	return {
		rootNodeId = p .. "Root",
		nodes = {
			[p .. "Root"] = {
				light = p .. "L1",
				heavy = p .. "H0",
				damageMult = 0,
				poiseDamage = 0,
				hitboxShape = "None",
				isFinisher = false,
			},
			[p .. "L1"] = {
				light = p .. "L2",
				heavy = p .. "H1",
				damageMult = 1.0 * damageScale,
				poiseDamage = 5,
				hitboxShape = hitboxShape,
				isFinisher = false,
			},
			[p .. "L2"] = {
				light = p .. "L3",
				heavy = p .. "H2",
				damageMult = 1.0 * damageScale,
				poiseDamage = 5,
				hitboxShape = hitboxShape,
				isFinisher = false,
			},
			[p .. "L3"] = {
				damageMult = 1.8 * damageScale,
				poiseDamage = 10,
				hitboxShape = hitboxShape .. "Wide",
				isFinisher = true,
			},
			[p .. "H0"] = {
				damageMult = 1.5 * damageScale,
				poiseDamage = 15,
				hitboxShape = "Slam",
				isFinisher = true,
			},
			[p .. "H1"] = {
				damageMult = 1.6 * damageScale,
				poiseDamage = 15,
				hitboxShape = "Slam",
				isFinisher = true,
			},
			[p .. "H2"] = {
				damageMult = 2.0 * damageScale,
				poiseDamage = 20,
				hitboxShape = "Slam",
				isFinisher = true,
			},
		},
	}
end

local ComboTrees: { [string]: ComboTree } = {
	Katana = buildComboTree("Katana", 1.0, "Arc"),
	Yari = buildComboTree("Yari", 1.1, "Thrust"),
	Naginata = buildComboTree("Naginata", 1.15, "Sweep"),
	TwinBlades = buildComboTree("TwinBlades", 0.8, "Arc"),
	Fists = buildComboTree("Fists", 0.9, "Punch"),
	Bow = buildComboTree("Bow", 0.85, "Line"),
}

return ComboTrees
