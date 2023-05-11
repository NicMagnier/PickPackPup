reset_progress = {}

local _max_progress = 0
local _progress = 0

local _anim_dog_enter = sequence.new():from(200):to(-20, 1.0, "outCubic")

local _fade_out = 0

function reset_progress.init()
	_progress = 0
	_max_progress = 0
	_fade_out = 0

	character.reset()
	character.set_animation( "idle" )

	playdate.ui.crankIndicator:start()
end

function reset_progress.update( dt )
	character.update( dt )

	if input.on(buttonB) then
		mode.back()
	end

	local crank_delta, acceleration = playdate.getCrankChange()

	_progress = math.clamp( _progress + crank_delta * 0.0001, 0, 1)

	if playdate.isCrankDocked() then
		_progress = math.clamp( _progress - dt, 0, 1)
	end

	if _max_progress>0.05 then
		_anim_dog_enter:start()
	end

	if _max_progress>0.2 then
		character.set_animation( "danger", 130 )
	else
		character.set_animation( "idle", 150 )
	end

	if _max_progress<_progress then
		if 0.05>_max_progress and 0.05<_progress then
			character.talk("reset_progress_talk_1")
		elseif 0.2>_max_progress and 0.2<_progress then
			character.talk("reset_progress_talk_2")
		elseif 0.3>_max_progress and 0.3<_progress then
			character.talk("reset_progress_talk_3")
		elseif 0.4>_max_progress and 0.4<_progress then
			character.talk("reset_progress_talk_4")
		elseif 0.5>_max_progress and 0.5<_progress then
			character.talk("reset_progress_talk_5")
		elseif 0.6>_max_progress and 0.6<_progress then
			character.talk("reset_progress_talk_6")
		elseif 0.7>_max_progress and 0.7<_progress then
			character.talk("reset_progress_talk_7")
		elseif 0.8>_max_progress and 0.8<_progress then
			character.talk("reset_progress_talk_8")
		elseif 0.9>_max_progress and 0.9<_progress then
			character.talk("reset_progress_talk_9")
		elseif _max_progress>=1 then
			character.talk("reset_progress_talk_10")
		end

		_max_progress = _progress
	end

	if _max_progress>=1 then
		_fade_out = math.clamp(_fade_out + dt*0.2, 0, 1)
	end

	if _fade_out>=1 then
		save_game.reset()
		-- mode.set( menu )
		mode.set( first_launch )
	end

end

function reset_progress.draw()

	playdate.graphics.clear(white)

	playdate.graphics.drawTextAligned( loc("reset_progress_instruction"), 200, 10, kTextAlignment.center )

	local h = 240*_progress
	playdate.graphics.setColor(black)
	playdate.graphics.fillRect(0, 240-h, 400, h)

	-- cancel instruction
	images.buttonB:draw(10,200)
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeNXOR)
	playdate.graphics.drawText( loc("reset_progress_cancel"), 50, 210 )
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)

	character.offset_x = _anim_dog_enter:get()
	character.draw()
	character.draw_speech()

	if playdate.isCrankDocked() then
		playdate.ui.crankIndicator:update()
	end

	if _fade_out>0 then
		playdate.graphics.setColor(white)
		playdate.graphics.setDitherPattern(1-_fade_out)
		playdate.graphics.fillRect(0,0,400,240)
	end

end