
vector = {_lieb_type = "vector"}
vector.__index = vector

function vector.new(x,y)
	if vector.is(x) then
		local copy_vector = x
		x = copy_vector.x
		y = copy_vector.y
	end
	return setmetatable({x = x or 0, y = y or 0}, vector)
end

function vector:Copy()
	return vector.new(self)
end

function vector:__tostring()
	return "vector("..tonumber(self.x)..","..tonumber(self.y)..")"
end

function vector:__unm()
	return vector.new(-self.x, -self.y)
end

function vector:__add(a)
	if rectangle.is(a) then
		return rectangle.new(self.x + a.x, self.y + a.y, a.w, a.h)
	end

	assert(vector.is(self) and vector.is(a), "Incorrect argument type in vector:__add ("..type(self)..","..type(a)..")")
	return vector.new(self.x+a.x, self.y+a.y)
end

function vector:__sub(a)
	assert(vector.is(self) and vector.is(a), "Incorrect argument type in vector:__sub ("..type(self)..","..type(a)..")")
	return vector.new(self.x-a.x, self.y-a.y)
end

function vector:__mul(a)
	if type(a) == "number" then
		return vector.new(self.x*a, self.y*a)
	else
		assert(vector.is(a), "Incorrect argument type in vector:__mul ("..type(self)..","..type(a)..")")
		return vector.new(self.x*a.x, self.y*a.y)
	end
end

function vector:__div(a)
	if type(a) == "number" then
		return vector.new(self.x/a, self.y/a)
	else
		assert(vector.is(a), "Incorrect argument type in vector:__div ("..type(self)..","..type(a)..")")
		return vector.new(self.x/a.x, self.y/a.y)
	end
end

function vector:__eq(a)
	return self.x == a.x and self.y == a.y
end

function vector:__lt(a)
	return self.x < a.x or (self.x == a.x and self.y < a.y)
end

function vector:__le(a)
	return self.x <= a.x and self.y <= a.y
end

function vector:Dot(a)
	assert(vector.is(a), "Incorrect argument type in vector:dot ("..type(self)..","..type(a)..")")
	return self.x*a.x + self.y*a.y
end
function vector:Cross(a)
	assert(vector.is(a), "Incorrect argument type in vector:cross ("..type(self)..","..type(a)..")")
	return self.x*a.y - self.y*a.x
end

function vector:Set_angle(angle,radius)
	radius = radius or 1
	self.x = math.cos(angle) * radius
	self.y = math.sin(angle) * radius
end

function vector:Get_angle()
	return math.atan2(self.x, self.y)
end

vector.Len = vector.Get_length
function vector:Get_length()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function vector:Distance(a)
	return (self-a):Get_length()
end

function vector:Normalize()
	local l = self:Get_length()
	return vector.new(self.x/l, self.y/l)
end

function vector:xy()
	return self.x, self.y
end

function vector.is(a)
	if type(a)~="table" then return false end
	if a._lieb_type~="vector" then return false end
	if type(a.x)~="number" then return false end
	if type(a.y)~="number" then return false end
	return true
end

-- add metamethods to the class
vector = setmetatable(vector, {
	__call = function(self,x,y) return setmetatable({x = x or 0, y = y or 0}, vector) end
})