recorder = {
	is_recording = false,
	random_index = 0,
	input_index = 0,
}

local content = {
	inputs = {},

	random_seed = 0,
	random = {},
}

local ib = {
	[buttonLeft] = 1,
	[buttonRight] = 2,
	[buttonUp] = 3,
	[buttonDown] = 4,
	[buttonA] = 5,
	[buttonB] = 6,
}

function recorder.record()
	content.random_seed = playdate.getSecondsSinceEpoch()
	math.randomseed(content.random_seed)

	-- switch to fixed framerate
	getDeltaTime = function()
		return 1/30
	end

	-- switch rand() functions
	local _rand = rand
	rand = function(min, max)
		local result = _rand(min, max)
		table.insert(content.random, result)
		return result
	end

	-- switch input functions
	local _input_update = input.update
	input.update = function(dt)
		_input_update(dt)
		table.insert(content.inputs, {
			[ib[buttonLeft]] = input.is(buttonLeft),
			[ib[buttonRight]] = input.is(buttonRight),
			[ib[buttonUp]] = input.is(buttonUp),
			[ib[buttonDown]] = input.is(buttonDown),
			[ib[buttonA]] = input.is(buttonA),
			[ib[buttonB]] = input.is(buttonB),
		})
	end

	recorder.is_recording = true
end

function recorder.replay( )
	-- read file
	content = playdate.datastore.read("recording")

	math.randomseed(content.random_seed)

	-- switch to fixed framerate
	getDeltaTime = function()
		return 1/30
	end

	-- switch rand() functions
	rand = function(min, max)
		recorder.random_index = recorder.random_index + 1
		return content.random[recorder.random_index]
	end

	local _rand_int = rand_int
	rand_int = function(min, max)
		return math.floor(_rand_int(min, max)+0.1)
	end

	-- switch input functions
	local _input_update = input.update
	input.update = function(dt)
		recorder.input_index = recorder.input_index + 1
		print("replay input frame",recorder.input_index)
		_input_update(dt)
	end

	input.is = function(b)
		return content.inputs[recorder.input_index][ib[b]]
	end

	input.on = function(b)
		return content.inputs[recorder.input_index][ib[b]] and not content.inputs[recorder.input_index-1][ib[b]]
	end

	input.off = function(b)
		return content.inputs[recorder.input_index-1][ib[b]] and not content.inputs[recorder.input_index][ib[b]]
	end

	playdate.buttonIsPressed = input.is
	playdate.buttonJustPressed = input.on
	playdate.buttonJustReleased = input.off
end

function recorder.fast_forward( frame_id )
	if recorder.is_recording then
		return
	end

	if frame_id<0 then
		frame_id = (#content.inputs) + frame_id
	end
	
	while ( recorder.input_index~=frame_id ) do
		playdate.update()
	end
end

function recorder.save(  )
	if not recorder.is_recording then
		return
	end

	local size = #content.inputs

	playdate.datastore.write(content, "recording")
	print("Recording Save -",size, "frames")
end