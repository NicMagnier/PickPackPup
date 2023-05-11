gameover = { modename = "gameover" }

-- private members
local _score = 0
local _highscore_old = 0
local _highscore_new = 0
local _no_input_cooldown = 0
local _fadein = 0

local _logo_anim = sequence.new():from(-240):to(0, 1.5, "outElastic")
local _score_anim = sequence.new():from(30):sleep(1.5):to(0, 0.4)
local _new_highscore_anim = sequence.new()
local _new_highscore_sound = sequence.new():from(0)
local _new_highscore_sfx_played = false

local _framebuffer_copy
local _background = playdate.graphics.image.new("images/gameover_background")

function gameover.init( old_highscore, new_highscore )
	_fadein = 0
	_framebuffer_copy = playdate.graphics.getDisplayImage()
	_logo_anim:restart()
	_score_anim:restart()
	_no_input_cooldown = 0.5
	_score = math.floor(game.real_score)

	_highscore_old = old_highscore or 0
	_highscore_new = new_highscore or 0
	_new_highscore_sfx_played = false

	if _highscore_new>_highscore_old then
		_new_highscore_anim:from(_highscore_old):sleep(2.2):to(_highscore_new, 1):start()
		_new_highscore_sound:from(0):sleep(2.2):to(1):sleep(1):to(0):start()
	else
		_new_highscore_anim:from(_highscore_old)
	end
end

function gameover.shutdown()
	sfx.get( "counting_up" ):stop()
end

function gameover.update(dt)
	_fadein = math.clamp(_fadein + dt*2, 0, 1)

	if _fadein==1 and _highscore_new>0 and _highscore_new>_highscore_old then
		if _new_highscore_anim:isDone() and _new_highscore_sfx_played==false then
			sfx.play("challenge_completed")
			_new_highscore_sfx_played = true
		end

		local counting_up_sfx = sfx.get( "counting_up" )
		if _new_highscore_sound:get()>0 and _new_highscore_sound:isDone()==false then
			if counting_up_sfx:isPlaying()==false then
				counting_up_sfx:play(1)
				counting_up_sfx:setVolume(settings.sound_volume)
			end
		else
			counting_up_sfx:stop()
		end
	end

	if _no_input_cooldown>0 then
		_no_input_cooldown = _no_input_cooldown - dt
	elseif input.on(buttonA) then
		mode.set( menu )
	end

end

function gameover.draw()
	if _framebuffer_copy then
		_framebuffer_copy:draw(0,0)
	end

	-- fade in
	_background:drawFaded(0, 0, _fadein, playdate.graphics.image.kDitherTypeBayer4x4)

	-- Game Over logo
	images.gameover:draw(0, _logo_anim:get())

	-- Score
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
	playdate.graphics.drawText( "Final Score: *".._score.."*", 10, 240 - 26 +  _score_anim:get())

	-- highscore
	local highscore_to_display = math.floor(_new_highscore_anim:get())
	local highscore_delta = _highscore_new - _highscore_old
	if _highscore_old>0 or _highscore_new>0 then
		playdate.graphics.drawTextAligned( "HighScore: *"..highscore_to_display.."*", 400 - 10, 240 - 26, kTextAlignment.right)

		if highscore_delta>0 and _new_highscore_anim:isDone() and blink(15, 5) then
			playdate.graphics.drawTextAligned( "*New HighScore* +"..highscore_delta, 400 - 10, 240 - 50, kTextAlignment.right)
		end
	end

	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
end