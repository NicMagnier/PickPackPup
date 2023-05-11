mode = {}

-- private members
local _index = 0
local _stack = table.create(8,0)
local _overlay_stack = table.create(8,0)
local _call_init = false
local _call_init_args = nil

local _update_start_time = nil
local _metric_update_duration = 0
local _metric_fullupdate_duration = 0

function mode.print_stack()
	print("-- Stack --")
	for i = _index, 1, -1 do
		print("  ", i, _stack[i].modename)
	end
end

-- push a new mode in the stack
function mode.push( new_mode, ... )
	if not new_mode then return end

	if _stack[_index] then
		call(_stack[_index].shutdown, ...)
	end

	local new_index = _index + 1
	_index = new_index
	_stack[new_index] = new_mode
	_overlay_stack[new_index] = nil

	-- we enter a new mode so we initialize it
	_call_init = true
	_call_init_args = {...}
end

-- push a new mode in the stack
-- draw previous mode as background
function mode.push_overlay( new_mode, ... )
	if not new_mode then return end

	mode.push( new_mode, ... )
	_overlay_stack[_index] = playdate.graphics.getDisplayImage()
end

-- go back to the previous mode in the stack
function mode.back(...)
	if _index<=1 then return end

	call(_stack[_index].shutdown, ...)
	_index = _index - 1
	call(_stack[_index].resume, ...)
end

function mode.back_to( game_mode, ... )
	while _index>1 and _stack[_index]~=game_mode do
		call(_stack[_index].shutdown, ...)
		_index = _index - 1
	end

	call(_stack[_index].resume, ...)
end

-- reset the whole stack
function mode.set( new_mode, ... )
	if not new_mode then return end

	if _stack[_index] then
		call(_stack[_index].shutdown, ...)
	end

	_index = 0
	mode.push( new_mode, ... )
end

-- properly switch mode at the beginning of the frame
function mode.update( dt )
	local previous_update_start_time = _update_start_time
	_update_start_time = playdate.getCurrentTimeMilliseconds()
	if previous_update_start_time then
		_metric_fullupdate_duration = _update_start_time - previous_update_start_time
	end

	local index = _index
	local current = _stack[_index]

	-- we call the init before it's own update
	if _call_init then
		call(current.init, table.unpack(_call_init_args))
		_call_init = false
	end

	-- update the current mode
	call( current.update, dt )

	-- render the framebuffer copy of the previous mode
	local overlay_background = _overlay_stack[index]
	if overlay_background then
		overlay_background:draw(0,0)
		playdate.graphics.setColor(black)
		playdate.graphics.setDitherPattern(0.5)
		playdate.graphics.fillRect(0, 0, 400, 240)
	end

	-- render current mode
	if type(current.draw)=="function" then
		screenshake.update( dt )
		current.draw()
	end

	_metric_update_duration = playdate.getCurrentTimeMilliseconds() - _update_start_time
end

function mode.is_in_stack( check_mode )
	for i = _index, 1, -1 do
		if _stack[i]==check_mode then
			return true
		end
	end

	return false
end

function mode.get_metrics()
	return _metric_update_duration, _metric_fullupdate_duration
end