-- The Special page's "Cone per aircraft" (the jet... widgets in options.dlg), wired up each time the page opens
-- (optionsDb.lua's callbackOnShowDialog): pick an aircraft, opening on the one you're in (else the one picked last),
-- and set its cone. Its built-in settings (Default) are never changed: moving a slider while they're in use starts
-- a preset of its own, "Custom"; Save as keeps the settings shown under a name of yours. All of it is the plugin
-- option "jets" (see jets.lua), set through Options.Data as a new table each change, so DCS's OK and Cancel keep
-- or undo it like any setting, and the hook draws it as you go.
local ID = "SonicBoom3D"
local PICK = "Pick an aircraft"

local function capital(name)
	return name:sub(1, 1):upper() .. name:sub(2)
end

local function trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

return function(w, JETS, Data)
	local key = nil         -- the aircraft shown (a key of jets.lua), nil until one's picked
	local filling = false   -- the widgets being set to the saved settings, not moved by you

	-- The saved settings, a copy to change, and the parts of it to change.
	local function jets()
		local j = Data.getPlugin(ID, "jets")
		return JETS.copy(type(j) == "table" and j or {})
	end
	local function save(j)
		Data.setPlugin(ID, "jets", j)
	end
	local function presetsOf(j, k)
		j.presets = type(j.presets) == "table" and j.presets or {}
		j.presets[k] = type(j.presets[k]) == "table" and j.presets[k] or {}
		return j.presets[k]
	end
	local function useOf(j)
		j.use = type(j.use) == "table" and j.use or {}
		return j.use
	end

	local sliders, values = {}, {}
	for _, d in ipairs(JETS.SETTINGS) do
		sliders[d.name] = w["jet" .. capital(d.name) .. "Slider"]
		values[d.name] = w["jet" .. capital(d.name) .. "Value"]
		sliders[d.name]:setRange(d.min, d.max)
	end
	local controls = { w.jetPresetList, w.jetResetButton, w.jetDeleteButton, w.jetNameEdit, w.jetSaveAsButton }
	for _, d in ipairs(JETS.SETTINGS) do controls[#controls + 1] = sliders[d.name] end

	-- The aircraft's on/off, presets and settings into the widgets; with none picked, all of them off, and with its
	-- cone switched off, all but the switch.
	local function show()
		filling = true
		w.jetPresetList:clear()
		local j = jets()
		local on = key ~= nil and JETS.on(j, key)
		w.jetOnCheck:setEnabled(key ~= nil)
		w.jetOnCheck:setState(on)
		for _, c in ipairs(controls) do c:setEnabled(on) end
		if key then
			local name, s = JETS.preset(j, key)
			local chosen = w.jetPresetList:newItem(JETS.DEFAULT_PRESET)
			chosen.preset = JETS.DEFAULT_PRESET
			for _, n in ipairs(JETS.presetNames(j, key)) do
				local item = w.jetPresetList:newItem(n)
				item.preset = n
				if n == name then chosen = item end
			end
			w.jetPresetList:selectItem(chosen)
			w.jetDeleteButton:setEnabled(on and name ~= JETS.DEFAULT_PRESET)
			for _, d in ipairs(JETS.SETTINGS) do
				sliders[d.name]:setValue(s[d.name])
				values[d.name]:setText(tostring(s[d.name]))
			end
		else
			w.jetPresetList:setText("")
		end
		filling = false
	end

	-- The aircraft list: every jet in jets.lua by name, Other jets last.
	w.jetAircraftList:clear()
	local items = {}
	for _, k in ipairs(JETS.list()) do
		items[k] = w.jetAircraftList:newItem(JETS.LABEL[k] or k)
		items[k].key = k
	end
	local ok, me = pcall(function() return Export and Export.LoGetSelfData and Export.LoGetSelfData() end)
	local last = jets().last
	key = ok and type(me) == "table" and type(me.Name) == "string" and JETS.keyOf(me.Name)
		or (type(last) == "string" and items[last] and last) or nil
	if key then
		w.jetAircraftList:selectItem(items[key])
	else
		w.jetAircraftList:selectItem(nil)
		w.jetAircraftList:setText(PICK)
	end
	show()

	w.jetAircraftList.onChange = function(self, item)
		if filling or not item or not item.key then return end
		key = item.key
		local j = jets()
		j.last = key
		save(j)
		show()
	end

	w.jetOnCheck.onChange = function(self)
		if filling or not key then return end
		local j = jets()
		j.off = type(j.off) == "table" and j.off or {}
		j.off[key] = not self:getState() or nil
		save(j)
		show()
	end

	w.jetPresetList.onChange = function(self, item)
		if filling or not key or not item then return end
		local j = jets()
		useOf(j)[key] = item.preset ~= JETS.DEFAULT_PRESET and item.preset or nil
		save(j)
		show()
	end

	for _, d in ipairs(JETS.SETTINGS) do
		sliders[d.name].onChange = function(self)
			if filling or not key then return end
			local v = self:getValue()
			values[d.name]:setText(tostring(v))
			local j = jets()
			local name, s = JETS.preset(j, key)
			local mine = presetsOf(j, key)
			local fresh = name == JETS.DEFAULT_PRESET
			if fresh then   -- the built-in settings stay as they are: a preset of its own, the first free "Custom"
				name = "Custom"
				for n = 2, math.huge do
					if not mine[name] then break end
					name = "Custom " .. n
				end
				mine[name] = s
				useOf(j)[key] = name
			end
			mine[name][d.name] = v
			save(j)
			if fresh then show() end
		end
	end

	w.jetResetButton.onChange = function()
		if not key then return end
		local j = jets()
		useOf(j)[key] = nil
		save(j)
		show()
	end

	w.jetDeleteButton.onChange = function()
		if not key then return end
		local j = jets()
		local name = JETS.preset(j, key)
		if name == JETS.DEFAULT_PRESET then return end
		presetsOf(j, key)[name] = nil
		useOf(j)[key] = nil
		save(j)
		show()
	end

	w.jetSaveAsButton.onChange = function()
		local name = trim(w.jetNameEdit:getText())
		if not key or name == "" or name == JETS.DEFAULT_PRESET then return end
		local j = jets()
		local _, s = JETS.preset(j, key)
		presetsOf(j, key)[name] = s
		useOf(j)[key] = name
		save(j)
		w.jetNameEdit:setText("")
		show()
	end
end
