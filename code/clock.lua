clock = {
	duration = 20,
	danger = 5,
	time = 0,

}

-- private members
local _enabled = true
local _has_ended = false
local _frame = playdate.graphics.nineSlice.new("images/frames/dark", 5, 3, 2, 2)

local _render_text
local _render_w = 100
local _render_h = 18
local _render = playdate.graphics.image.new(_render_w, _render_h)
local _sprite = playdate.graphics.sprite.new()
_sprite:setImage(_render)
_sprite:setCenter(0.5, 1)
_sprite:setZIndex(layer.clock)
_sprite:moveTo(132,240)

function clock.reset()
	clock.duration = 20
	clock.danger = 5
	clock.time = 0
	_has_ended = false
	clock.enable()
end

function clock.enable()
	_enabled = true
	_sprite:add()
end

function clock.disable()
	_enabled = false
	game.board_y = 10
	_sprite:remove()
end

function clock.set_duration( duration, danger )
	clock.duration = duration
	clock.danger = danger or 5
end

function clock.time_left()
	return clock.duration - clock.time
end

function clock.in_danger()
	if not _enabled then
		return false
	end

	return (clock.duration - clock.time) < clock.danger
end

function clock.has_ended()
	return _enabled and _has_ended
end

function clock.stop_sfx()
	sfx.get( "clock" ):stop()
end

function clock.update( dt )
	_has_ended = false

	if not _enabled then
		return
	end

	if game.has_moving_tile==false then
		clock.time = clock.time + dt
	end

	if clock.time>clock.duration then
		clock.time = clock.time - clock.duration
		_has_ended = true
	end

	local clock_sfx = sfx.get( "clock" )
	local timeleft = clock.duration - clock.time
	if _has_ended==false and timeleft < clock.danger then
		clock_sfx:setVolume(settings.sound_volume*math.infinite_approach(0, 1, clock.danger*0.3, clock.danger-timeleft))
		if clock_sfx:isPlaying()==false then
			clock_sfx:play(1, 0)
		end
	else
		clock_sfx:stop()
	end

	-- render
	local time_left = clock.time_left()
	local time_text = math.ceil(time_left)
	if game.is_trashing then
		time_text = "Trashing"
	end

	if time_text==_render_text then
		return
	end
	_render_text = time_text

	playdate.graphics.lockFocus(_render)

		local x, y, w, h = 0, 0, _render_w, _render_h
		_frame:drawInRect(x, y, w, h)

		images.clock:draw(x+5,y)

		playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)

		set_font( "clock" )
		playdate.graphics.drawTextAligned( _render_text, x + w/2 + 9, y+3, kTextAlignment.center)
		default_font()

		playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)

	playdate.graphics.unlockFocus()

	_sprite:markDirty()

end
