--[[
class to create simple animations using easing as building blocks

To create a simple sequence:
	v = anim.from(0):To(1,2.0,"soft-out"):Mirror()

To create a animation that change multiple values
	v = anim.new({
		x = anim.from(0):To(1,1.0):Mirror(),
		y = anim.from(12):To(0,1.0):Mirror()
	})

To create an animation loaded by the asset class (support hot reloading)
	v = anim.from_asset("file.anim")

Other important functions
	v:Update(dt)
	v:Get()
	v:Get_key("x")

]]--

-- TODO
--	function to change initial value to help transitioning from the current value to a target values
--	:Callback(fn,...)

anim = {}
anim.__index = anim

-- create a list of anim
function anim.new()
	local result = {
		time = 0,
		duration = 0,
		loop = false,
		last_easing = 0,
		sequence = table.create(4, 0),

		has_cached_result = false,
		cached_result = 0,
		previous_update_easing_index = nil
	}

	return setmetatable(result, anim)
end

function anim:Init()
	self.last_easing = 0

	self.time = 0
	self.duration = 0
	self.loop = false
	self.last_easing = 0
	self.has_cached_result = false
	self.cached_result = 0
	self.previous_update_easing_index = nil
end

-- Reinitialize the anim sequence
function anim:From(from)
	from = from or 0

	-- release all easings
	self:Init()

	-- allocate the easing
	self.last_easing = self.last_easing + 1
	local new_easing = self:Get_easing_by_index(self.last_easing)

	-- setup first empty easing at the beginning of the sequence
	new_easing.timestamp = 0
	new_easing.from = from
	new_easing.to = from
	new_easing.duration = 0
	new_easing.fn = easing.flat

	return self
end

-- easing_type: format of easing "easing-in-loop"
--	easings: "linear", "blink", "cos", "soft2", "soft3", "soft4", "smoothstep", "circ", "back", "expo", "bounce", "elastic"
--	type: "in", "out", "inout", "outin"
function anim:To(to, duration, easing_type)
	if not self then return end

	-- default parameters
	to = to or 0
	duration = duration or 0
	easing_type = easing_type or "soft2-inout"

	local last_easing = self.sequence[self.last_easing]

	-- allocate the easing
	self.last_easing = self.last_easing + 1
	local new_easing = self:Get_easing_by_index(self.last_easing)

	-- setup first empty easing at the beginning of the sequence
	new_easing:init(easing_type, last_easing.to, to, duration, last_easing.timestamp + last_easing.duration)

	-- update overall sequence infos
	self.duration = self.duration + duration

	return self
end

function anim:Set(value)
	if not self then return end

	local last_easing = self.sequence[self.last_easing]

	-- allocate the easing
	self.last_easing = self.last_easing + 1
	local new_easing = self:Get_easing_by_index(self.last_easing)

	-- setup first empty easing at the beginning of the sequence
	new_easing.timestamp = last_easing.timestamp + last_easing.duration
	new_easing.from = value
	new_easing.to = value
	new_easing.duration = 0
	new_easing.fn = easing.flat

	-- update overall sequence infos
	self.duration = self.duration + duration

	return self
end

-- @number: number of times the last easing as to be duplicated
-- @mirror: does the repeating easings have to be mirrored (yoyo effect)
function anim:Repeat(number,mirror)
	if not self then return end
	if not number or number==0 then return self end

	local previous_easing = self.sequence[self.last_easing]

	for i = 1, number do
		-- allocate the easing
		self.last_easing = self.last_easing + 1
		local new_easing = self:Get_easing_by_index(self.last_easing)

		-- setup first empty easing at the beginning of the sequence
		new_easing.timestamp = previous_easing.timestamp + previous_easing.duration
		new_easing.duration = previous_easing.duration
		new_easing.fn = previous_easing.fn
		new_easing.param = previous_easing.param

		if mirror then
			new_easing.from = previous_easing.to
			new_easing.to = previous_easing.from
		else
			new_easing.from = previous_easing.from
			new_easing.to = previous_easing.to
		end

		-- update overall sequence infos
		self.duration = self.duration + duration

		previous_easing = new_easing
	end

	return self
end

function anim:Sleep(duration)
	if not self then return end

	if duration==0 then return self end

	local previous_easing = self.sequence[self.last_easing]

	-- allocate the easing
	self.last_easing = self.last_easing + 1
	local new_easing = self:Get_easing_by_index(self.last_easing)

	-- setup first empty easing at the beginning of the sequence
	new_easing.timestamp = previous_easing.timestamp + previous_easing.duration
	new_easing.from = previous_easing.to
	new_easing.to = previous_easing.to
	new_easing.duration = duration
	new_easing.fn = easing.flat

	-- update overall sequence infos
	self.duration = self.duration + duration

	return self
end

function anim:Loop()
	self.loop = "loop"
	return self
end

function anim:Mirror()
	self.loop = "mirror"
	return self
end

function anim:Update(dt)
	self.time = self.time + dt
	self.has_cached_result = false
end

function anim:Get_easing_by_index(index)
	if self.sequence[index] then return self.sequence[index] end

	local new_easing = easing.new({
		timestamp = 0,
		from = 0,
		to = 0,
		duration = 0,
		fn = easing.flat
	})

	self.sequence[index] = new_easing

	return new_easing
end

function anim:Get_easing_by_time(clamped_time)
	if self:Is_empty() then
		print("anim warning: empty animation")
		return nil, 0
	end

	local easing_index = self.previous_update_easing_index or 1

	while easing_index>=1 and easing_index<=self.last_easing do
		local easing = self.sequence[easing_index]

		if clamped_time<easing.timestamp then
			easing_index = easing_index - 1
		elseif clamped_time>(easing.timestamp+easing.duration) then
			easing_index = easing_index + 1
		else
			self.previous_update_easing_index = easing_index
			return easing, easing_index
		end
	end

	-- we didn't the correct part
	print("anim warning: couldn't find sequence part. clamped_time probably out of bound.", clamped_time, self.duration)
	return self.sequence[1], 1
end

function anim:Get(time)
	if not self then return nil end
	if self:Is_empty() then
		return 0
	end

	local use_cache = false
	if not time then
		time = self.time
		use_cache = true
	end

	-- try to get cached result
	if use_cache and self.has_cached_result then
		return self.cached_result
	end

	-- we get clamped time for the sequence
	time = self:_get_clamped_time(time)

	-- we calculate and cache the result
	local result = self:Get_easing_by_time(time):Get(time)
	if use_cache then
		self.has_cached_result = true
		self.cached_result = result
	end

	return result
end

-- get the time clamped in the sequence duration
-- manage time using loop setting
function anim:_get_clamped_time(time)
	time = time or self.time

	-- time is looped
	if self.loop=="loop" then
		return time%self.duration

	-- time is mirrored / yoyo
	elseif self.loop=="mirror" then
		time = time%(self.duration*2)
		if time>self.duration then
			time = self.duration + self.duration - time
		end

		return time
	end

	-- time is normally clamped
	return math.clamp(time, 0, self.duration)
end

function anim:Restart()
	self.time = 0
	self.has_cached_result = false
end

function anim:Is_done()
    return self.time>self.duration
end

function anim:Is_empty()
    return self.last_easing==0
end