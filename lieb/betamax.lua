--[[
Betamax is a module that record a gameplay session and let you play it back.
It records inputs, timings and random numbers and feed them back to the game during playback.

== How to Add betamax in your project ==
in main.lua:
	import betamax as the very top of main.lua (before any other file)
	call betamax_eof() at the bottom of main.lua

== Example ==
import 'betamax'
import 'CoreLibs/graphics'

function playdate.update()
	-- do stuff
end
betamax_eof()

== How to Use ==
- How to record: When you want to record a game session, simply press the Menu button of the playdate.
- How to playback: To playback the previous recording, simply boot the game while holding Left on the D-Pad. You can fast forward 10x by pressing right on the D-Pad.

The recording is save in the Disk/Data/(bundleID) folder.
betamax_eof() can take an optional argument, which is the frame to directly jump to. It can be negative to jump to a frame from the end of the recording (for example -100)

== Limitations ==
- The playback will properly work only if the source code is functionally identical. Code changes can break the playback.
- Number have a lower precision when running with betamax. Numbers are identical during recording and playback but less precise than when betamax is not used.
- Microphone inputs are not supported
- Handling inputs via callbacks is not supported
- Changing system callback (like playdate.update or playdate.gameWillPause) at runtime is not handled
- Since we record a lot of data, it will consume some RAM (and we don't care about memory fragmentation yet)
- It's the first version

== TODO ==
- current and previous input frame
- save empty frame when inputs are identical
- set_function_set(fn_array), have a function array for reading and playback
- function so that a game can save and replay part of the gameplay (generic replay feature)
- add callbacks for replay features (post_update, button press callbacks)

]]

betamax = {}

-- save reference to original functions we will replace
local og = {
	random = math.random,
	randomseed = math.randomseed,

	getCurrentTimeMilliseconds = playdate.getCurrentTimeMilliseconds,
	getTime = playdate.getTime,
	getSecondsSinceEpoch = playdate.getSecondsSinceEpoch,

	buttonIsPressed = playdate.buttonIsPressed,
	buttonJustPressed = playdate.buttonJustPressed,
	buttonJustReleased = playdate.buttonJustReleased,

	accelerometerIsRunning = playdate.accelerometerIsRunning,
	readAccelerometer = playdate.readAccelerometer,
	startAccelerometer = playdate.startAccelerometer,
	stopAccelerometer = playdate.stopAccelerometer,

	isCrankDocked = playdate.isCrankDocked,
	getCrankPosition = playdate.getCrankPosition,
	getCrankChange = playdate.getCrankChange,

	datastoreRead = playdate.datastore.read
}

-- player keep track of the frame and indexes we are at
local player = {
	frame = 0
}
local recording = {
	inputs = {},
	random = {},
	randomseed = {},
	read = {},
	getCurrentTimeMilliseconds = {},
	getTime = {},
	getSecondsSinceEpoch = {},
}

-- fraction part of a float is converted as an integer to be saved more consitently in the json
-- fraction is saved as an integer (math.floor(fraction*float_precision))
local float_precision = 10000000000

-- state of the input for the current frame
local frame_input = {
	buttons = 0,
	accelerometer_running = false,

	isCrankDocked = true,
	crankPos = 0,
	crankeDelta = 0,
	crankAcc = 0,

	accRunning = false,
	accData = { 0, 0, 0 }
}

-- we do a weird serialization for number to make sure that what we use during the recording
-- will be the same value as in the play back
local function serialize_number( n )
	if not n then
		return nil, nil
	end

	local int = math.floor(n)

	-- if it is a round number, we just return a single number
	if int==n then
		return {n}, n
	end

	-- for the fraction part of a float we save fraction at an integer too
	local frac = math.floor((n-int)*float_precision)
	return {int, frac}, int + frac/float_precision
end

local function unserialize_number( t )
	if not t then
		return nil
	end

	local int, frac = t[1], t[2]

	if not frac then
		return int
	end

	return int + frac/float_precision
end

-- when we run out of data, we just quit the game
local function reached_end_of_recording()
	print("End of recording")
	playdate.exit()
end

-- return the next entry recorded for a specific attribute
local function get_next( attribute_name )
	player[attribute_name] = player[attribute_name] + 1
	local result = recording[attribute_name][player[attribute_name]]
	if not result then
		reached_end_of_recording()
		return nil
	end
	return recording[attribute_name][player[attribute_name]]
end

-- save the next entry for a specific attribute
local function set_next( attribute_name, content )
	table.insert( recording[attribute_name], content)
	return content
end

-- return the next entry recorded for a specific attribute
local function get_next_tuple( attribute_name )
	return table.unpack(get_next( attribute_name ))
end

local function set_next_tuple( attribute_name, ... )
	set_next( attribute_name, {...} )
	return ...
end

local function save_recording()
	playdate.datastore.write(recording, "betamax_recording")
	print("Recording Saved -", #recording.inputs, "frames")
end

local function load_recording()
	recording = playdate.datastore.read("betamax_recording")
	if not recording then
		print("Betamax Error: Couldn't load any recording")
	end
end

-- we playback when we hold A, B and Left when booting
local is_playback = playdate.buttonIsPressed(playdate.kButtonLeft)

-- we setup the game for playbacka
if is_playback then
	-- initialize player
	player = {
		frame = 0
	}
	for attribute_name in pairs(recording) do
		player[attribute_name] = 0
	end

	-- loading file
	load_recording()
	print("Playback recording", #recording.inputs, "frames")

	playdate.getCurrentTimeMilliseconds = function() return get_next("getCurrentTimeMilliseconds") end
	playdate.getTime = function() return get_next( "getTime" ) end
	playdate.getSecondsSinceEpoch = function() return get_next( "getSecondsSinceEpoch" ) end
	playdate.datastore.read = function() return get_next( "read" ) end

	math.randomseed = function() og.randomseed(get_next( "randomseed" )) end
	math.random = function()
		return unserialize_number( get_next("random") )
	end

	playdate.startAccelerometer = function() end
	playdate.stopAccelerometer = function() end

-- we setup the game for recording
else
	playdate.getCurrentTimeMilliseconds = function() return set_next( "getCurrentTimeMilliseconds", og.getCurrentTimeMilliseconds() ) end
	playdate.getTime = function() return set_next( "getTime", og.getTime() ) end
	playdate.getSecondsSinceEpoch = function() return set_next_tuple( "getSecondsSinceEpoch", og.getSecondsSinceEpoch() ) end

	playdate.datastore.read = function( ... )
		local read_content = og.datastoreRead(...)
		set_next( "read", read_content )
		return read_content
	end

	math.randomseed = function( seed )
		-- TODO: we might have an issue if the seed is a float
		set_next( "randomseed", seed )
		return og.randomseed( seed )
	end
	math.random = function(...)
		local r, n = serialize_number( og.random(...) )
		set_next( "random", r )
		return n
	end

	-- we guarantee randomseed is set at least once
	math.randomseed(playdate.getSecondsSinceEpoch())
end

-- common input functions (Buttons)
playdate.buttonIsPressed = function( b )
	local buttons_state = recording.inputs[player.frame][1]
	return (buttons_state&b)>0
end
playdate.buttonJustPressed = function( b )
	if player.frame==1 then return false end
	local buttons_state = recording.inputs[player.frame][1]
	local prev_buttons_state = recording.inputs[player.frame-1][1]
	return ((buttons_state&b)>0) and ((prev_buttons_state&b)==0)
end
playdate.buttonJustReleased = function( b )
	if player.frame==1 then return false end
	local buttons_state = recording.inputs[player.frame][1]
	local prev_buttons_state = recording.inputs[player.frame-1][1]
	return ((buttons_state&b)==0) and ((prev_buttons_state&b)>0)
end

-- common crank functions
playdate.isCrankDocked = function()	return frame_input.isCrankDocked end
playdate.getCrankPosition = function() return frame_input.crankPos end
playdate.getCrankChange = function() return frame_input.crankeDelta, frame_input.crankAcc end

-- common accelerometer functions
playdate.accelerometerIsRunning = function() return frame_input.accRunning end
playdate.readAccelerometer = function() return table.unpack( frame_input.accData ) end

local function save_input_frame()
	-- Pack inputs to save
	local save_struct = {}

	-- compute button state
	local buttons = 0
	if og.buttonIsPressed(playdate.kButtonA)		then buttons = buttons | playdate.kButtonA end
	if og.buttonIsPressed(playdate.kButtonB)		then buttons = buttons | playdate.kButtonB end
	if og.buttonIsPressed(playdate.kButtonUp)		then buttons = buttons | playdate.kButtonUp end
	if og.buttonIsPressed(playdate.kButtonDown)		then buttons = buttons | playdate.kButtonDown end
	if og.buttonIsPressed(playdate.kButtonLeft)		then buttons = buttons | playdate.kButtonLeft end
	if og.buttonIsPressed(playdate.kButtonRight)	then buttons = buttons | playdate.kButtonRight end
	frame_input.buttons = buttons
	table.insert(save_struct, frame_input.buttons )

	-- compute crank
	frame_input.isCrankDocked = og.isCrankDocked()
	table.insert(save_struct, frame_input.isCrankDocked )

	if frame_input.isCrankDocked then
		frame_input.crankPos = 0
		frame_input.crankeDelta = 0
		frame_input.crankAcc = 0
	else
		local serialized

		frame_input.crankPos = og.getCrankPosition()
		frame_input.crankeDelta, frame_input.crankAcc = og.getCrankChange()

		serialized, frame_input.crankPos = serialize_number( frame_input.crankPos )
		table.insert(save_struct, serialized )

		serialized, frame_input.crankeDelta = serialize_number( frame_input.crankeDelta )
		table.insert(save_struct, serialized )

		serialized, frame_input.crankAcc = serialize_number( frame_input.crankAcc )
		table.insert(save_struct, serialized )
	end

	-- compute accelerometer
	frame_input.accRunning = og.accelerometerIsRunning()
	table.insert(save_struct, frame_input.accRunning )

	if frame_input.accRunning then
		local serialized
		local x, y, z = og.readAccelerometer()

		serialized, x = serialize_number( x )
		table.insert(save_struct, serialized )

		serialized, y = serialize_number( y )
		table.insert(save_struct, serialized )

		serialized, z = serialize_number( z )
		table.insert(save_struct, serialized )

		frame_input.accData[1] = x
		frame_input.accData[2] = y
		frame_input.accData[3] = z
	else
		frame_input.accData[1] = 0
		frame_input.accData[2] = 0
		frame_input.accData[3] = 0
	end

	-- save the inputs
	set_next("inputs", save_struct)
end

local function load_input_frame()
	local inputs_struct = recording.inputs[player.frame]
	local index = 0
	local read_next_input = function()
		index = index + 1
		return inputs_struct[index]
	end

	-- read buttons
	frame_input.buttons = read_next_input()

	-- read crank
	frame_input.isCrankDocked = read_next_input()

	if frame_input.isCrankDocked then
		frame_input.crankPos = 0
		frame_input.crankeDelta = 0
		frame_input.crankAcc = 0
	else
		frame_input.crankPos = unserialize_number( read_next_input() )
		frame_input.crankeDelta = unserialize_number( read_next_input() )
		frame_input.crankAcc = unserialize_number( read_next_input() )
	end

	frame_input.accRunning = read_next_input()

	if frame_input.accRunning then
		frame_input.accData[1] = unserialize_number( read_next_input() )
		frame_input.accData[2] = unserialize_number( read_next_input() )
		frame_input.accData[3] = unserialize_number( read_next_input() )
	else
		frame_input.accData[1] = 0
		frame_input.accData[2] = 0
		frame_input.accData[3] = 0
	end
end

local function playback_frame()
	player.frame = player.frame + 1

	if not recording.inputs[player.frame] then
		reached_end_of_recording()
		return
	end

	-- load inputs for this frame
	load_input_frame()

	-- call original playdate.update()
	og.update()
end


-- function to call at the end of main.lua
-- used to overload user callbacks like playdate.update()
function betamax_eof( frame_jump )
	og.update = playdate.update
	og.gameWillPause = playdate.gameWillPause
	og.gameWillTerminate = playdate.gameWillTerminate

	-- playback update
	if is_playback then
		playdate.update = function()
			if og.buttonIsPressed(playdate.kButtonRight) then
				for i=1, 10 do
					playback_frame()
				end
			else
				playback_frame()
			end
		end

	-- recording update
	else
		playdate.update = function()
			-- process and save current inputs
			save_input_frame()

			player.frame = #recording.inputs

			-- call original playdate.update()
			og.update()
		end

		playdate.gameWillPause = function()
			save_recording()
			og.gameWillPause()
		end
	end

	-- fast forward
	if is_playback and frame_jump then
		if frame_jump<0 then
			frame_jump = (#recording.inputs) + frame_jump
		end
		frame_jump = math.clamp(frame_jump, 1, #recording.inputs)

		print("jump to:", frame_jump)

		while ( player.frame~=frame_jump ) do
			playdate.update()
		end
	end
end

function betamax_frame()
	print("Betamax current frame:", player.frame)
end