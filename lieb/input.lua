buttonLeft = playdate.kButtonLeft
buttonRight = playdate.kButtonRight
buttonUp = playdate.kButtonUp
buttonDown = playdate.kButtonDown
buttonA = playdate.kButtonA
buttonB = playdate.kButtonB

input = {
	repeatDuration = 0.12,
	repeats = {
		[buttonLeft] = {state = false, timer = 0},
		[buttonRight] = {state = false, timer = 0},
		[buttonUp] = {state = false, timer = 0},
		[buttonDown] = {state = false, timer = 0},
		[buttonA] = {state = false, timer = 0},
		[buttonB] = {state = false, timer = 0}
	},

	isCrankDocked = {previous = nil, current = nil},

	is_recording = true,
}

local _buttonFrameState = 0

-- input.is = playdate.buttonIsPressed
input.on = playdate.buttonJustPressed
input.off = playdate.buttonJustReleased

function input.onRepeat( buttonId )
	return input.repeats[buttonId].state
end

function input.update( dt )
	-- Save the button for this frame because playdate.buttonIsPressed always return latest result 
	local isPressed = playdate.buttonIsPressed
	_buttonFrameState = 0
	if isPressed(playdate.kButtonA)		then _buttonFrameState = _buttonFrameState | playdate.kButtonA end
	if isPressed(playdate.kButtonB)		then _buttonFrameState = _buttonFrameState | playdate.kButtonB end
	if isPressed(playdate.kButtonUp)	then _buttonFrameState = _buttonFrameState | playdate.kButtonUp end
	if isPressed(playdate.kButtonDown)	then _buttonFrameState = _buttonFrameState | playdate.kButtonDown end
	if isPressed(playdate.kButtonLeft)	then _buttonFrameState = _buttonFrameState | playdate.kButtonLeft end
	if isPressed(playdate.kButtonRight)	then _buttonFrameState = _buttonFrameState | playdate.kButtonRight end

	for buttonId, buttonRepeat in pairs(input.repeats) do
		buttonRepeat.timer = buttonRepeat.timer + dt

		if input.on(buttonId) or ( input.is(buttonId) and buttonRepeat.timer > input.repeatDuration ) then
			buttonRepeat.state = true
			buttonRepeat.timer = 0
		elseif input.is(buttonId)==false then
			buttonRepeat.state = false
			buttonRepeat.timer = 0
		else
			buttonRepeat.state = false
		end
	end

	local isCrankDocked = input.isCrankDocked
	isCrankDocked.previous = isCrankDocked.current
	isCrankDocked.current = playdate.isCrankDocked()
end

function input.is( button )
	return (_buttonFrameState&button)~=0
end

function input.onCrankDock()
	local isCrankDocked = input.isCrankDocked
	return isCrankDocked.previous==false and isCrankDocked.current==true
end

function input.onCrankUndock()
	local isCrankDocked = input.isCrankDocked
	return isCrankDocked.previous==true and isCrankDocked.current==false
end

function input.reset()
	for buttonId, buttonRepeat in pairs(input.repeats) do
		buttonRepeat.state = false
		buttonRepeat.timer = 0
	end
end