-- SonicBoom3D's update check, run by the hook (Scripts\Hooks\SonicBoom3D.lua) as DCS starts: the DLL asks GitHub
-- for the mod's latest release, off DCS's threads; if it's newer than this one (entry.lua's version), DCS's own
-- message window says so in the main menu, with the boom of Sounds\update.wav, never in a mission:
--   Update now          the DLL downloads it and puts it in place of this one, for DCS's next start
--   Open download page  its page on GitHub, in your browser, to download it yourself
--   Skip <version>      not asked about that version again (Saved Games\DCS\Config\SonicBoom3D update.lua)
--   Remind me later     asked again next time DCS starts (Esc too)
local M = {}

M.API = "https://api.github.com/repos/KanaiCasual/SonicBoom3D/releases/latest"
M.SKIP_FILE = "Config\\SonicBoom3D update.lua"
M.WAIT = 3            -- seconds of the main menu before the popup, so it comes up over it, not the loading screen
M.inMission = false   -- set by the hook: no popup over a mission; it waits for the main menu

local CAPTION = "SonicBoom3D update"

local function read(path)
	local f = io.open(path, "rb")
	if not f then return nil end
	local s = f:read("*a")
	f:close()
	return s
end

-- The installed version (entry.lua's).
function M.version(writedir)
	local s = read(writedir .. "Mods\\tech\\SonicBoom3D\\entry.lua")
	return s and s:match('version%s*=%s*"([^"]+)"')
end

-- The version you chose to skip, if any.
function M.skipped(writedir)
	local s = read(writedir .. M.SKIP_FILE)
	return s and s:match('skip%s*=%s*"([^"]+)"')
end

local function skip(writedir, version)
	local f = io.open(writedir .. M.SKIP_FILE, "w")
	if f then
		f:write(string.format("-- SonicBoom3D's update check doesn't ask about this version again. Delete this file to be asked.\nskip = %q\n", version))
		f:close()
	end
end

-- Starts the check, and the popup in the main menu once there's an answer. SB: the DLL; say: a line into dcs.log.
function M.start(SB, writedir, say)
	local current = M.version(writedir)
	if not (current and SB.updateCheck) then return end
	local UpdateManager, MsgWindow = require("UpdateManager"), require("MsgWindow")
	SB.updateCheck(current, M.API)
	local ready   -- when the answer was in and we were in the main menu

	local function inMenu()
		if M.inMission then ready = nil return false end
		ready = ready or os.time()
		return os.time() - ready >= M.WAIT
	end

	local function installing()
		if not inMenu() then return false end
		local state, latest, page, _, why = SB.updateState()
		if state == "downloading" then return false end
		if state == "installed" then
			say("update: " .. latest .. " installed")
			MsgWindow.info(string.format("SonicBoom3D %s is installed.\n\nRestart DCS to use it.", latest), CAPTION, "OK"):show()
		else
			say("update: couldn't install " .. latest .. ": " .. tostring(why))
			local OPEN = "Open download page"
			local h = MsgWindow.warning(string.format("SonicBoom3D couldn't update itself:\n%s\n\nYou can download %s from its page instead.",
				tostring(why), latest), CAPTION, OPEN, "Close")
			function h:onChange(button) if button == OPEN then SB.open(page) end end
			h:show()
		end
		return true
	end

	local function ask(latest, page)
		local NOW, PAGE, SKIP, LATER = "Update now", "Open download page", "Skip " .. latest, "Remind me later"
		SB.play(writedir .. "Mods\\tech\\SonicBoom3D\\Sounds\\update.wav")
		local h = MsgWindow.info(string.format("A new version of SonicBoom3D is available.\n\n%s  \226\134\146  %s", current, latest),
			CAPTION, NOW, PAGE, SKIP, LATER)
		function h:onChange(button)
			say("update: " .. button)
			if button == NOW then
				ready = nil
				SB.updateInstall(writedir)
				UpdateManager.add(installing)
			elseif button == PAGE then
				SB.open(page)
			elseif button == SKIP then
				skip(writedir, latest)
			end
		end
		h:show()
	end

	UpdateManager.add(function()
		local state, latest, page, _, why = SB.updateState()
		if state == "checking" then return false end
		if state ~= "available" then
			say(state == "failed" and "update check: " .. tostring(why) or "update check: " .. current .. " is the latest")
			return true
		end
		if latest == M.skipped(writedir) then
			say("update check: " .. latest .. " is out, skipped")
			return true
		end
		if not inMenu() then return false end
		say("update check: " .. latest .. " is out (this is " .. current .. ")")
		ask(latest, page)
		return true
	end)
end

return M
