--[[
	Simple State class

game_mode = new(state, "intro")
game_mode:Set("gameplay")
game_mode:Get()

______

The state can be also an object
Properties and function of the object can be directly access with the state object

gameplay = {
	time = 0
	update = function() ... end
	draw = function() ... end
}
game_mode:Set(gameplay)
game_mode.time
game_mode.update()
game_mode.missing_function()

By default when a property is missing, it returns an empty function.
It enables to call functions without triggering an error even if they are not all defined in all objects use as state
However if a number is not defined or nil it will also return a function
]]--

state = {}
state.__index = function(self, key)
	-- if this is a standard key in the state class, we simply return it
	if state[key] then return state[key] end

	-- check if we should get a property of the current state
	-- can return an empty function if the property is not defined
	-- (as it lets the user call a function even if the property is not defined)
	if type(self.current)=="table" then
		return self.current[key] or function() end
	end

	return nil
end

-- create a new state
-- @current_state: initial state (can be any type of value)
function state.new(current_state)
	return setmetatable({
		current = current_state
	}, state)
end

function state:Set(state)
	self.current = state
end

function state:Get()
	return self.current
end

function state:Is(state)
	return self.current==state
end