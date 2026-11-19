-- SonicBoom3D: a 3D vapor cone around your jet, and the jets near you, near Mach 1. This mod is its icon in
-- the main menu, its settings page (Options > Special > SonicBoom3D) and the DLL that draws it (bin); the
-- hook that runs it is Saved Games\DCS\Scripts\Hooks\SonicBoom3D.lua. All in Saved Games: IC stays clean.
declare_plugin("SonicBoom3D", {
	installed = true,
	dirName = current_mod_path,
	displayName = _("SonicBoom3D"),
	shortName = "SonicBoom3D",
	version = "1.3",
	state = "installed",
	info = _("A 3D vapor cone around your jet near Mach 1, and around the jets near you: drawn into DCS's own picture and lit by its sun, with its shadow on the ground and its reflection in water. Only you see it.\n\nSettings, quality included: Options > Special > SonicBoom3D."),
	binaries = {},   -- the hook loads the DLL in bin itself
	Skins = {
		{ name = "SonicBoom3D", dir = "Theme" },
	},
	Options = {
		{ name = "SonicBoom3D", nameId = "SonicBoom3D", dir = "Options", allow_in_simulation = true },
	},
})

plugin_done()
