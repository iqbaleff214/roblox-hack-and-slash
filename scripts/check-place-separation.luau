--!strict
--[[
	T-006 smoke test: asserts the Lobby-only and Battlefield-only Services
	folders never define a same-named module. This can't be expressed as a
	TestEZ spec because it compares two place trees that never run in the same
	DataModel at once — it's a filesystem check, run with:

		lune run scripts/check-place-separation

	Extend the `folderPairs` list below if Controllers ever need the same check.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local function listModuleNames(path: string): { string }
	local names = {}
	if fs.isDir(path) then
		for _, entryName in fs.readDir(path) do
			local baseName = entryName:gsub("%.luau$", ""):gsub("%.lua$", "")
			if baseName ~= entryName or entryName:match("%.lua$") then
				table.insert(names, baseName)
			end
		end
	end
	return names
end

local folderPairs = {
	{
		label = "Services",
		lobby = "src/server/Lobby/Services",
		battlefield = "src/server/Battlefield/Services",
	},
	{
		label = "Controllers",
		lobby = "src/client/Lobby/Controllers",
		battlefield = "src/client/Battlefield/Controllers",
	},
}

local ok = true

for _, pair in folderPairs do
	local lobbyNames = listModuleNames(pair.lobby)
	local battlefieldNames = listModuleNames(pair.battlefield)

	local lobbySet: { [string]: boolean } = {}
	for _, name in lobbyNames do
		lobbySet[name] = true
	end

	local collisions = {}
	for _, name in battlefieldNames do
		if lobbySet[name] then
			table.insert(collisions, name)
		end
	end

	if #collisions > 0 then
		ok = false
		print(("FAIL [%s]: name(s) defined in both Lobby and Battlefield: %s"):format(pair.label, table.concat(collisions, ", ")))
	else
		print(("PASS [%s]: Lobby (%d) and Battlefield (%d) are disjoint"):format(pair.label, #lobbyNames, #battlefieldNames))
	end
end

if not ok then
	process.exit(1)
end
