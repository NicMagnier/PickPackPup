anim_loop = {}
anim_loop.__index = anim_loop

-- create a list of anim
function anim_loop.new()
	local result = {
		imageTable = nil,
		delay = 100,
		loop = true,

		imageCache = nil,
		time = 0,
	}

	return setmetatable(result, anim_loop)
end

function anim_loop:update( dt )
	if self.loop then
		self.time = math.ring( self.time + dt, 0, self:duration())
	else
		self.time = self.time + dt
	end

	self.imageCache = nil
end

function anim_loop:image()
	if self.imageCache then
		return self.imageCache
	end

	local delay = self.delay/1000
	local frame = math.clamp(1 + math.floor(self.time/delay), 1, #self.imageTable)
	self.imageCache = self.imageTable[frame]

	return self.imageCache
end

function anim_loop:isValid()
	return self.loop or self.time<self:duration()
end

function anim_loop:duration()
	return (self.delay/1000)*#self.imageTable
end

function anim_loop:draw( x, y)
	self:image():draw(x,y)
end