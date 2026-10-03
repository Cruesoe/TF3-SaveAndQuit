local builtin = ug_require "::/gui/main/builtin.lua" as Builtin
local engine_react_util = ug_require "::/gui/main/engine_react_util.tl" as EngineReactUtil
local main_mod_button_area = ug_require "::/gui/main/main_mod_button_area.tl" as MainModButtonArea
local react = ug_require "::/gui/main/react.lua" as React

-- Save name used when the game has never been saved
local FALLBACK_NAME = "save_and_quit"

-- Mod button bar button: saves under the current save name (as quicksave does), then quits to the desktop
local SaveAndQuitButton = react.RegisterPluginRecipe(main_mod_button_area.MainModButtonAreaExtension, "CruesoeSaveAndQuitButton", function() : TreeNodeId
	local quittingState = react.useState(false) as ReactStateT<boolean>
	local savingState = engine_react_util.useStepState(function() : boolean
		return api.gui.game.isSavegameUIBlocked()
	end) as ReactStateT<boolean>

	-- A plugin recipe must return a layout
	return builtin.BoxLayout{
		children = {
			builtin.Button{
				meta = {
					tooltip = _("cruesoe_save_and_quit_tooltip"),
					enabled = not quittingState:old() and not savingState:old(),
				},
				content = builtin.ImageView{
					path = "::/gui/main/icons/symbol_save_floppy_42.tga",
					scaling = builtin.type.ImageViewScaling.AutoFit,
				},
				onClick = function()
					if quittingState:old() then return end
					quittingState:set(true)
					local name = api.gui.game.getDefaultSavegameId()
					if not name or name == "" then name = FALLBACK_NAME end
					debugPrint("[save_and_quit] saving " .. name)
					app.saveGame(name, function()
						debugPrint("[save_and_quit] saved " .. name .. "; quitting")
						app.quit(true)
					end, api.gui.game.isMapEditor(), true)
				end,
			},
		},
	}
end)

return {
	SaveAndQuitButton = SaveAndQuitButton,
}
