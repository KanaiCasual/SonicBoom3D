-- The Mach readout's window (Options > Special > SonicBoom3D, Mach readout): the hook's lines of text over the
-- picture, in DCS's own GUI. A dark see-through box, DCS's monospace font so its columns line up. Drag it anywhere
-- by any part of it: it stays where you leave it (Saved Games\DCS\Config\SonicBoom3D readout.lua), kept on screen.
-- The hook (Scripts\Hooks\SonicBoom3D.lua, showReadout) sends its lines four times a second.
local DialogLoader = require("DialogLoader")
local dxgui = require("dxgui")
local lfs = require("lfs")

local M = {}
local LINES, W, LINE_H, PAD = 12, 580, 17, 8
local CURSOR_MOVE = 37   -- DCS's move cursor (Scripts\UI\ViewportEditor.lua)
local PLACE = lfs.writedir() .. "Config\\SonicBoom3D readout.lua"

local win, rows, drag

-- Where you left it, else the top left.
local function saved()
	local f = io.open(PLACE, "r")
	local s = f and f:read("*a") or ""
	if f then f:close() end
	return tonumber(s:match("x%s*=%s*(%-?%d+)")) or 20, tonumber(s:match("y%s*=%s*(%-?%d+)")) or 90
end

local function save()
	local x, y = win:getPosition()
	local f = io.open(PLACE, "w")
	if f then
		f:write(string.format("-- Where SonicBoom3D's Mach readout sits on screen (pixels from the top left). Delete this file for its first place.\nx = %d\ny = %d\n", x, y))
		f:close()
	end
end

local function keepOnScreen(x, y)
	local sw, sh = dxgui.GetScreenSize()
	local ww, wh = win:getSize()
	win:setPosition(math.max(0, math.min(x, sw - ww)), math.max(0, math.min(y, sh - wh)))
end

-- Press and drag on any line: the box follows (screen coordinates, as DCS's own drag code has them).
local function draggable(row)
	row:addMouseEnterCallback(function() if not drag then win:pushMouseCursor(CURSOR_MOVE) end end)
	row:addMouseLeaveCallback(function() if not drag then win:popMouseCursor() end end)
	row:addMouseDownCallback(function(self, x, y, button)
		if button ~= 1 then return end
		local wx, wy = win:getPosition()
		drag = { x = x, y = y, wx = wx, wy = wy }
		self:captureMouse()
	end)
	row:addMouseMoveCallback(function(self, x, y)
		if drag then keepOnScreen(drag.wx + x - drag.x, drag.wy + y - drag.y) end
	end)
	row:addMouseUpCallback(function(self)
		if not drag then return end
		self:releaseMouse()
		drag = nil
		win:popMouseCursor()
		save()
	end)
end

local function create()
	local text = { params = { name = "staticSkin" }, states = { released = { [1] = {
		bkg = { center_center = "0x00000000" },
		text = { color = "0xe8e8e8ff", font = "DejaVuLGCSansMono.ttf", fontSize = 12,
		         horzAlign = { type = "min" }, vertAlign = { type = "middle" } },
	} } } }
	local children = {}
	for i = 1, LINES do
		children["line" .. i] = { type = "Static", skin = text,
			params = { bounds = { x = PAD, y = PAD + (i - 1) * LINE_H, w = W - 2 * PAD, h = LINE_H },
			           enabled = true, visible = true, text = "" } }
	end
	local x, y = saved()
	win = DialogLoader.spawnWidget("dialog", {
		type = "Window",
		params = { bounds = { [1] = { x = x, y = y, w = W, h = 2 * PAD + LINES * LINE_H } }, draggable = false,
		           enabled = true, hasCursor = true, lockFlow = false, modal = false, offscreen = false,
		           resizable = false, zOrder = 112, text = "" },
		skin = { params = { headerHeight = 0, name = "windowSkin" },
		         states = { released = { [1] = { bkg = { center_center = "0x000000b0" } } } } },
		children = children,
	})
	rows = {}
	for i = 1, LINES do
		rows[i] = win["line" .. i]
		draggable(rows[i])
	end
end

-- Shows these lines (the first LINES of them), the box fitted to them.
function M.show(lines)
	if not win then create() end
	local n = math.min(#lines, LINES)
	for i = 1, LINES do rows[i]:setText(lines[i] or "") end
	local _, wh = win:getSize()
	if wh ~= 2 * PAD + n * LINE_H then
		win:setSize(W, 2 * PAD + n * LINE_H)
		keepOnScreen(win:getPosition())   -- sized to its lines: still all on screen (and if the screen got smaller)
	end
	if not win:getVisible() then win:setVisible(true) end
end

function M.hide()
	if win and win:getVisible() then win:setVisible(false) end
end

return M
