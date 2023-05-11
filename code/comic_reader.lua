comic_reader = {
	modename = "comic reader",

	name = nil,
	image = nil,

	scroll = 0,
	scroll_max = 0,
	margin = 20,
	height = 0,
	width = 0,

	can_be_scrolled = false,
	at_start = false,
	reached_end = false,
}

-- private member
local _synth = playdate.sound.synth.new(playdate.sound.kWaveNoise)
local _can_close_with_crank = false
local _is_comic_menu = false

local _no_crank_delta_timeout = 0

local _start_timestamp
local _synth_volume = 0

function comic_reader.view_comic( name )
	comic_reader.name  = name
	comic_reader.image = nil

	mode.push( comic_reader )
end

function comic_reader.init()
	comic_menu.unlock( comic_reader.name )
	save_game.save()

	playdate.display.setRefreshRate(50)

	comic_reader.image = playdate.graphics.image.new( "images/comic/"..comic_reader.name )

	local iw, ih = comic_reader.image:getSize()

	comic_reader.scroll = 0
	comic_reader.width = iw
	comic_reader.can_be_scrolled = ih > 240

	if comic_reader.can_be_scrolled then
		comic_reader.margin = min((400 - comic_reader.width)/2, 20)
	else
		comic_reader.margin = (240 - ih)/2
		comic_reader.height = 240
	end

	comic_reader.height = ih + comic_reader.margin * 2
	comic_reader.scroll_max = comic_reader.height - 240

	playdate.ui.crankIndicator:start()
	_can_close_with_crank = playdate.isCrankDocked()==false
	comic_reader.reached_end = false
	comic_reader.at_start = true

	_synth_volume = 0
	_synth:playNote(2000)
	_synth:setVolume(_synth_volume)

	_is_comic_menu = mode.is_in_stack( comic_menu )

	_start_timestamp = playdate.getCurrentTimeMilliseconds()
end

function comic_reader.resume()
	playdate.display.setRefreshRate(50)
end

function comic_reader.shutdown()
	_synth:noteOff()
	playdate.display.setRefreshRate(30)
end

function comic_reader.update( dt )
	local crank_delta = playdate.getCrankChange()

	if crank_delta==0 then
		_no_crank_delta_timeout = max(_no_crank_delta_timeout-dt, 0)
	else
		_no_crank_delta_timeout = 0.1
	end

	-- emulate the crank with the dpad
	if _no_crank_delta_timeout==0 then
		if input.is(buttonDown) then
			crank_delta = crank_delta + 300*dt
		end
		if input.is(buttonUp) then
			crank_delta = crank_delta - 300*dt
		end
	end

	local old_scroll = comic_reader.scroll
	comic_reader.scroll = math.clamp(comic_reader.scroll + crank_delta, -60, comic_reader.scroll_max + 60 )
	local scroll_delta = old_scroll - comic_reader.scroll

	if _no_crank_delta_timeout==0 then
		if comic_reader.scroll>comic_reader.scroll_max then
			comic_reader.scroll = comic_reader.scroll - 100*dt
		elseif comic_reader.scroll<0 then
			comic_reader.scroll = comic_reader.scroll + 100*dt
		end
	end

	if comic_reader.reached_end==false then
		comic_reader.reached_end = comic_reader.scroll > comic_reader.scroll_max - 100
	end

	if comic_reader.at_start==true then
		comic_reader.at_start = comic_reader.scroll < 100
	end

	if _is_comic_menu then
		if _can_close_with_crank==false then
			_can_close_with_crank = playdate.isCrankDocked()==false
		end
		local close_with_crank = _can_close_with_crank and playdate.isCrankDocked()

		if input.on(buttonA | buttonB) or close_with_crank then
			mode.back()
		end
	else
		if comic_reader.reached_end and (input.onCrankDock() or input.on(buttonA)) then
			mode.back()
		end

		if input.on(buttonB) then
			mode.push_overlay( pause )
		end
	end


	local target_volume = math.clamp( math.abs(scroll_delta), 0, 5) / 5
	if target_volume > _synth_volume then
		_synth_volume = math.approach( _synth_volume, target_volume, 3*dt )
	else
		_synth_volume = math.approach( _synth_volume, target_volume, 10*dt )
	end

	local time = (playdate.getCurrentTimeMilliseconds() - _start_timestamp)/1000
	local volume_variation01 = 0.5 + math.sin(time*6) * 0.5
	local volume = _synth_volume * 0.02 + _synth_volume * volume_variation01 * 0.005
	_synth:setVolume( math.clamp(volume, 0, 1) * settings.sound_volume )
end

function comic_reader.draw()
	images["comic_background"]:draw(0,0)

	-- draw message at the bottom
	local message
	if _is_comic_menu then
		message = loc("comic_close_in_reader")
	else
		if playdate.isCrankDocked() then
			message = loc("comic_close_in_story_without_crank")
		else
			message = loc("comic_close_in_story_with_crank")
		end
	end

	local tw, th = playdate.graphics.getTextSize(message)
	local margin_h, margin_v = 10, 5
	game.score_frame:drawInRect( 200-tw/2-margin_h, 210-margin_v, tw+2*margin_h, th+2*margin_v)

	playdate.graphics.drawTextAligned(message, 200, 210, kTextAlignment.center)

	local x = (400 - comic_reader.width)/2
	local y = comic_reader.margin - comic_reader.scroll
	comic_reader.image:draw(x, y)

	-- draw page outline
	local iw, ih = comic_reader.image:getSize()
	playdate.graphics.setColor(black)
	playdate.graphics.drawRect(x-1,y-1, iw+2, ih+2)

	if comic_reader.can_be_scrolled and comic_reader.scroll<240 and (playdate.isCrankDocked() or comic_reader.at_start) then
		playdate.ui.crankIndicator:update()
	end

	if comic_reader.reached_end and playdate.isCrankDocked() then
		if blink(40, 10) then
			images.buttonA:draw( 360, 200)
		end
	end
end