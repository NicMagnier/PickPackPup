settings = {
	modename = "settings",

	music_volume = 1,
	sound_volume = 1,

	music_anim = table.create(10,0),
	sound_anim = table.create(10,0),

	previous_mode = nil
}

local bar_high, bar_low = 10, 1
local music_index, sound_index

local _list_in_game = { "Music", "SFX", "Reset" }
local _list_in_menu = { "Music", "SFX", "CustomTileset", "Reset" }
local _list = _list_in_menu
local _list_selected = 1

local _show_custom_tileset = false

local _background = playdate.graphics.image.new( "images/settings_background" )
local _cursor = playdate.graphics.image.new( "images/menu_cursor" )
local _cursor_animy = sequence.new()

-- pre-allocate animations
for i=1, 10 do
	settings.music_anim[i] = sequence.new()
	settings.sound_anim[i] = sequence.new()
end

function settings.draw_cursor(x,y)
	local iw, ih = _cursor:getSize()

	_cursor:draw( x - iw/2, y - ih/2 + _cursor_animy:get())
end

function settings.init( previous_mode )
	settings.previous_mode = previous_mode
	_list_selected = 1

	music_index = math.floor(settings.music_volume*10)
	sound_index = math.floor(settings.sound_volume*10)

	-- initial animation when menu opens
	for i=1, 10 do
		if music_index>=i then
			settings.music_anim[i]:from(0):sleep(0.03*i):to(bar_high, 0.3, "outBack"):start()
		else
			settings.music_anim[i]:from(0):sleep(0.03*i):to(bar_low, 0.3):start()
		end

		if sound_index>=i then
			settings.sound_anim[i]:from(0):sleep(0.25+0.03*i):to(bar_high, 0.3, "outBack"):start()
		else
			settings.sound_anim[i]:from(0):sleep(0.25+0.03*i):to(bar_low, 0.3):start()
		end
	end

	if mode.is_in_stack( game ) then
		_list = _list_in_game
		_show_custom_tileset = false
	else
		_list = _list_in_menu
		_show_custom_tileset = true
	end
end

function settings.update( dt )
	-- quit?
	if input.on(buttonB) then
		save_game.save()
		mode.back()
	end

	-- selection
	if input.on(buttonUp) then
		_list_selected = math.clamp( _list_selected - 1, 1, #_list)
		_cursor_animy:from(10):to(0, 0.3, "outBack"):start()
		sfx.play( "menu_move" )
	end
	if input.on(buttonDown) then
		_list_selected = math.clamp( _list_selected + 1, 1, #_list)
		_cursor_animy:from(-10):to(0, 0.3, "outBack"):start()
		sfx.play( "menu_move" )
	end

	-- update the section
	local current_name = _list[_list_selected]

	if current_name=="Music" then
		if input.on(buttonLeft) then
			music_index = math.clamp( music_index-1, 0, 10)
			settings.music_anim[music_index+1]:from(bar_high):to(bar_low, 0.5, "outBounce"):start()
		elseif input.on(buttonRight) then
			music_index = math.clamp( music_index+1, 0, 10)
			settings.music_anim[music_index]:from(bar_low):to(bar_high, 0.3, "outBack"):start()
		end

		if input.on(buttonLeft) or input.on(buttonRight) then
			settings.music_volume = music_index / 10
			music.volume( settings.music_volume )
			sfx.play("select")
		end

	elseif current_name=="SFX" then
		if input.on(buttonLeft) then
			sound_index = math.clamp( sound_index-1, 0, 10)
			settings.sound_anim[sound_index+1]:from(bar_high):to(bar_low, 0.5, "outBounce"):start()
		end
		if input.on(buttonRight) then
			sound_index = math.clamp( sound_index+1, 0, 10)
			settings.sound_anim[sound_index]:from(bar_low):to(bar_high, 0.3, "outBack"):start()
		end

		if input.on(buttonLeft) or input.on(buttonRight) then
			settings.sound_volume = sound_index / 10
			sfx.play("select")
		end

	elseif current_name=="CustomTileset" then
		if input.on(buttonA) then
			mode.push( custom_tileset )
		end

	elseif current_name=="Reset" then
		if input.on(buttonA) then
			mode.push( reset_progress )
		end
	end
end

function settings.draw()
	local current_name = _list[_list_selected]
	local x, y, w, h

	_background:draw(0,0)

	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
	playdate.graphics.drawText( "*Settings*", 50, 7)
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)

	-- setup colors
	playdate.graphics.setColor(black)

	if _show_custom_tileset then
		y = 40
	else
		y = 50
	end

	-- Music
	if current_name=="Music" then
		settings.draw_cursor(120, y+30)
		playdate.graphics.drawTextAligned( "*Music*", 200, y, kTextAlignment.center)
	else
		playdate.graphics.drawTextAligned( "Music", 200, y, kTextAlignment.center)
	end

	x, w, h = 140, 120, 20
	y = y + 20
	for i=1, 10 do
		local bar_height = settings.music_anim[i]:get()
		playdate.graphics.fillRect(x + 12*(i-1), y+10 - bar_height, 10, bar_height*2)
	end
	y = y + 40

	-- Volume
	if current_name=="SFX" then
		settings.draw_cursor(120, y+30)
		playdate.graphics.drawTextAligned( "*Sound Effects*", 200, y, kTextAlignment.center)
	else
		playdate.graphics.drawTextAligned( "Sound Effects", 200, y, kTextAlignment.center)
	end

	x, w, h = 140, 120, 20
	y = y + 20
	for i=1, 10 do
		local bar_height = settings.sound_anim[i]:get()
		playdate.graphics.fillRect(x + 12*(i-1), y+10 - bar_height, 10, bar_height*2)
	end
	y = y + 40

	-- CustomTileset
	if _show_custom_tileset then
		if current_name=="CustomTileset" then
			settings.draw_cursor(120, y+10)
			playdate.graphics.drawTextAligned( "*Custom Item List*", 200, y, kTextAlignment.center)
		else
			playdate.graphics.drawTextAligned( "Custom Item List", 200, y, kTextAlignment.center)
		end
		y = y + 40
	else
		y = y + 20
	end

	-- Reset
	if current_name=="Reset" then
		settings.draw_cursor(120, y+10)
		playdate.graphics.drawTextAligned( "*Reset Progress*", 200, y, kTextAlignment.center)
	else
		playdate.graphics.drawTextAligned( "Reset Progress", 200, y, kTextAlignment.center)
	end
	y = y + 40
end