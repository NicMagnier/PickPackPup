pause = {
	modename = "pause",

	frame = playdate.graphics.nineSlice.new("images/frames/pause", 6, 6, 20, 14),

	state = "menu",

	menu_options = { "Resume", "Settings", "Quit" },
	current_menu_option = 1,

	confirm_options = { "No", "Yes" },
	current_confirm_option = 1
}

-- private members
local _state = "menu"

-- menu list for the pause menu
local _pause_list = nil
local _quit_index = 3

local _pause_list_standard = {
	{
		label = "PauseResume",
		margin_bottom = 10,
		onPressed = function()
			mode.back()
		end
	},

	{
		label = "PauseReset",
		margin_bottom = 10,
		onPressed = function()
			if mode.is_in_stack( story ) then
				mode.back_to(story)
				story.reset_level()
			else
				mode.back_to(game)
				mode.back()
				mode.push(game, game.mode)
			end
		end
	},

	{
		label = "PauseSettings",
		margin_bottom = 10,
		onPressed = function()
			mode.push( settings )
		end
	},

	{
		label = "PauseQuit",
		onPressed = function()
			pause.enter_quit_confirm()
		end
	},
}

-- menu list for the pause menu
local _pause_list_no_reset = {
	{
		label = "PauseResume",
		margin_bottom = 10,
		onPressed = function()
			mode.back()
		end
	},

	{
		label = "PauseSettings",
		margin_bottom = 10,
		onPressed = function()
			mode.push( settings )
		end
	},

	{
		label = "PauseQuit",
		onPressed = function()
			pause.enter_quit_confirm()
		end
	},
}

-- menu list for the pause menu during the first launch
local _pause_list_first_launch = {
	{
		label = "PauseResume",
		margin_bottom = 10,
		onPressed = function()
			mode.back()
		end
	},

	{
		label = "PauseSettings",
		margin_bottom = 10,
		onPressed = function()
			mode.push( settings )
		end
	},

	{
		label = "PauseQuitTutorial",
		onPressed = function()
			comic_menu.unlock( "page01" )
			comic_menu.unlock( "page02" )
			if mode.is_in_stack( game ) then
				mode.back()
				mode.back()
			else
				first_launch.finish()
			end
		end
	},
}

local _confirm_list = {
	{
		label = "PauseQuitNo",
		margin_bottom = 10,
		onPressed = function()
			pause.leave_quit_confirm()
		end
	},

	{
		label = "PauseQuitYes",
		onPressed = function()
			mode.set( menu )
		end
	},
}

-- private member
local _pause_background_offset = 100
local _pause_background = playdate.graphics.image.new(400, 240)

function pause.init()
	_state = "menu"
	_quit_index = 3

	if first_launch.is_running then
		_pause_list = _pause_list_first_launch
	else
		if game.mode=="normal" then
			_pause_list = _pause_list_no_reset
		else
			_pause_list = _pause_list_standard
			_quit_index = 4
		end
	end

	menulist.set_list( _pause_list )

	music.pause()
end

function pause.enter_quit_confirm()
	_state = "confirm"
	menulist.set_list( _confirm_list )
end

function pause.leave_quit_confirm()
	_state = "menu"

	menulist.set_list( _pause_list, _quit_index )
end

function pause.update( dt )
	menulist.update( dt )
	if _state=="menu" and input.on(buttonB) then
		music.unpause()
		mode.back()
	end
end

function pause.draw()
	images["pause_background"]:draw(0,0)

	-- display the memo
	local in_comic_reader = mode.is_in_stack( comic_reader )
	local in_story_intro = mode.is_in_stack( story_level_intro )
	if (not in_comic_reader) and (not in_story_intro) then
		memo.drawBackground(0, 0)
		memo.drawPage(1, 0, 0)
	end

	-- draw pause frame
	if _state=="confirm" then
		playdate.graphics.drawTextAligned( loc("PauseQuitMessage"), 300, 50, kTextAlignment.center)
		menulist.draw( 300, 100, kTextAlignment.center)
	else
		menulist.draw( 300, 50, kTextAlignment.center)
	end
end


-- System related functions

function pause.renderBackground()
	local gfx = playdate.graphics

	gfx.lockFocus(_pause_background)
	gfx.clear(black)

	memo.drawBackground(_pause_background_offset, 0)
	memo.drawPage(1, _pause_background_offset, 0)
	gfx.unlockFocus()
end

function pause.prepareSystem()
	memo.create( {game.memo} )
	pause.renderBackground()
	playdate.setMenuImage(_pause_background, _pause_background_offset)
end

function pause.resetSystem()
	-- TODO
	-- BUGGY CODE
	local gfx = playdate.graphics
	gfx.lockFocus(_pause_background)
	-- gfx.setColor(black)
	-- gfx.fillRect(0, 0, 400, 240)
	images["menu_background"]:draw(0,0)
	-- gfx.getDisplayImage():drawFaded(0,0, 0.5, playdate.graphics.image.kDitherTypeBayer8x8)
	gfx.unlockFocus()

	playdate.setMenuImage(_pause_background)
end