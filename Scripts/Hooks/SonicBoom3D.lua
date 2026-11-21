-- SonicBoom3D: a vapor cone around your jet near Mach 1, and around the other jets near you, drawn into
-- DCS's own picture: in outside views, from the cockpit (behind the canopy frame) and in the cockpit
-- mirrors. Only you see it. Works in single player, and as a client on a server that allows own-aircraft
-- export (your jet) and object export (the others).
-- Lives in Saved Games, so IC stays clean. The rest of it is the mod Saved Games\DCS\Mods\tech\SonicBoom3D: the
-- DLL that draws it (bin), its icon in the main menu, and its settings page, Options > Special > SonicBoom3D.

local Sim = Sim or DCS -- DCS 2.9.31 renamed DCS.* to Sim.*

-- The settings below are in feet and nautical miles; DCS works in metres, so they're turned into metres where used.
local FT, NM = 0.3048, 1852   -- metres in a foot, in a nautical mile

-- The settings. Those on the Special page (the ones marked) take the place of these, live, in flight too;
-- these are what's used before they're changed there.
local CFG = {
	ENABLED = true,        -- page: the cone at all
	QUALITY = 3,           -- page: how fine the steps through the vapor are, 1 low, 2 medium, 3 high, 4 ultra: finer costs more GPU time
	MACH_ON_START = 0.94,  -- the vapor starts flashing in from here...
	MACH_ON_FULL = 0.97,   -- ...is solid, always there, from here...
	MACH_OFF_START = 1.01, -- ...starts to break up here...
	MACH_OFF_END = 1.03,   -- ...and is gone here (real vapor cones are mostly just below Mach 1)
	G_EARLIER = 0.02,      -- G brings it in earlier, pulling or pushing: this much Mach per G over 1 either way, up to 4 G's worth
	ALT_FULL_FT = 10000,   -- full strength below this altitude (ft above sea level)...
	ALT_FADE_FT = 40000,   -- ...thinning to ALT_MIN by this one, where the air is dry
	ALT_MIN = 0.15,
	DENSITY = 2,           -- how thick the vapor looks: 1 = thinner and more see-through, 4 = twice as thick (each jet's Thickness on the page scales it)
	CONE_WIDTH = 1,        -- how far out the cone's rim reaches: 1 = 1.2 half-spans, as in photos (each jet's Width on the page scales it)
	JET_SHADE = true,      -- page: the jet's wing and fuselage shade its vapor from the sun
	SHADOW = true,         -- page: its shadow on the ground, the sea and the jet
	REFLECTION = true,     -- page: its reflection in water, as DCS reflects jets
	PULSE = 1,             -- how much it flashes forming and breaking up, and breathes when solid: 0 = steady, 1 = like real footage (each jet's Flashing on the page scales it)
	SOFTNESS = 0,          -- page: from the crisp cone (0) to the softer, a smooth mist with soft edges as the JF-17 draws its own (1); between, a blend
	INSTABILITY = 0,       -- page: how unstable the formed vapor is, as in footage: parts of the cone drop out for a moment, now and then all of it (0 = never, 1 = most)
	SHOW_IN_COCKPIT = true, -- page
	COCKPIT_RADIUS_FT = 26, -- camera this close to your jet (ft) counts as the cockpit view
	SHOW_IN_MIRRORS = true, -- page
	MIRROR_BRIGHTNESS = 1, -- the vapor's brightness in the mirrors (DCS renders them before tonemapping)
	MAX_DISTANCE_NM = 1.6, -- no cone when the camera is further than this from your jet (nm)
	OTHER_JETS = 25,       -- page: vapor on this many of the nearest other jets too, 0 = only yours
	OTHER_DISTANCE_NM = 4.3, -- ...within this far of the camera (nm)
	DCS_LIGHT = true,      -- draw it into DCS's own HDR picture, lit with DCS's light; false = onto the finished picture, lit its own way
	SCATTER_TEST = false,  -- true: much fuller lighting, to see how it could look; very slow (many times the GPU time)
	TEST_MODE = false,     -- page: show the cone at any speed and height, to check it lines up
	ADVANCED_LOGGING = false, -- page: more in dcs.log for bug reports: a status line every 10 s, a line for each run of
	                       -- frames DCS showed without the vapor in its view, and the first three of those captured (capture-N.txt in the DLL's folder)
	MACH_READOUT = false,  -- page: on screen, each jet's Mach as the cone goes by it (yours also as DCS has it), and every 10 s in dcs.log
	UPDATE_CHECK = true,   -- as DCS starts, ask GitHub whether there's a newer SonicBoom3D, and if so say so in the main menu
}

-- The Special page's settings (Mods\tech\SonicBoom3D\Options): each its name there, the setting above it
-- takes the place of, and how (the sliders are in percent).
local OPTIONS = {
	{ "enabled", "ENABLED" }, { "quality", "QUALITY" },
	{ "softness", "SOFTNESS", function(v) return v / 100 end },
	{ "instability", "INSTABILITY", function(v) return v / 100 end },
	{ "jetShade", "JET_SHADE" }, { "shadow", "SHADOW" }, { "reflection", "REFLECTION" },
	{ "cockpit", "SHOW_IN_COCKPIT" }, { "mirrors", "SHOW_IN_MIRRORS" }, { "otherJets", "OTHER_JETS" },
	{ "testMode", "TEST_MODE" }, { "advancedLogging", "ADVANCED_LOGGING" }, { "machReadout", "MACH_READOUT" },
}
-- And the cone's settings per aircraft (the page's "Cone per aircraft", its "jets"; see jets.lua): as read, and
-- each jet's worked out from them, kept until they change.
local savedJets, jetCache = nil, {}
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
	local jets = nil
	if hasOptions then
		local ok, v = pcall(OptionsData.getPlugin, "SonicBoom3D", "jets")
		if ok and type(v) == "table" then jets = v end
	end
	if jets ~= savedJets then savedJets, jetCache = jets, {} end
end

-- Jets whose module draws its own vapor cone, when a person flies them: no second one on top. An AI one
-- (its module isn't running) gets this cone. Delete a line to get this cone on it always.
local OWN_VAPOR = { ["JF-17"] = true, ["M-2000C"] = true }

local lfs = require("lfs")
local DIR = lfs.writedir() .. "Mods\\tech\\SonicBoom3D\\bin\\"
-- Each jet's shape, and the cone's settings per jet: the mod's jets.lua, which the Special page shares.
local JETS = dofile(lfs.writedir() .. "Mods\\tech\\SonicBoom3D\\jets.lua")

-- A jet's cone settings, as set on the page for its type: move and front (ft), the rest in percent.
local function settingsFor(name)
	local key = JETS.keyOf(name)
	local s = jetCache[key]
	if not s then
		s = JETS.settings(savedJets, key)
		jetCache[key] = s
	end
	return s
end

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
	local early = CFG.G_EARLIER * math.min(math.max(math.abs(load) - 1, 0), 4)
	return ramp(mach, CFG.MACH_ON_START - early, CFG.MACH_ON_FULL - early) * (1 - ramp(mach, CFG.MACH_OFF_START, CFG.MACH_OFF_END))
end

-- How thick it is at this altitude: thinner high up, where the air is dry. Thinner, not flashing.
local function thickness(alt)
	if CFG.TEST_MODE then return CFG.DENSITY end
	return CFG.DENSITY * (1 - (1 - CFG.ALT_MIN) * ramp(alt, CFG.ALT_FULL_FT * FT, CFG.ALT_FADE_FT * FT))
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
-- The mission's air against DCS's standard day (K): its weather's temperature at sea level over 15 C. DCS keeps
-- the whole atmosphere that much warmer or colder (an F-16's sensors had a 20 C mission 5 K warm at every height,
-- 500 to 40,000 ft), but its own Mach (LoGetMachNumber) is TAS over a standard day's speed of sound all the same;
-- the jet's HUD, as a real one does, gives it for the air the jet's in (tools/hud_logger.lua). The cone goes by that.
local warmer = 0

local function standardTemperature(alt)
	return 288.15 - 0.0065 * math.min(alt, 11000)
end

-- Mach in the mission's air, from DCS's (a standard day's) at this height.
local function realMach(dcsMach, alt)
	local T = standardTemperature(alt)
	return dcsMach * math.sqrt(T / math.max(T + warmer, 150))
end

local function readMission()
	local ok, cur = pcall(Sim.getCurrentMission)
	local m = ok and type(cur) == "table" and cur.mission
	if m and m.date and m.start_time then
		missionClock = { m.date.Year, m.date.Month, m.date.Day, m.start_time, UTC_OFFSET[m.theatre or ""] }
	end
	local season = m and type(m.weather) == "table" and type(m.weather.season) == "table" and m.weather.season
	warmer = season and tonumber(season.temperature) and season.temperature - 15 or 0
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
		if off < 1.5 and math.abs(ahead) < CFG.COCKPIT_RADIUS_FT * FT then inside = true end
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
	return JETS.geometry(JETS.keyOf(name))
end

-- Other jets. DCS tells Lua only where they are and which way they point, so, as Tacview does, their
-- speed and G come from their flight path, smoothed over a few tenths of a second. Their airspeed is
-- that less the wind where they are, their Mach that over the speed of sound at their height: DCS's
-- standard atmosphere, as much warmer or colder as the mission's weather has it.
local others, nextScan = {}, 0   -- jets followed, by id; when to look for jets again
local yourLoad = 1   -- your G, smoothed over a few tenths of a second like the other jets'

-- Every half second: the nearest jets to the camera, keeping what's known of those already followed.
local function lookAround(c, t)
	nextScan = t + 0.5
	local near, found = {}, {}
	if CFG.OTHER_JETS > 0 and Export.LoIsObjectExportAllowed and Export.LoIsObjectExportAllowed() then
		local mine = Export.LoGetPlayerPlaneId and Export.LoGetPlayerPlaneId()
		for id, o in pairs(Export.LoGetWorldObjects() or {}) do
			local p, kind = o.Position, o.Type
			local own = OWN_VAPOR[o.Name or ""] and o.Flags and o.Flags.Human
				or not JETS.on(savedJets, JETS.keyOf(o.Name or ""))   -- or its type's cone switched off on the page
			if id ~= mine and p and kind and kind.level1 == 1 and kind.level2 == 1 and not own then
				local d2 = (p.x - c.x) ^ 2 + (p.y - c.y) ^ 2 + (p.z - c.z) ^ 2
				if d2 < (CFG.OTHER_DISTANCE_NM * NM) ^ 2 then near[#near + 1] = { id, d2 } end
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
	local set = settingsFor(o.Name or "")
	-- what was worked out, for the Mach readout
	j.name, j.mach, j.air, j.load, j.alt, j.strength = o.Name, mach, air, load, p.y, strength(mach, load)
	j.ground, j.wind = math.sqrt(j.v[1] ^ 2 + j.v[2] ^ 2 + j.v[3] ^ 2), math.sqrt((wx or 0) ^ 2 + (wy or 0) ^ 2 + (wz or 0) ^ 2)
	return { j.strength, h[1], h[2], h[3], h[4], h[5], h[6], h[7] + id % 97 * 7.3,   -- each breathing on its own, timed from its pose
		size, 1, front + set.front * FT, shock0, shock1, outer, halfSpan, ux, uy, uz, load, thickness(p.y) * set.thickness / 100, id,
		j.v[1], j.v[2], j.v[3], h[7],   -- its velocity, and when it was where it is, for the DLL to move it on to the picture's time
		CFG.CONE_WIDTH * set.width / 100, te, le,
		math.max(CFG.PULSE * set.pulse / 100, 0.001), set.top / 100, set.bottom / 100, set.move * FT }   -- as set for its type
end

-- The Mach readout (the page's, for bug reports): each jet's Mach as the cone goes by it, four times a second on
-- screen (Mods\tech\SonicBoom3D\readout.lua) and every 10 s in dcs.log. Yours twice: as DCS has it, which your cone
-- goes by, and worked out from your flight path the way every other jet's is, so if that way is wrong it shows.
local READOUT, readoutAt, readoutLogAt, readoutFailed, yourTrack = nil, 0, 0, false, { history = {} }
local KT = 1.943844   -- knots in a metre a second

local function thousands(x)
	local s = string.format("%d", math.floor(x + 0.5))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^(%-?),", "%1"))
end

local function readoutRow(label, mach, cone, air, ground, wind, alt, load)
	local kt = function(v) return v and string.format("%.0f kt", v * KT) or "-" end
	return string.format("%-16s %5.2f %4.0f%% %8s %8s %7s %10s %5.1f", label:sub(1, 16), mach, cone * 100,
		kt(air), kt(ground), kt(wind), thousands(alt / FT) .. " ft", load)
end

local function hideReadout()
	if READOUT then READOUT.hide() end
end

-- you: your jet as DCS has it (nil: not in one); c: the camera, the other jets listed nearest it first, 8 at most.
local function showReadout(t, c, you)
	if t < readoutAt and readoutAt - t <= 0.25 then return end   -- 4 a second (and at once if the clock went back)
	readoutAt = t + 0.25
	local lines = {
		string.format("SonicBoom3D Mach readout     the mission's air %+.0f \194\176C against a standard day", warmer),
		string.format("%-16s %5s %5s %8s %8s %7s %10s %5s", "", "Mach", "cone", "airspeed", "ground", "wind", "altitude", "G"),
	}
	if you then
		-- DCS's Mach in the mission's air: what your cone goes by, and your HUD shows
		lines[#lines + 1] = readoutRow("You", you.mach, you.strength, you.tas, you.ground, nil, you.alt, you.load)
		-- What your HUD draws, when the dev tool tools\hud_logger.lua runs in DCS's export state and hands it over
		-- through the DLL (the hook can't read cockpit values itself): "" when it doesn't.
		local hud = SB.hud and SB.hud() or ""
		local n = tonumber(hud:match("%d*%.%d+") or "")
		if n then lines[#lines + 1] = string.format("%-16s %5.2f", "You, HUD", n) end
		if yourTrack.mach then
			local j = yourTrack
			lines[#lines + 1] = readoutRow("You, worked out", j.mach, j.strength, j.air, j.ground, j.wind, j.alt, j.load)
		end
	end
	local near = {}
	for id, j in pairs(others) do
		local h = j.history[1]
		if j.mach and h then near[#near + 1] = { j, (h[1] - c.x) ^ 2 + (h[2] - c.y) ^ 2 + (h[3] - c.z) ^ 2, id } end
	end
	table.sort(near, function(a, b) return a[2] < b[2] end)
	for i = 1, math.min(#near, 8) do
		local j = near[i][1]
		lines[#lines + 1] = readoutRow(j.name or ("#" .. near[i][3]), j.mach, j.strength, j.air, j.ground, j.wind, j.alt, j.load)
	end
	READOUT = READOUT or dofile(lfs.writedir() .. "Mods\\tech\\SonicBoom3D\\readout.lua")
	READOUT.show(lines)
	if t >= readoutLogAt or readoutLogAt - t > 10 then
		readoutLogAt = t + 10
		for _, line in ipairs(lines) do say("readout: " .. line) end
	end
end

local function sendFrame()
	readOptions()
	SB.logging(CFG.ADVANCED_LOGGING and 1 or 0)
	if not (CFG.ENABLED and CFG.MACH_READOUT) then hideReadout() end
	if not CFG.ENABLED then return SB.frame(0) end
	local cam = Export.LoGetCameraPosition()
	if not cam then return SB.frame(0) end
	local c, t = cam.p, Sim.getModelTime()
	local me = Export.LoIsOwnshipExportAllowed() and Export.LoGetSelfData()
	if not (me and me.Position) or OWN_VAPOR[me.Name or ""] or not JETS.on(savedJets, JETS.keyOf(me.Name or "")) then me = nil end

	-- your jet as the picture shows it; its nose and up in DCS world axes (x north, y up, z east)
	local s, h, size, mainView, front, shock0, shock1, outer, halfSpan = 0, { 0, 0, 0, 0, 0, 0 }, 0, false, 0, 0, 0, 0, 0
	local width, te, le = CFG.CONE_WIDTH, 0, 0
	local pulse, top, bottom, move = CFG.PULSE, 1, 1, 0   -- and as set on the page for your jet's type
	local ux, uy, uz, load, density, lla = 0, 0, 0, 1, CFG.DENSITY, me and me.LatLongAlt
	local vel, seenAt = { x = 0, y = 0, z = 0 }, 0   -- your jet's velocity, and when it was where it's sent
	local you   -- for the Mach readout
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
		local alt = Export.LoGetAltitudeAboveSeaLevel() or 0
		local mach = realMach(Export.LoGetMachNumber() or 0, alt)   -- in the mission's air, as your HUD has it
		yourLoad = yourLoad + (load - yourLoad) * 0.05
		s, density = strength(mach, yourLoad), thickness(alt)
		mainView = dist <= CFG.MAX_DISTANCE_NM * NM and (dist >= CFG.COCKPIT_RADIUS_FT * FT or CFG.SHOW_IN_COCKPIT)
		local tas = Export.LoGetTrueAirSpeed and Export.LoGetTrueAirSpeed()
		if CFG.MACH_READOUT then
			you = { mach = mach, tas = tas, alt = alt, strength = s, load = yourLoad,
			        ground = math.sqrt((vel.x or 0) ^ 2 + (vel.y or 0) ^ 2 + (vel.z or 0) ^ 2) }
			otherJet(0, yourTrack, me, t)   -- and worked out as every other jet's is
		end
		local g = geometryOf(name)
		measureCockpit(name, g, c, cam.y)
		size, front, shock0, shock1, outer, halfSpan, te, le = placement(g, true)
		local set = settingsFor(name)
		front, density, width = front + set.front * FT, density * set.thickness / 100, width * set.width / 100
		pulse, top, bottom, move = pulse * set.pulse / 100, set.top / 100, set.bottom / 100, set.move * FT
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
	if CFG.MACH_READOUT then
		local ok, err = pcall(showReadout, t, c, you)
		if not ok and not readoutFailed then
			readoutFailed = true -- one log line, not one per frame
			say("Mach readout: " .. tostring(err))
		end
	end
	if not me and #jets == 0 then return SB.frame(0) end

	lla = lla or {}
	local sunN, sunU, sunE = sunDirection(lla.Lat, lla.Long, t)
	local mirror = CFG.SHOW_IN_MIRRORS and CFG.MIRROR_BRIGHTNESS or 0
	local v = { s, h[1], h[2], h[3], h[4], h[5], h[6],
		c.x, c.y, c.z, cam.x.x, cam.x.y, cam.x.z, cam.y.x, cam.y.y, cam.y.z, cam.z.x, cam.z.y, cam.z.z,
		me and seenAt or t, fov, size, mainView and 1 or 0, mirror, front, shock0, shock1, sunN, sunU, sunE, outer, halfSpan,   -- the vapor's clock: its pose's
		ux, uy, uz, yourLoad, density, math.max(pulse, 0.001), CFG.DCS_LIGHT and 1 or -1, CFG.SCATTER_TEST and 1 or 0, width, 0, CFG.JET_SHADE and 1 or -1,   -- G smoothed, as it shapes the cone; 0: your jet's id
		CFG.QUALITY, CFG.SHADOW and 1 or -1, CFG.REFLECTION and 1 or -1,
		vel.x or 0, vel.y or 0, vel.z or 0, seenAt,   -- for the DLL to move your jet on to the picture's time
		te, le, CFG.SOFTNESS,
		t,    -- the newest simulation step seen: the step the picture shows is one of these
		top, bottom, move,
		CFG.INSTABILITY }   -- for every jet, as the air is the same
	for _, jet in ipairs(jets) do
		for _, x in ipairs(jet) do v[#v + 1] = x end
	end
	SB.frame(unpack(v))
end

local cb = {}
-- The update check (Mods\tech\SonicBoom3D\update.lua), started below once the DLL is loaded.
local UPDATE

function cb.onSimulationStart()
	if UPDATE then UPDATE.inMission = true end
	readDefaultFov()
	readMission()
	readOptions()
	local custom = 0
	for _ in pairs(type(savedJets) == "table" and type(savedJets.use) == "table" and savedJets.use or {}) do custom = custom + 1 end
	say(string.format("settings %s: %s, quality %d, softness %.2f, shadow %s, reflection %s, advanced logging %s, own presets in use for %d aircraft",
		hasOptions and "from Options > Special" or "from this file", CFG.ENABLED and "on" or "off", CFG.QUALITY,
		CFG.SOFTNESS, tostring(CFG.SHADOW), tostring(CFG.REFLECTION), CFG.ADVANCED_LOGGING and "on" or "off", custom))
	history, seatType, others, nextScan, yourLoad = {}, nil, {}, 0, 1
	say(string.format("the mission's air: %+.0f K against a standard day", warmer))
	nextStatus = Sim.getRealTime() + 5
end

function cb.onSimulationFrame()
	if UPDATE then   -- the update check's answer and popup: this runs in the main menu too
		local ok, err = pcall(UPDATE.tick)
		if not ok then
			UPDATE = nil -- one log line, then it's left alone
			say("update check: " .. tostring(err))
		end
	end
	if not SB then return end
	local ok, err = pcall(sendFrame)
	if not ok and not errored then
		errored = true -- one log line, not one per frame
		say("frame error: " .. tostring(err))
	end
	if CFG.ADVANCED_LOGGING then
		for line in SB.events():gmatch("[^\n]+") do say(line) end
	end
	if nextStatus and Sim.getRealTime() >= nextStatus then
		nextStatus = Sim.getRealTime() + (CFG.ADVANCED_LOGGING and 10 or 60)
		say(SB.status())
	end
end

function cb.onSimulationStop()
	if SB then SB.frame(0) end
	if UPDATE then UPDATE.inMission = false end
	pcall(hideReadout)
end

package.cpath = package.cpath .. ";" .. DIR .. "?.dll"
local ok, mod = pcall(require, "SonicBoom3D")
if ok and type(mod) == "table" then
	SB = mod
	say("3D cone loaded: " .. SB.status())
	local started, err = pcall(function()   -- whatever happens to it, never the cone
		if not CFG.UPDATE_CHECK then return end
		UPDATE = dofile(lfs.writedir() .. "Mods\\tech\\SonicBoom3D\\update.lua")
		UPDATE.start(SB, lfs.writedir(), say, Sim.getRealTime)
	end)
	if not started then say("update check: " .. tostring(err)) end
else
	say("3D cone not loaded: " .. tostring(mod))
end

Sim.setUserCallbacks(cb)
