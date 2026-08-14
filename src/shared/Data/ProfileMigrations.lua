--!strict
--[[
	Profile schema version/migration chain (T-205). `DataService` calls
	`Apply(profile.Data)` right after load, before `profile:Reconcile()` —
	migrations fix up structural changes (renamed/restructured fields);
	Reconcile then backfills any brand-new template fields that don't need
	custom logic. Pure (operates on a plain table), so it's unit-testable
	without ProfileService/Studio.

	`Migrations[N]` transforms a profile from version N to version N+1.
	`CurrentVersion` must match `ProfileTemplate.version`.
]]

local ProfileMigrations = {}

ProfileMigrations.CurrentVersion = 1

ProfileMigrations.Migrations = {
	-- Example v0 -> v1 migration: MapStats (per-map clear/reward tracking,
	-- T-903) was introduced in v1. Kept as a live migration (not just a
	-- comment) so this module's mechanism has a real, testable path — the
	-- next actual schema change follows the same pattern.
	[0] = function(data)
		if data.MapStats == nil then
			data.MapStats = {}
		end
	end,
}

function ProfileMigrations.Apply(data: { version: number })
	while data.version < ProfileMigrations.CurrentVersion do
		local migrate = ProfileMigrations.Migrations[data.version]
		assert(migrate, "ProfileMigrations: no migration registered for version " .. data.version)
		migrate(data)
		data.version += 1
	end
	return data
end

return ProfileMigrations
