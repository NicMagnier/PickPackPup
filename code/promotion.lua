promotion = {
	modename = "promotion",
	
	no_input_cooldown = 0,
}

-- private members
local _background = playdate.graphics.image.new("images/promotion/background")
local _title = playdate.graphics.image.new("images/promotion/text")
local _animation_frames = playdate.graphics.imagetable.new("images/promotion/animation")

local _text_anim = sequence.new():from(400):sleep(0.3):to(0, 1.5, "outElastic")

local _sequence_speed = 0.1

local _sequence_index = 1
local _sequence_time = 0
local _sequence = {
	{ frame = 1, duration = 0.7 },
	{ frame = 2, duration = 0.1 },

	{ frame = 3, duration = _sequence_speed },
	{ frame = 4, duration = _sequence_speed },
	{ frame = 5, duration = _sequence_speed },

	-- spinning the box
	{ frame = 6, duration = _sequence_speed },
	{ frame = 7, duration = _sequence_speed },
	{ frame = 8, duration = _sequence_speed },
	{ frame = 9, duration = _sequence_speed },

	{ frame = 6, duration = _sequence_speed },
	{ frame = 7, duration = _sequence_speed },
	{ frame = 8, duration = _sequence_speed },
	{ frame = 9, duration = _sequence_speed },
	{ frame = 6, duration = _sequence_speed },
	{ frame = 7, duration = _sequence_speed },
	{ frame = 8, duration = _sequence_speed },
	{ frame = 9, duration = _sequence_speed },
	{ frame = 6, duration = _sequence_speed },
	{ frame = 7, duration = _sequence_speed },
	{ frame = 8, duration = _sequence_speed },
	{ frame = 9, duration = _sequence_speed },

	{ frame = 2, duration = _sequence_speed },
}

function promotion.init()
	promotion.no_input_cooldown = 0.5

	_text_anim:restart()
	sfx.play("promotion")

	_sequence_index = 1
	_sequence_time = 0
end

function promotion.update(dt)
	if promotion.no_input_cooldown>0 then
		promotion.no_input_cooldown = promotion.no_input_cooldown - dt
	elseif input.on(buttonA) then
		mode.back()
	end

	-- update sequence
	local seq_frame = _sequence[_sequence_index]

	_sequence_time = _sequence_time + dt

	if _sequence_time>=seq_frame.duration then
		_sequence_time = _sequence_time - seq_frame.duration
		_sequence_index = _sequence_index + 1
	end

	-- looping
	if not _sequence[_sequence_index] then
		_sequence_index = 1
	end
end

function promotion.draw()
	_background:draw(0,0)
	_title:draw( _text_anim:get(), 0)

	local frame = _animation_frames:getImage(_sequence[_sequence_index].frame)
	frame:draw(180, 0)
end