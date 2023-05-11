screenshake = {}

local _enable = false
local _time = 0
local _time_max = 0
local _force = 0

function screenshake.disable()
	_enable = false
	playdate.graphics.setDrawOffset(0, 0)
end

function screenshake.update(dt)
	if _enable==false then
		return
	end

	_time = max(_time-dt, 0)
	if _time==0 then
		screenshake.disable()
		return
	end

	local force = _force * _time
	playdate.graphics.setDrawOffset( rand(-force,force), rand(-force,force))
end

function screenshake.set( force, time )
	_enable = true

	_time = time or _time
	_force = force / _time
end