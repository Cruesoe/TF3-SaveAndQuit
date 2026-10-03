local ssu = require "::/gui/main/stylesheetutil.lua"

function data()
	local result = {}
	local a = ssu.makeAdder(result)

	-- Same size as the layer button and the other mod buttons (ToggleButton ignores an inline stylesheet)
	a("#cruesoe-save-and-quit.button", {
		size = { 32, 32 },
		padding = { 4, 4, 4, 4 },
		margin = { 1, 1, 1, 1 },
	})

	return result
end
