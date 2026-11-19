-- SonicBoom3D's jets: each one's shape (where its cone goes), its name on the Special page, and the cone's
-- settings per jet (Options > Special > SonicBoom3D, "Cone per aircraft"): the built-in ones, and your presets.
-- Loaded by the hook (Saved Games\DCS\Scripts\Hooks\SonicBoom3D.lua) and by the page (Options\optionsDb.lua).
local M = {}

-- Each jet's shape: the pilot's seat, the wingtip, where the wing ends (te: its trailing edge where it meets
-- the fuselage, or out at the tips when they're swept back), where the wing begins (le: its leading edge
-- where it meets the fuselage, or the glove of a swing-wing; not the strakes or canards ahead of it) and the
-- engine nozzles, in metres ahead of the model's origin; and the wingspan and length in metres. From DCS's
-- own aircraft files (CoreMods\aircraft); te, le, and all of the AI-only jets, measured from straight-down
-- views of each model in DCS, set against its box (the size the mission scripting reports for it); where
-- that box is only a nominal size (the Viggen, the MiG-23 and 27, the Su-17), corrected by where the
-- vapor's back stood against the wing in DCS.
-- The shock is a flat plane across the flight path: once the vapor's solid, at the wing's trailing edge (te;
-- the nozzles for a jet with none), crossing the tips about halfway along them. Photos put it further back,
-- by the nozzles (F/A-18C -8.6, F-15E -6.2), but drawn there the cones look too far back in DCS.
-- While the vapor forms it stands further forward, halfway toward the wing root. Ahead of it the vapor fills
-- a straight-sided cone, its point on the fuselage 40% of the way back
-- from le to te (where the air over the wing goes supersonic: the F/A-18C's measured -2.1, against -2.47);
-- its rim past the tips.
-- Flaming Cliffs jets have no readable file. For them (marked measured) the seat is measured from the
-- cockpit camera, and the rest kept where it is behind it on a sister airframe's file.
M.GEOMETRY = {
	["F-15ESE"]        = { pilot = 6.51, tip = -3.90, nozzle = -6.75, span = 13.05, length = 19.43, te = -4.30, le = 1.20 },
	["F-16C_50"]       = { pilot = 3.32, tip = -2.70, nozzle = -6.00, span = 9.45,  length = 14.52, te = -4.00, le = -0.80 },
	["FA-18C_hornet"]  = { pilot = 3.50, tip = -2.47, nozzle = -8.01, span = 11.43, length = 17.07, te = -4.45, le = -1.15 },
	["F-4E-45MC"]      = { pilot = 5.00, tip = -3.99, nozzle = -4.94, span = 11.70, length = 19.20, te = -5.00, le = 1.60 },
	["F-5E-3"]         = { pilot = 3.02, tip = -2.78, nozzle = -6.05, span = 8.53,  length = 14.68, te = -2.98, le = 0.00 },  -- its file's nozzle is past the tail
	["AJS37"]          = { pilot = 4.80, tip = -4.53, nozzle = -5.80, span = 10.60, length = 16.30, te = -4.50, le = 1.50 },  -- its file's nozzle is a rough -3
	["MiG-21Bis"]      = { pilot = 2.71, tip = -2.50, nozzle = -6.00, span = 7.15,  length = 14.50, te = -2.90, le = 2.10 },
	["MiG-29 Fulcrum"] = { pilot = 4.64, tip = -3.80, nozzle = -6.53, span = 11.36, length = 17.32, te = -3.94, le = 0.15 },
	["MiG-19P"]        = { pilot = 3.76, tip = -2.54, nozzle = -4.00, span = 9.00,  length = 13.03 },
	["F-100D"]         = { pilot = 3.63, tip = -4.31, nozzle = -4.43, span = 11.81, length = 14.35, te = -4.70, le = 2.60 },
	["F-86F Sabre"]    = { pilot = 1.70, tip = -3.21, nozzle = -6.25, span = 11.30, length = 11.43 },
	["MiG-15bis"]      = { pilot = 1.77, tip = -2.25, nozzle = -4.11, span = 10.08, length = 10.11 },
	["Hawk"]           = { pilot = 4.00, tip = -1.76, nozzle = -4.85, span = 9.42,  length = 11.98 },
	["AV8BNA"]         = { pilot = 3.43, tip = -2.54, nozzle = -2.89, span = 9.24,  length = 14.12 },
	["Mirage-F1"]      = { pilot = 3.19, tip = -3.50, nozzle = -7.50, span = 8.40,  length = 15.30, te = -3.50, le = -0.10 },  -- every Mirage-F1 version
	["J-11A"]          = { pilot = 7.92, tip = -4.50, nozzle = -6.89, span = 14.70, length = 21.94, te = -4.00, le = 1.60 },
	["JF-17"]          = { pilot = 4.45, tip = -2.90, nozzle = -5.51, span = 8.50,  length = 14.25, te = -2.84, le = 0.35 },
	["M-2000C"]        = { pilot = 2.68, tip = -5.00, nozzle = -6.59, span = 9.13,  length = 14.36, te = -5.00, le = 1.80 },
	["F-14B"]          = { pilot = 4.00, tip = -5.00, nozzle = -6.67, span = 11.65, length = 19.10, te = -6.50, le = 2.50 },  -- wings swept back, as near Mach 1
	["F-14A-135-GR"]   = { pilot = 4.00, tip = -5.00, nozzle = -6.67, span = 11.65, length = 19.10, te = -6.50, le = 2.50 },
	["F-15C"]          = { pilot = 6.51, tip = -3.90, nozzle = -6.75, span = 13.05, length = 19.43, te = -5.00, le = 1.10, measured = true },  -- as the F-15E
	["Su-27"]          = { pilot = 7.92, tip = -4.50, nozzle = -6.89, span = 14.70, length = 21.94, te = -3.80, le = 1.80, measured = true },  -- as the J-11A
	["Su-33"]          = { pilot = 7.92, tip = -4.50, nozzle = -6.89, span = 14.70, length = 21.19, te = -3.80, le = 1.80, measured = true },
	["MiG-29A"]        = { pilot = 4.64, tip = -3.80, nozzle = -6.53, span = 11.36, length = 17.32, te = -3.94, le = 0.15, measured = true },  -- as the MiG-29
	["MiG-29S"]        = { pilot = 4.64, tip = -3.80, nozzle = -6.53, span = 11.36, length = 17.32, te = -3.94, le = 0.15, measured = true },
	["MiG-29G"]        = { pilot = 4.64, tip = -3.80, nozzle = -6.53, span = 11.36, length = 17.32, te = -3.94, le = 0.15, measured = true },
	-- AI only, all measured in DCS; the swing-wings swept back, as at speed
	["F-16A"]          = { pilot = 4.26, tip = -2.25, nozzle = -5.90, span = 9.45,  length = 15.06, te = -2.45, le = 0.45 },  -- every AI F-16: its own model
	["F-5E"]           = { pilot = 3.38, tip = -2.46, nozzle = -6.08, span = 8.13,  length = 14.45, te = -2.46, le = 0.55 },
	["Mirage 2000-5"]  = { pilot = 3.70, tip = -4.35, nozzle = -6.60, span = 9.13,  length = 14.36, te = -4.65, le = 1.75 },
	["Tornado IDS"]    = { pilot = 4.00, tip = -5.56, nozzle = -7.56, span = 8.60,  length = 16.72, te = -6.00, le = 1.20 },
	["MiG-23MLD"]      = { pilot = 4.30, tip = -5.35, nozzle = -7.10, span = 7.78,  length = 16.70, te = -5.85, le = 2.05 },
	["MiG-27K"]        = { pilot = 5.40, tip = -5.00, nozzle = -6.80, span = 7.78,  length = 17.08, te = -5.50, le = 2.20 },
	["MiG-25PD"]       = { pilot = 6.50, tip = -4.50, nozzle = -7.80, span = 14.01, length = 19.75, te = -5.00, le = 0.30 },
	["MiG-31"]         = { pilot = 6.40, tip = -6.75, nozzle = -10.5, span = 13.46, length = 22.69, te = -7.25, le = -0.05 },
	["Su-17M4"]        = { pilot = 6.00, tip = -4.35, nozzle = -7.80, span = 10.02, length = 19.02, te = -4.85, le = 1.85 },
	["Su-24M"]         = { pilot = 6.10, tip = -7.80, nozzle = -12.1, span = 10.37, length = 22.67, te = -8.25, le = 3.45 },
	["Su-30"]          = { pilot = 8.60, tip = -4.50, nozzle = -6.89, span = 14.70, length = 21.94, te = -3.90, le = 1.70 },
	["Su-34"]          = { pilot = 8.50, tip = -4.00, nozzle = -7.00, span = 14.70, length = 23.34, te = -4.25, le = 1.35 },
	["B-1B"]           = { pilot = 21.0, tip = -15.0, nozzle = -15.5, span = 24.10, length = 44.50, te = -16.1, le = 3.70 },  -- nozzles under the wing
	["Tu-160"]         = { pilot = 21.0, tip = -17.5, nozzle = -16.0, span = 35.60, length = 54.10, te = -18.9, le = 2.10 },  -- nozzles under the wing
	["Tu-22M3"]        = { pilot = 15.3, tip = -14.6, nozzle = -20.6, span = 23.30, length = 42.46, te = -15.6, le = 1.10 },
}
-- Other names for the same models.
M.SAME_AS = {
	["F-15E"] = "F-15ESE", ["F-16A MLU"] = "F-16A", ["F-16C bl.50"] = "F-16A", ["F-16C bl.52d"] = "F-16A",
	["F/A-18A"] = "FA-18C_hornet", ["F/A-18C"] = "FA-18C_hornet", ["QF-4E"] = "F-4E-45MC", ["F-5E-3_FC"] = "F-5E-3",
	["F-14A-135-GR-Early"] = "F-14A-135-GR", ["F-14A-95-GR"] = "F-14A-135-GR", ["F-14BU"] = "F-14B",
	["Tornado GR4"] = "Tornado IDS", ["MiG-25RBT"] = "MiG-25PD", ["Su-24MR"] = "Su-24M",
	["MiG-15bis_FC"] = "MiG-15bis", ["F-86F_FC"] = "F-86F Sabre",
}
-- Anything else: a mid-sized fighter, its seat measured from the cockpit camera.
M.DEFAULT_GEOMETRY = { pilot = 4.0, tip = -3.0, nozzle = -6.5, span = 11.0, length = 16.0, te = -4.5, le = 0.0, measured = true }
M.OTHER = "*"   -- the key for every jet not listed: they share one set of settings

-- Their names in the page's list.
M.LABEL = {
	["F-15ESE"] = "F-15E Strike Eagle", ["F-16C_50"] = "F-16C Viper", ["FA-18C_hornet"] = "F/A-18C Hornet",
	["F-4E-45MC"] = "F-4E Phantom II", ["F-5E-3"] = "F-5E Tiger II", ["AJS37"] = "AJS 37 Viggen", ["MiG-21Bis"] = "MiG-21bis",
	["MiG-29 Fulcrum"] = "MiG-29 Fulcrum", ["MiG-19P"] = "MiG-19P Farmer", ["F-100D"] = "F-100D Super Sabre",
	["F-86F Sabre"] = "F-86F Sabre", ["MiG-15bis"] = "MiG-15bis", ["Hawk"] = "Hawk T.1A", ["AV8BNA"] = "AV-8B Harrier",
	["Mirage-F1"] = "Mirage F1", ["J-11A"] = "J-11A", ["JF-17"] = "JF-17 Thunder", ["M-2000C"] = "Mirage 2000C",
	["F-14B"] = "F-14B Tomcat", ["F-14A-135-GR"] = "F-14A Tomcat", ["F-15C"] = "F-15C Eagle", ["Su-27"] = "Su-27 Flanker",
	["Su-33"] = "Su-33", ["MiG-29A"] = "MiG-29A", ["MiG-29S"] = "MiG-29S", ["MiG-29G"] = "MiG-29G",
	["F-16A"] = "F-16 (AI)", ["F-5E"] = "F-5E (AI)", ["Mirage 2000-5"] = "Mirage 2000-5 (AI)", ["Tornado IDS"] = "Tornado (AI)",
	["MiG-23MLD"] = "MiG-23MLD (AI)", ["MiG-27K"] = "MiG-27K (AI)", ["MiG-25PD"] = "MiG-25 (AI)", ["MiG-31"] = "MiG-31 (AI)",
	["Su-17M4"] = "Su-17M4 (AI)", ["Su-24M"] = "Su-24 (AI)", ["Su-30"] = "Su-30 (AI)", ["Su-34"] = "Su-34 (AI)",
	["B-1B"] = "B-1B (AI)", ["Tu-160"] = "Tu-160 (AI)", ["Tu-22M3"] = "Tu-22M3 (AI)",
	[M.OTHER] = "Other jets",
}

-- The cone's settings for each jet, in the page's order: how far the whole cone moves forward (ft, back
-- below 0), how much further forward its point reaches (ft: a longer cone, or shorter below 0), how far out
-- its rim reaches, how far up and down it reaches, how thick it is and how much it flashes and breathes (%).
M.SETTINGS = {
	{ name = "move",      min = -25, max = 25 },
	{ name = "front",     min = -25, max = 25 },
	{ name = "width",     min = 50,  max = 200 },
	{ name = "top",       min = 25,  max = 200 },
	{ name = "bottom",    min = 25,  max = 200 },
	{ name = "thickness", min = 25,  max = 200 },
	{ name = "pulse",     min = 0,   max = 100 },
}
M.DEFAULT = { move = 0, front = 0, width = 100, top = 100, bottom = 100, thickness = 100, pulse = 100 }
M.DEFAULTS = {}   -- a jet's own built-in settings, where they differ from DEFAULT
M.DEFAULT_PRESET = "Default"   -- the built-in settings' name in the page's preset list: never saved over

-- A jet's key: its own name, the model it shares, or OTHER.
function M.keyOf(name)
	name = M.SAME_AS[name] or name or ""
	if M.GEOMETRY[name] then return name end
	if name:find("^Mirage%-F1") then return "Mirage-F1" end
	return M.OTHER
end

function M.geometry(key)
	return M.GEOMETRY[key] or M.DEFAULT_GEOMETRY
end

-- A jet's built-in settings: a new table.
function M.defaults(key)
	local d = {}
	for k, v in pairs(M.DEFAULT) do d[k] = v end
	for k, v in pairs(M.DEFAULTS[key] or {}) do d[k] = v end
	return d
end

-- The page's saved table (jets, the plugin option "jets"): { last = the jet last picked on the page,
-- use = { [key] = the preset in use }, presets = { [key] = { [name] = settings } }, off = { [key] = true for a
-- jet whose cone is switched off } }. Any of it may be missing.
local function field(t, k)
	return type(t) == "table" and type(t[k]) == "table" and t[k] or nil
end

-- The name of the preset jet key uses (DEFAULT_PRESET if none, or it's gone), and that preset's settings.
function M.preset(jets, key)
	local use = field(jets, "use")
	local name = use and type(use[key]) == "string" and use[key]
	local mine = field(field(jets, "presets"), key)
	local saved = name and mine and type(mine[name]) == "table" and mine[name]
	if not saved then return M.DEFAULT_PRESET, M.defaults(key) end
	local s = M.defaults(key)
	for _, d in ipairs(M.SETTINGS) do
		local v = saved[d.name]
		if type(v) == "number" then s[d.name] = math.max(d.min, math.min(d.max, v)) end
	end
	return name, s
end

-- The settings jet key's cone is drawn with.
function M.settings(jets, key)
	local _, s = M.preset(jets, key)
	return s
end

-- Whether jet key has a cone at all (switched off on the page: none, whatever its preset).
function M.on(jets, key)
	local off = field(jets, "off")
	return not (off and off[key] == true)
end

-- Jet key's own presets' names, sorted.
function M.presetNames(jets, key)
	local names = {}
	for name, s in pairs(field(field(jets, "presets"), key) or {}) do
		if type(name) == "string" and type(s) == "table" then names[#names + 1] = name end
	end
	table.sort(names)
	return names
end

-- The page's list: every key, by name, Other jets last.
function M.list()
	local keys = {}
	for key in pairs(M.GEOMETRY) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b) return (M.LABEL[a] or a):lower() < (M.LABEL[b] or b):lower() end)
	keys[#keys + 1] = M.OTHER
	return keys
end

-- A deep copy (the page saves a new table each change, so DCS can tell it changed and Cancel can undo it).
function M.copy(t)
	if type(t) ~= "table" then return t end
	local c = {}
	for k, v in pairs(t) do c[k] = M.copy(v) end
	return c
end

return M
