-- The settings on SonicBoom3D's Special page, and what they start at (as the hook's own, CFG in
-- Scripts\Hooks\SonicBoom3D.lua). The hook reads them as you change them, in flight too.
local DbOption = require("Options.DbOption")
local lfs = require("lfs")

-- The mod's folder: DCS names it in modulelocation while it loads this file.
local DIR = (type(modulelocation) == "string" and modulelocation:gsub("[\\/]+$", "") or lfs.writedir() .. "Mods\\tech\\SonicBoom3D") .. "\\"

return {
	enabled    = DbOption.new():setValue(true):checkbox(),
	quality    = DbOption.new():setValue(3):combo({
		DbOption.Item(_("Low")):Value(1),
		DbOption.Item(_("Medium")):Value(2),
		DbOption.Item(_("High")):Value(3),
		DbOption.Item(_("Ultra")):Value(4),
	}),
	softness   = DbOption.new():setValue(0):slider(DbOption.Range(0, 100)),     -- percent: 0 the crisp cone, 100 the softer
	instability = DbOption.new():setValue(30):slider(DbOption.Range(0, 100)),   -- percent: 0 the formed cone holds, 100 it comes and goes most
	jetShade   = DbOption.new():setValue(true):checkbox(),
	shadow     = DbOption.new():setValue(true):checkbox(),
	reflection = DbOption.new():setValue(true):checkbox(),
	cockpit    = DbOption.new():setValue(true):checkbox(),
	mirrors    = DbOption.new():setValue(true):checkbox(),
	otherJets  = DbOption.new():setValue(25):combo({
		DbOption.Item(_("None, only yours")):Value(0),
		DbOption.Item(_("The nearest 5")):Value(5),
		DbOption.Item(_("The nearest 10")):Value(10),
		DbOption.Item(_("The nearest 25")):Value(25),
		DbOption.Item(_("The nearest 50")):Value(50),
	}),
	testMode   = DbOption.new():setValue(false):checkbox(),
	advancedLogging = DbOption.new():setValue(false):checkbox(),
	machReadout = DbOption.new():setValue(false):checkbox(),
	-- Cone per aircraft: each jet's presets and the one in use (see jets.lua). No widget of DCS's binds it: the
	-- page's jet... widgets are wired up by jetsPage.lua as it opens.
	jets       = { value = {} },
	callbackOnShowDialog = function(container)
		dofile(DIR .. "Options\\jetsPage.lua")(container, dofile(DIR .. "jets.lua"), require("Options.Data"))
		-- Which SonicBoom3D this is, at the right of the title: entry.lua's version, the one the update check goes by.
		local f = io.open(DIR .. "entry.lua", "rb")
		local version = f and f:read("*a"):match('version%s*=%s*"([^"]+)"')
		if f then f:close() end
		container.sbVersion:setText(version and "Version " .. version or "")
	end,
}
