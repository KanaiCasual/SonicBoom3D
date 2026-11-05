-- SonicBoom3D: a vapor cone around your jet near Mach 1, and around the other jets near you, drawn into
-- DCS's own picture: in outside views, from the cockpit (behind the canopy frame) and in the cockpit
-- mirrors. Only you see it. Works in single player, and as a client on a server that allows own-aircraft
-- export (your jet) and object export (the others).
-- Lives in Saved Games, so IC stays clean. The rest of it is the mod Saved Games\DCS\Mods\tech\SonicBoom3D: the
-- DLL that draws it (bin), its icon in the main menu, and its settings page, Options > Special > SonicBoom3D.

local Sim = Sim or DCS -- DCS 2.9.31 renamed DCS.* to Sim.*

-- The settings. Those on the Special page (the ones marked) take the place of these, live, in flight too;
-- these are what's used before they're changed there.
local CFG = {
	ENABLED = true,        -- page: the cone at all
	QUALITY = 3,           -- page: how fine the steps through the vapor are, 1 low, 2 medium, 3 high, 4 ultra: finer costs more GPU time
	MACH_ON_START = 0.94,  -- the vapor starts flashing in from here...
	MACH_ON_FULL = 0.97,   -- ...is solid, always there, from here...
	MACH_OFF_START = 1.01, -- ...starts to break up here...
	MACH_OFF_END = 1.03,   -- ...and is gone here (real vapor cones are mostly just below Mach 1)
	G_EARLIER = 0.02,      -- pulling G brings it in earlier: this much Mach per G over 1, up to 4 G's worth
	ALT_FULL_M = 3000,     -- full strength below this altitude (m above sea level)...
	ALT_FADE_M = 12000,    -- ...thinning to ALT_MIN by this one, where the air is dry
	ALT_MIN = 0.15,
	DENSITY = 2,           -- page: how thick the vapor looks: 1 = thinner and more see-through, 4 = twice as thick
	CONE_WIDTH = 1,        -- page: how far out the cone's rim reaches: 1 = 1.2 half-spans, as in photos; its start and end stay put
	JET_SHADE = true,      -- page: the jet's wing and fuselage shade its vapor from the sun
	SHADOW = true,         -- page: its shadow on the ground, the sea and the jet
	REFLECTION = true,     -- page: its reflection in water, as DCS reflects jets
	PULSE = 1,             -- page: how much it flashes forming and breaking up, and breathes when solid: 0 = steady, 1 = like real footage
	SOFT = false,          -- page: a softer cone, a smooth mist with soft edges (as the JF-17 draws its own), not crisp faces
	SHOW_IN_COCKPIT = true, -- page
	COCKPIT_RADIUS = 8,    -- camera this close to your jet (m) counts as the cockpit view
	SHOW_IN_MIRRORS = true, -- page
	MIRROR_BRIGHTNESS = 1, -- the vapor's brightness in the mirrors (DCS renders them before tonemapping)
	MAX_DISTANCE = 3000,   -- no cone when the camera is further than this from your jet (m)
	OTHER_JETS = 25,       -- page: vapor on this many of the nearest other jets too, 0 = only yours
	OTHER_DISTANCE = 8000, -- ...within this far of the camera (m)
	DCS_LIGHT = true,      -- draw it into DCS's own HDR picture, lit with DCS's light; false = onto the finished picture, lit its own way
	SCATTER_TEST = false,  -- true: much fuller lighting, to see how it could look; very slow (many times the GPU time)
	TEST_MODE = false,     -- page: show the cone at any speed and height, to check it lines up
}

-- The Special page's settings (Mods\tech\SonicBoom3D\Options): each its name there, the setting above it
-- takes the place of, and how (the sliders are in percent).
local OPTIONS = {
	{ "enabled", "ENABLED" }, { "quality", "QUALITY" },
	{ "density", "DENSITY", function(v) return 2 * v / 100 end },   -- 100% = 2
	{ "width", "CONE_WIDTH", function(v) return v / 100 end },
	{ "pulse", "PULSE", function(v) return v / 100 end },
	{ "soft", "SOFT" }, { "jetShade", "JET_SHADE" }, { "shadow", "SHADOW" }, { "reflection", "REFLECTION" },
	{ "cockpit", "SHOW_IN_COCKPIT" }, { "mirrors", "SHOW_IN_MIRRORS" }, { "otherJets", "OTHER_JETS" },
	{ "testMode", "TEST_MODE" },
}
local DEFAULTS = {}
for k, v in pairs(CFG) do DEFAULTS[k] = v end
local hasOptions, OptionsData = pcall(require, "Options.Data")

-- The page's settings into CFG, or the defaults where it has none (not installed, or not read).
local function readOptions()
	for _, o in ipairs(OPTIONS) do
		local value = DEFAULTS[o[2]]
		if hasOptions then
			local ok, v = pcall(OptionsData.getPlugin, "SonicBoom3D", o[1])
			if ok and type(v) == type(value) then value = o[3] and o[3](v) or v end
		end
		CFG[o[2]] = value
	end
end

-- Jets whose module draws its own vapor cone, when a person flies them: no second one on top. An AI one
-- (its module isn't running) gets this cone. Delete a line to get this cone on it always.
local OWN_VAPOR = { ["JF-17"] = true, ["M-2000C"] = true }

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
local GEOMETRY = {
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
local SAME_AS = {
	["F-15E"] = "F-15ESE", ["F-16A MLU"] = "F-16A", ["F-16C bl.50"] = "F-16A", ["F-16C bl.52d"] = "F-16A",
	["F/A-18A"] = "FA-18C_hornet", ["F/A-18C"] = "FA-18C_hornet", ["QF-4E"] = "F-4E-45MC", ["F-5E-3_FC"] = "F-5E-3",
	["F-14A-135-GR-Early"] = "F-14A-135-GR", ["F-14A-95-GR"] = "F-14A-135-GR", ["F-14BU"] = "F-14B",
	["Tornado GR4"] = "Tornado IDS", ["MiG-25RBT"] = "MiG-25PD", ["Su-24MR"] = "Su-24M",
	["MiG-15bis_FC"] = "MiG-15bis", ["F-86F_FC"] = "F-86F Sabre",
}
-- Anything else: a mid-sized fighter, its seat measured from the cockpit camera.
local DEFAULT_GEOMETRY = { pilot = 4.0, tip = -3.0, nozzle = -6.5, span = 11.0, length = 16.0, te = -4.5, le = 0.0, measured = true }

local lfs = require("lfs")
local DIR = lfs.writedir() .. "Mods\\tech\\SonicBoom3D\\bin\\"

local SB, fov, errored, nextStatus = nil, 78, false, nil

local function say(msg)
	log.write("SONICBOOM", log.INFO, msg)
end

local function ramp(x, a, b)
	return math.max(0, math.min(1, (x - a) / (b - a)))
end

-- 0..1: how formed the vapor is at this Mach number and G (smoothed): 1 is solid, below that it flashes
-- in or breaks up. As in real life, pulling G forms it at a lower Mach.
local function strength(mach, load)
	if CFG.TEST_MODE then return 1 end
	local early = CFG.G_EARLIER * math.min(math.max(load - 1, 0), 4)
	return ramp(mach, CFG.MACH_ON_START - early, CFG.MACH_ON_FULL - early) * (1 - ramp(mach, CFG.MACH_OFF_START, CFG.MACH_OFF_END))
end

-- How thick it is at this altitude: thinner high up, where the air is dry. Thinner, not flashing.
local function thickness(alt)
	if CFG.TEST_MODE then return CFG.DENSITY end
	return CFG.DENSITY * (1 - (1 - CFG.ALT_MIN) * ramp(alt, CFG.ALT_FULL_M, CFG.ALT_FADE_M))
end

-- DCS's Default FOV option, used until the DLL finds the live camera FOV on the GPU.
local function readDefaultFov()
	local chunk = loadfile(lfs.writedir() .. "Config\\options.lua")
	if not chunk then return end
	local env = {}
	setfenv(chunk, env)
	if pcall(chunk) and env.options and env.options.graphics then
		fov = tonumber(env.options.graphics.defaultFOV) or fov
	end
end

-- Each map's clock against UTC, for where the sun is. An unknown map is taken to run on local solar time.
local UTC_OFFSET = {
	Caucasus = 4, PersianGulf = 4, Syria = 3, Nevada = -8, Normandy = 2, TheChannel = 2, MarianaIslands = 10,
	Falklands = -3, SinaiMap = 2, Kola = 3, Afghanistan = 4.5, Iraq = 3, GermanyCW = 1,
}
local missionClock = nil   -- { year, month, day, start time (s after midnight), UTC offset or nil }

local function readMissionClock()
	local ok, cur = pcall(Sim.getCurrentMission)
	local m = ok and type(cur) == "table" and cur.mission
	if m and m.date and m.start_time then
		missionClock = { m.date.Year, m.date.Month, m.date.Day, m.start_time, UTC_OFFSET[m.theatre or ""] }
	end
end

-- Direction to the sun in DCS's axes (x north, y up, z east): from the mission's date and time, model
-- time since the start, and where you are. 0 0 0 when the mission's clock isn't known.
local function sunDirection(lat, lon, seconds)
	if not (missionClock and lat and lon) then return 0, 0, 0 end
	local y, mo, d, start, utc = missionClock[1], missionClock[2], missionClock[3], missionClock[4], missionClock[5]
	local hours = (start + seconds) / 3600 - (utc or lon / 15)   -- UTC, from midnight on the mission's date
	local a = math.floor((14 - mo) / 12)
	local yy, mm = y + 4800 - a, mo + 12 * a - 3
	local jdn = d + math.floor((153 * mm + 2) / 5) + 365 * yy + math.floor(yy / 4) - math.floor(yy / 100)
		+ math.floor(yy / 400) - 32045
	local n = jdn - 2451545 + (hours - 12) / 24                 -- days since 2000-01-01 12:00 UTC
	local g = math.rad(357.529 + 0.98560028 * n)
	local L = math.rad(280.459 + 0.98564736 * n + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g))
	local e = math.rad(23.439 - 0.00000036 * n)
	local ra = math.atan2(math.cos(e) * math.sin(L), math.cos(L))
	local dec = math.asin(math.sin(e) * math.sin(L))
	local h = math.rad((280.46061837 + 360.98564736629 * n) % 360 + lon) - ra   -- the sun's hour angle
	local phi = math.rad(lat)
	return math.sin(dec) * math.cos(phi) - math.cos(dec) * math.cos(h) * math.sin(phi),
		math.sin(dec) * math.sin(phi) + math.cos(dec) * math.cos(h) * math.cos(phi),
		-math.cos(dec) * math.sin(h)
end

-- The jet's up direction from its heading, pitch and bank, in DCS's axes. Positive bank is taken as
-- right wing down; the cockpit camera confirms that (or turns it round) the first time you bank in there.
local bankSign, bankVote, bankSamples = 1, 0, 0

local function jetUp(H, P, B)
	local cb, sb = math.cos(B), math.sin(B)
	local ux, uy, uz = -math.sin(P) * math.cos(H), math.cos(P), -math.sin(P) * math.sin(H)   -- wings level
	local rx, rz = -math.sin(H), math.cos(H)                                               -- the right wing, level
	return ux * cb + rx * sb, uy * cb, uz * cb + rz * sb
end

-- Your jet over the last few simulation frames, newest first: position, nose, model time, heading,
-- pitch, bank. DCS's simulation runs on its own thread, a step ahead of the picture: in motion, the jet
-- Lua reads is where the jet will be, not where it's drawn. So the cone goes where the jet was that many
-- frames ago. One by default; in the cockpit of a jet whose seat is known, it's measured: the lag that
-- puts your head on the seat.
local MAX_LAG = 3
local history, lag, lagError, lagSamples = {}, 1, {}, 0

-- The list with jet o added in front (another jet's list works the same way).
local function remember(list, o, t)
	local p, h, cp = o.Position, list[1], math.cos(o.Pitch)
	if h and (p.x - h[1]) ^ 2 + (p.y - h[2]) ^ 2 + (p.z - h[3]) ^ 2 > 500 * 500 then list = {} end   -- a respawn
	table.insert(list, 1, { p.x, p.y, p.z, cp * math.cos(o.Heading), math.sin(o.Pitch), cp * math.sin(o.Heading), t,
		o.Heading, o.Pitch, o.Bank or 0 })
	list[MAX_LAG + 2] = nil
	return list
end

local seatType, seatX = nil, nil

-- How far the camera c sits ahead of, and off to the side of, the jet in history frame h.
local function fromJet(c, h)
	local dx, dy, dz = c.x - h[1], c.y - h[2], c.z - h[3]
	local ahead = dx * h[4] + dy * h[5] + dz * h[6]
	return ahead, math.sqrt(math.max(0, dx * dx + dy * dy + dz * dz - ahead * ahead))
end

-- In the cockpit the camera is your head, close to the jet's centreline: averaged, it marks the seat
-- (for jets with no file), or, at speed, it shows which frame the picture is drawn from. Banked, the
-- camera's up (camUp) shows which way DCS counts bank.
local function measureCockpit(name, g, c, camUp)
	if seatType ~= name then
		seatType, seatX, lagError, lagSamples = name, nil, {}, 0
	end
	local inside = false   -- close to the centreline of the jet in one of the recent frames
	for L = 0, #history - 1 do
		local ahead, off = fromJet(c, history[L + 1])
		if off < 1.5 and math.abs(ahead) < CFG.COCKPIT_RADIUS then inside = true end
	end
	if not inside then return end
	local hb = history[math.min(lag, #history - 1) + 1]
	if bankSamples < 60 and math.abs(hb[10]) > 0.35 then
		local px, py, pz = jetUp(hb[8], hb[9], hb[10])
		local mx, my, mz = jetUp(hb[8], hb[9], -hb[10])
		bankVote = bankVote + (px - mx) * camUp.x + (py - my) * camUp.y + (pz - mz) * camUp.z
		bankSamples = bankSamples + 1
		if bankSamples == 60 then
			bankSign = bankVote < 0 and -1 or 1
			say(bankSign > 0 and "bank check: positive bank is right wing down, as assumed"
				or "bank check: DCS counts bank the other way round; turned round")
		end
	end
	if g.measured then
		local ahead = fromJet(c, history[math.min(lag, #history - 1) + 1])
		seatX = seatX and seatX + (ahead - seatX) * 0.02 or ahead
		return
	end
	local h1, h2 = history[1], history[2]
	if not (history[MAX_LAG + 1] and h1[7] > h2[7]) then return end
	local speed = math.sqrt((h1[1] - h2[1]) ^ 2 + (h1[2] - h2[2]) ^ 2 + (h1[3] - h2[3]) ^ 2) / (h1[7] - h2[7])
	if speed < 60 then return end   -- slower, every frame puts you on the seat
	for L = 0, MAX_LAG do
		local err = math.abs(fromJet(c, history[L + 1]) - g.pilot)
		lagError[L] = lagError[L] and lagError[L] + (err - lagError[L]) * 0.05 or err
	end
	lagSamples = lagSamples + 1
	if lagSamples < 60 then return end
	local best = 0
	for L = 1, MAX_LAG do
		if lagError[L] < lagError[best] then best = L end
	end
	if best ~= lag then
		lag = best
		say(string.format("the picture is drawn %d simulation frame(s) behind Lua (seat off by %.2f m)", lag, lagError[lag]))
	end
end

-- The cone's size (1 = F-15 sized). Then, in metres ahead of the jet's origin: where the cone starts, its
-- point on the fuselage (a jet with no le: where a 60 degree cone 1.45 half-spans across would start); two
-- marks by the wing root (the shock starts halfway between the second and its solid place while the vapor
-- forms); where the shock stands once it's solid. The half-span. And the wing's root, trailing and leading
-- edge (0: not known), for the jet's shade on its vapor.
local function placement(g, yours)
	local shift = yours and g.measured and seatX and seatX - g.pilot or 0
	local pilot, tip = g.pilot + shift, g.tip + shift
	local reach = pilot - tip
	local back = (g.te or g.nozzle) + shift
	local te, le = g.te and g.te + shift, g.le and g.le + shift
	local start = le and te + 0.6 * (le - te) or back + 0.42 * g.span
	return 0.5 * (g.span / 13.05 + g.length / 19.43), start, tip + 0.3 * reach, tip + 0.18 * reach, back, g.span / 2,
		te or 0, le or 0
end

local function geometryOf(name)
	name = SAME_AS[name] or name
	return GEOMETRY[name] or (name:find("^Mirage%-F1") and GEOMETRY["Mirage-F1"]) or DEFAULT_GEOMETRY
end

-- Other jets. DCS tells Lua only where they are and which way they point, so, as Tacview does, their
-- speed and G come from their flight path, smoothed over a few tenths of a second. Their airspeed is
-- that less the wind where they are, their Mach that over the speed of sound at their height: DCS's
-- standard atmosphere, as much warmer or colder as your own jet's Mach meter shows the mission to be.
local others, nextScan, warmer = {}, 0, 0   -- jets followed, by id; when to look for jets again; the mission over standard (K)
local yourLoad = 1   -- your G, smoothed over a few tenths of a second like the other jets'

local function standardTemperature(alt)
	return 288.15 - 0.0065 * math.min(alt, 11000)
end

-- Every half second: the nearest jets to the camera, keeping what's known of those already followed.
local function lookAround(c, t)
	nextScan = t + 0.5
	local near, found = {}, {}
	if CFG.OTHER_JETS > 0 and Export.LoIsObjectExportAllowed and Export.LoIsObjectExportAllowed() then
		local mine = Export.LoGetPlayerPlaneId and Export.LoGetPlayerPlaneId()
		for id, o in pairs(Export.LoGetWorldObjects() or {}) do
			local p, kind = o.Position, o.Type
			local own = OWN_VAPOR[o.Name or ""] and o.Flags and o.Flags.Human
			if id ~= mine and p and kind and kind.level1 == 1 and kind.level2 == 1 and not own then
				local d2 = (p.x - c.x) ^ 2 + (p.y - c.y) ^ 2 + (p.z - c.z) ^ 2
				if d2 < CFG.OTHER_DISTANCE ^ 2 then near[#near + 1] = { id, d2 } end
			end
		end
		table.sort(near, function(a, b) return a[2] < b[2] end)
	end
	for i = 1, math.min(#near, CFG.OTHER_JETS) do
		local id = near[i][1]
		found[id] = others[id] or { history = {} }
	end
	others = found
end

-- Another jet's values for the DLL, in the order of its JET_FIELDS; nil while its speed isn't known yet.
local function otherJet(id, j, o, t)
	j.history = remember(j.history, o, t)
	local h1, h2 = j.history[1], j.history[2]
	if not h2 then j.v, j.a = nil, nil end   -- new, or respawned
	if h2 and h1[7] > h2[7] then
		local dt = h1[7] - h2[7]
		local k = 1 - math.exp(-dt / 0.3)
		local v = { (h1[1] - h2[1]) / dt, (h1[2] - h2[2]) / dt, (h1[3] - h2[3]) / dt }
		if j.v then
			for i = 1, 3 do
				local was = j.v[i]
				j.v[i] = was + (v[i] - was) * k
				j.a[i] = j.a[i] + ((j.v[i] - was) / dt - j.a[i]) * k
			end
		else
			j.v, j.a = v, { 0, 0, 0 }
		end
	end
	if not j.v then return end
	local p = o.Position
	local wx, wy, wz = 0, 0, 0
	if Export.LoGetWindAtPoint then wx, wy, wz = Export.LoGetWindAtPoint(p.x, p.y, p.z, false) end
	local air = math.sqrt((j.v[1] - (wx or 0)) ^ 2 + (j.v[2] - (wy or 0)) ^ 2 + (j.v[3] - (wz or 0)) ^ 2)
	local mach = air / math.sqrt(401.874 * (standardTemperature(p.y) + warmer))
	local h = j.history[math.min(lag, #j.history - 1) + 1]
	local ux, uy, uz = jetUp(h[8], h[9], h[10] * bankSign)
	local load = (j.a[1] * ux + j.a[2] * uy + j.a[3] * uz) / 9.81 + uy   -- along its up, gravity included
	local size, front, shock0, shock1, outer, halfSpan, te, le = placement(geometryOf(o.Name or ""), false)
	return { strength(mach, load), h[1], h[2], h[3], h[4], h[5], h[6], h[7] + id % 97 * 7.3,   -- each breathing on its own, timed from its pose
		size, 1, front, shock0, shock1, outer, halfSpan, ux, uy, uz, load, thickness(p.y), id,
		j.v[1], j.v[2], j.v[3], h[7],   -- its velocity, and when it was where it is, for the DLL to move it on to the picture's time
		CFG.CONE_WIDTH, te, le }
end

local function sendFrame()
	readOptions()
	if not CFG.ENABLED then return SB.frame(0) end
	local cam = Export.LoGetCameraPosition()
	if not cam then return SB.frame(0) end
	local c, t = cam.p, Sim.getModelTime()
	local me = Export.LoIsOwnshipExportAllowed() and Export.LoGetSelfData()
	if not (me and me.Position) or OWN_VAPOR[me.Name or ""] then me = nil end

	-- your jet as the picture shows it; its nose and up in DCS world axes (x north, y up, z east)
	local s, h, size, mainView, front, shock0, shock1, outer, halfSpan = 0, { 0, 0, 0, 0, 0, 0 }, 0, false, 0, 0, 0, 0, 0
	local width, te, le = CFG.CONE_WIDTH, 0, 0
	local ux, uy, uz, load, density, lla = 0, 0, 0, 1, CFG.DENSITY, me and me.LatLongAlt
	local vel, seenAt = { x = 0, y = 0, z = 0 }, 0   -- your jet's velocity, and when it was where it's sent
	if me then
		local name = me.Name or ""
		history = remember(history, me, t)
		h = history[math.min(lag, #history - 1) + 1]
		seenAt = h[7]
		vel = Export.LoGetVectorVelocity and Export.LoGetVectorVelocity() or vel
		ux, uy, uz = jetUp(h[8], h[9], h[10] * bankSign)
		local acc = Export.LoGetAccelerationUnits and Export.LoGetAccelerationUnits()
		load = acc and acc.y or 1
		local dx, dy, dz = h[1] - c.x, h[2] - c.y, h[3] - c.z
		local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
		local mach, alt = Export.LoGetMachNumber() or 0, Export.LoGetAltitudeAboveSeaLevel() or 0
		yourLoad = yourLoad + (load - yourLoad) * 0.05
		s, density = strength(mach, yourLoad), thickness(alt)
		mainView = dist <= CFG.MAX_DISTANCE and (dist >= CFG.COCKPIT_RADIUS or CFG.SHOW_IN_COCKPIT)
		local tas = Export.LoGetTrueAirSpeed and Export.LoGetTrueAirSpeed()
		if tas and mach > 0.3 then   -- the speed of sound here tells how warm the mission is
			warmer = warmer + ((tas / mach) ^ 2 / 401.874 - standardTemperature(alt) - warmer) * 0.02
		end
		local g = geometryOf(name)
		measureCockpit(name, g, c, cam.y)
		size, front, shock0, shock1, outer, halfSpan, te, le = placement(g, true)
	end

	if t >= nextScan or nextScan - t > 1 then lookAround(c, t) end
	local jets = {}
	for id, j in pairs(others) do
		local o = Export.LoGetObjectById(id)
		if o and o.Position then
			jets[#jets + 1] = otherJet(id, j, o, t)
			lla = lla or o.LatLongAlt
		else
			others[id] = nil   -- gone
		end
	end
	if not me and #jets == 0 then return SB.frame(0) end

	lla = lla or {}
	local sunN, sunU, sunE = sunDirection(lla.Lat, lla.Long, t)
	local mirror = CFG.SHOW_IN_MIRRORS and CFG.MIRROR_BRIGHTNESS or 0
	local v = { s, h[1], h[2], h[3], h[4], h[5], h[6],
		c.x, c.y, c.z, cam.x.x, cam.x.y, cam.x.z, cam.y.x, cam.y.y, cam.y.z, cam.z.x, cam.z.y, cam.z.z,
		me and seenAt or t, fov, size, mainView and 1 or 0, mirror, front, shock0, shock1, sunN, sunU, sunE, outer, halfSpan,   -- the vapor's clock: its pose's
		ux, uy, uz, load, density, math.max(CFG.PULSE, 0.001), CFG.DCS_LIGHT and 1 or -1, CFG.SCATTER_TEST and 1 or 0, width, 0, CFG.JET_SHADE and 1 or -1,   -- 0: your jet's id
		CFG.QUALITY, CFG.SHADOW and 1 or -1, CFG.REFLECTION and 1 or -1,
		vel.x or 0, vel.y or 0, vel.z or 0, seenAt,   -- for the DLL to move your jet on to the picture's time
		te, le, CFG.SOFT and 1 or 0,
		t }   -- the newest simulation step seen: the step the picture shows is one of these
	for _, jet in ipairs(jets) do
		for _, x in ipairs(jet) do v[#v + 1] = x end
	end
	SB.frame(unpack(v))
end

local cb = {}

function cb.onSimulationStart()
	readDefaultFov()
	readMissionClock()
	readOptions()
	say(string.format("settings %s: %s, quality %d, thickness %.2f, width %.2f, shadow %s, reflection %s",
		hasOptions and "from Options > Special" or "from this file", CFG.ENABLED and "on" or "off", CFG.QUALITY,
		CFG.DENSITY, CFG.CONE_WIDTH, tostring(CFG.SHADOW), tostring(CFG.REFLECTION)))
	history, seatType, others, nextScan, warmer, yourLoad = {}, nil, {}, 0, 0, 1
	nextStatus = Sim.getRealTime() + 5
end

function cb.onSimulationFrame()
	if not SB then return end
	local ok, err = pcall(sendFrame)
	if not ok and not errored then
		errored = true -- one log line, not one per frame
		say("frame error: " .. tostring(err))
	end
	if nextStatus and Sim.getRealTime() >= nextStatus then
		nextStatus = Sim.getRealTime() + 60
		say(SB.status())
	end
end

function cb.onSimulationStop()
	if SB then SB.frame(0) end
end

package.cpath = package.cpath .. ";" .. DIR .. "?.dll"
local ok, mod = pcall(require, "SonicBoom3D")
if ok and type(mod) == "table" then
	SB = mod
	say("3D cone loaded: " .. SB.status())
else
	say("3D cone not loaded: " .. tostring(mod))
end

Sim.setUserCallbacks(cb)
