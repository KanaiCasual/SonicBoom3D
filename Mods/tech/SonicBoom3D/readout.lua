-- The Mach readout's window (Options > Special > SonicBoom3D, Mach readout): the hook's lines of text over the
-- picture, at the top left, in DCS's own GUI. A dark see-through box, DCS's monospace font so its columns line up;
-- it takes no mouse. The hook (Scripts\Hooks\SonicBoom3D.lua, showReadout) sends its lines four times a second.
local DialogLoader = require("DialogLoader")

local M = {}
local LINES, W, LINE_H, PAD, X, Y = 12, 580, 17, 8, 20, 90

local win, rows

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
	win = DialogLoader.spawnWidget("dialog", {
		type = "Window",
		params = { bounds = { [1] = { x = X, y = Y, w = W, h = 2 * PAD + LINES * LINE_H } }, draggable = false,
		           enabled = true, hasCursor = false, lockFlow = false, modal = false, offscreen = false,
		           resizable = false, zOrder = 112, text = "" },
		skin = { params = { headerHeight = 0, name = "windowSkin" },
		         states = { released = { [1] = { bkg = { center_center = "0x000000b0" } } } } },
		children = children,
	})
	rows = {}
	for i = 1, LINES do rows[i] = win["line" .. i] end
end

-- Shows these lines (the first LINES of them), the box fitted to them.
function M.show(lines)
	if not win then create() end
	local n = math.min(#lines, LINES)
	for i = 1, LINES do rows[i]:setText(lines[i] or "") end
	win:setBounds(X, Y, W, 2 * PAD + n * LINE_H)
	if not win:getVisible() then win:setVisible(true) end
end

function M.hide()
	if win and win:getVisible() then win:setVisible(false) end
end

return M
