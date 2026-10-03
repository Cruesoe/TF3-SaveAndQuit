local builtin = ug_require "::/gui/main/builtin.lua" as Builtin
local dialog_react_util = ug_require "::/gui/menu/dialog_react_util.tl" as DialogReactUtil
local engine_react_util = ug_require "::/gui/main/engine_react_util.tl" as EngineReactUtil
local lang_util = ug_require "::/scripts/lang_util.tl" as LangUtil
local main_mod_button_area = ug_require "::/gui/main/main_mod_button_area.tl" as MainModButtonArea
local react = ug_require "::/gui/main/react.lua" as React

-- Save name used when the game has never been saved
local FALLBACK_NAME = "save_and_quit"

local function saveName() : string
	local name = api.gui.game.getDefaultSavegameId()
	if not name or name == "" then return FALLBACK_NAME end
	return name
end

-- Saves under the current save name (as quicksave does), then quits to the desktop
local function saveAndQuit()
	local name = saveName()
	debugPrint("[save_and_quit] saving " .. name)
	app.saveGame(name, function()
		debugPrint("[save_and_quit] saved " .. name .. "; quitting")
		app.quit(true)
	end, api.gui.game.isMapEditor(), true)
end

-- Loaded at click time: game_react_globals pulls in game UI modules that don't exist while resources are scanned
local function windowApi() : Builtin.WindowAPI
	local globals = ug_require "::/gui/main/game_react_globals.tl" as GameReactGlobals
	return globals.getDefaultWindowApi()
end

-- Mod button bar button, styled like the layer button (size in save_and_quit.css.lua); stays pressed while the confirmation is open
local SaveAndQuitButton = react.RegisterPluginRecipe(main_mod_button_area.MainModButtonAreaExtension, "CruesoeSaveAndQuitButton", function() : TreeNodeId
	local pressedState = react.useState(false) as ReactStateT<boolean>
	local quittingState = react.useState(false) as ReactStateT<boolean>
	local savingState = engine_react_util.useStepState(function() : boolean
		return api.gui.game.isSavegameUIBlocked()
	end) as ReactStateT<boolean>

	local function confirm()
		local wc = windowApi()
		if not wc then return end
		local function cancel()
			pressedState:set(false)
			wc.removeAllWindows(dialog_react_util.DialogWindow)
		end
		pressedState:set(true)
		wc.addSingletonWindow(dialog_react_util.DialogWindow, {
			onClose = function() pressedState:set(false) end,
			x = 0.5,
			y = 0.5,
			windowTitle = _("cruesoe_save_and_quit_title"),
			displayText = lang_util.format(_("cruesoe_save_and_quit_confirm"), { savegameName = saveName() }),
			choices = {
				{
					text = _("cruesoe_save_and_quit_title"),
					onClick = function()
						quittingState:set(true)
						wc.removeAllWindows(dialog_react_util.DialogWindow)
						saveAndQuit()
					end,
					isSecondary = true,
				},
				{
					text = _("cruesoe_save_and_quit_cancel"),
					onClick = cancel,
					isSecondary = false,
				},
			},
			onBackChoiceIndex = 2,
		})
	end

	-- A plugin recipe must return a layout
	return builtin.BoxLayout{
		children = {
			builtin.ToggleButton{
				meta = {
					id = "cruesoe-save-and-quit.button",
					tooltip = _("cruesoe_save_and_quit_tooltip"),
					enabled = not quittingState:old() and not savingState:old(),
				},
				content = builtin.ImageView{
					path = "::/gui/main/icons/symbol_save_floppy_42.tga",
					scaling = builtin.type.ImageViewScaling.AutoFit,
				},
				value = (pressedState:old() or quittingState:old()) and 1 or 0,
				onValueChange = function(_value : integer)
					if quittingState:old() then return end
					if pressedState:old() then
						-- A second click closes the confirmation
						pressedState:set(false)
						local wc = windowApi()
						if wc then wc.removeAllWindows(dialog_react_util.DialogWindow) end
					else
						confirm()
					end
				end,
			},
		},
	}
end)

return {
	SaveAndQuitButton = SaveAndQuitButton,
}
