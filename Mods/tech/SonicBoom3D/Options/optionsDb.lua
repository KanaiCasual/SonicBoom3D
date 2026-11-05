-- The settings on SonicBoom3D's Special page, and what they start at (as the hook's own, CFG in
-- Scripts\Hooks\SonicBoom3D.lua). The hook reads them as you change them, in flight too.
local DbOption = require("Options.DbOption")

return {
	enabled    = DbOption.new():setValue(true):checkbox(),
	quality    = DbOption.new():setValue(3):combo({
		DbOption.Item(_("Low")):Value(1),
		DbOption.Item(_("Medium")):Value(2),
		DbOption.Item(_("High")):Value(3),
		DbOption.Item(_("Ultra")):Value(4),
	}),
	density    = DbOption.new():setValue(100):slider(DbOption.Range(25, 200)),   -- percent
	width      = DbOption.new():setValue(100):slider(DbOption.Range(70, 150)),
	pulse      = DbOption.new():setValue(100):slider(DbOption.Range(0, 100)),
	soft       = DbOption.new():setValue(false):checkbox(),
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
}
