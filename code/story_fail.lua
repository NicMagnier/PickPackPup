story_fail = {}

local _logo01 = playdate.graphics.image.new("images/levelfailed_part1")
local _logo01_anim = sequence.new():from(-240):to(-50, 1.2, "outBounce")
local _logo02 = playdate.graphics.image.new("images/levelfailed_part2")
local _logo02_anim = sequence.new():from(-240):sleep(0.3):to(-50, 1.6, "outBounce")

local _fadeout = 0

local _framebuffer_copy

function story_fail.init()
	_framebuffer_copy = playdate.graphics.getDisplayImage()
	_logo01_anim:restart()
	_logo02_anim:restart()
	_fadeout = 0

	sfx.play("fail")
end

function story_fail.update(dt)
	if _logo01_anim:isDone() and _logo02_anim:isDone() then
		_fadeout = math.clamp(_fadeout + dt, 0, 1)
	end

	if _fadeout>=1 and input.on(buttonA) then
		mode.back()
	end
end

function story_fail.draw()
	if _framebuffer_copy then
		_framebuffer_copy:draw(0,0)
	end

	-- fade in
	playdate.graphics.setColor(white)
	playdate.graphics.setDitherPattern(1 - _fadeout)
	playdate.graphics.fillRect(0, 0, 400, 240)

	-- Game Over logo
	_logo01:draw(0, _logo01_anim:get())
	_logo02:draw(0, _logo02_anim:get())

	if blink(40, 10) and _fadeout>=1 then
		images.buttonA:draw( 360, 200)
	end
end