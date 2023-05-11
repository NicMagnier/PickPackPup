
rectangle = {_lieb_type = "rectangle"}
rectangle.__index = rectangle

function rectangle.new(x,y,w,h)
	if rectangle.is(x) then
		local copy_rectangle = x
		x = copy_rectangle.x
		y = copy_rectangle.y
		w = copy_rectangle.w
		h = copy_rectangle.h
	end
	return setmetatable({x = x or 0, y = y or 0, w = w or 0, h = h or 0}, rectangle)
end

function rectangle:Copy()
	return rectangle.new(self)
end

function rectangle:__tostring()
	return "rectangle("..tonumber(self.x)..","..tonumber(self.y)..","..tonumber(self.w)..","..tonumber(self.h)..")"
end

function rectangle:__unm()
	return rectangle.new(-self.x-self.w, -self.y-self.h, self.w, self.h)
end

function rectangle:__add(a)
	if vector.is(a) then
		return rectangle.new(self.x + a.x, self.y + a.y, self.w, self.h)
	end

	assert(rectangle.is(self) and rectangle.is(a), "Incorrect argument type in rectangle:__add ("..type(self)..","..type(a)..")")
	local left = min(self:Left(),a:Left())
	local right = max(self:Right(),a:Right())
	local top = min(self:Top(),a:Top())
	local bottom = max(self:Bottom(),a:Bottom())

	return rectangle.new(left, top, right-left, bottom-top)
end

function rectangle:__sub(a)
	if vector.is(a) then
		return rectangle.new(self.x - a.x, self.y - a.y, self.w, self.h)
	end

	assert(rectangle.is(self) and rectangle.is(a), "Incorrect argument type in rectangle:__sub ("..type(self)..","..type(a)..")")

	local left = max(self:Left(),a:Left())
	local right = min(self:Right(),a:Right())
	local top = max(self:Top(),a:Top())
	local bottom = min(self:Bottom(),a:Bottom())

	local width = right - left
	if width<0 then width = 0 end

	local height = bottom - top
	if height<0 then height = 0 end

	return rectangle.new(left, top, width, height)
end

function rectangle:__mul(a)
	assert( type(a) == "number", "Incorrect argument type in rectangle:__mul ("..type(a)..")")
	return rectangle.new(self.x*a, self.y*a, self.w*a, self.h*a)
end

function rectangle:__div(a)
	assert( type(a) == "number", "Incorrect argument type in rectangle:__div ("..type(a)..")")
	return rectangle.new(self.x/a, self.y/a, self.w/a, self.h/a)
end

function rectangle:__eq(a)
	return self.x == a.x and self.y == a.y and self.w == a.w and self.h == a.h
end

function rectangle:Left()	return min(self.x, self.x+self.w)	end
function rectangle:Right()	return max(self.x, self.x+self.w)	end
function rectangle:Top()	return min(self.y, self.y+self.h)	end
function rectangle:Bottom()	return max(self.y, self.y+self.h)	end

function rectangle:Position()	return vector.new(self.x, self.y)	end
function rectangle:xywh()
	return self.x, self.y, self.w, self.h
end

function rectangle:Collide(a)
	if rectangle.is(a) then
		if self:Left() >= a:Right() then return false end
	    if self:Right() <= a:Left() then return false end
	    if self:Top() >= a:Bottom() then return false end
	    if self:Bottom() <= a:Top() then return false end

	    return true
	end

	if vector.is(a) then
		if a.x <= self:Left() then return false end
	    if a.y <= self:Top() then return false end
	    if a.x >= self:Right() then return false end
	    if a.y >= self:Bottom() then return false end

	    return true
	end
end

local function _collision_1d_segments(min1,max1, min2,max2)
	if min1 >= max2 then return false end
	if max1 <= min2 then return false end
	return true
end

function rectangle:Move(a,v)
	if not vector.is(v) then return vector.new() end
	if not rectangle.is(a) then return v end

	-- test on the x axis
	local x_scale = 1
	local x_precise = v.x
	if v.x > 0 then
		x_scale = (a:Left()-self:Right()) / v.x
		x_precise = a:Left()-self:Right()
	else
		x_scale = (a:Right()-self:Left()) / v.x
		x_precise = a:Right()-self:Left()
	end

	if x_scale>=0 and x_scale<1 then
		local vy = v.y*x_scale
		if not _collision_1d_segments(a:Top(),a:Bottom(), self:Top()+vy,self:Bottom()+vy) then
			x_scale = 1
		end
	else
		x_scale = 1
	end

	-- test on the y axis
	local y_scale = 1
	local y_precise = v.y
	if v.y > 0 then
		y_scale = (a:Top()-self:Bottom()) / v.y
		y_precise = a:Top()-self:Bottom()
	else
		y_scale = (a:Bottom()-self:Top()) / v.y
		y_precise = a:Bottom()-self:Top()
	end

	if y_scale>=0 and y_scale<1 then
		local vx = v.x*y_scale
		if not _collision_1d_segments(a:Left(),a:Right(), self:Left()+vx,self:Right()+vx) then
			y_scale = 1
		end
	else
		y_scale = 1
	end

	-- no collision found, we return the vector intact
	if x_scale==1 and y_scale==1 then
		return v
	end

	if x_scale<y_scale then
		return new(vector, x_precise, v.y*x_scale)
	else
		return new(vector, v.x*y_scale, y_precise)
	end
end

-- move a rectangle horizontaly
-- faster to call move_h() + move_v() than move()
function rectangle:Move_h(a,x)
	x = x or 0
	if not rectangle.is(a) then return x end

	local result = x

	if x==0 then return 0 end

	if x > 0 then
		if self:Right() > a:Right() then return x end
		if self:Right()+x <= a:Left() then return x end
		result = max(0, a:Left() - self:Right())
	else
		if self:Left() < a:Left() then return x end
		if self:Left()+x >= a:Right() then return x end
		result = min(0, a:Right() - self:Left())
	end

	if _collision_1d_segments(a:Top(),a:Bottom(), self:Top(),self:Bottom()) then
		return result
	end

	return x
end

-- move a rectangle verticaly
-- faster to call move_h() + move_v() than move()
function rectangle:Move_v(a,y)
	y = y or 0
	if not rectangle.is(a) then return y end

	local result = y

	if y==0 then return 0 end

	if y > 0 then
		if self:Bottom() > a:Bottom() then return y end
		if self:Bottom()+y <= a:Top() then return y end
		result = max(0, a:Top() - self:Bottom())
	else
		if self:Top() < a:Top() then return y end
		if self:Top()+y >= a:Bottom() then return y end
		result = min(0, a:Bottom() - self:Top())
	end

	if _collision_1d_segments(a:Left(),a:Right(), self:Left(),self:Right()) then
		return result
	end

	return y
end

-- create a new position for the rectangle in case it overlap another rectangle
function rectangle:Solve_overlap(a)
	if not self:Collide(a) then
		return self
	end

	local left = self:Right() - a:Left()
	local right = a:Right() - self:Left()
	local x_axis = min(left,right)

	local up = self:Bottom() - a:Top()
	local down = a:Bottom() - self:Top()
	local y_axis = min(up,down)

	local shift = new(vector)

	if x_axis<y_axis then
		if left<right then
			shift.x = -left
		else
			shift.x = right
		end
	else
		if up<down then
			shift.y = -up
		else
			shift.y = down
		end
	end

	return self + shift
end

function rectangle.is(a)
	if type(a)~="table" then return false end
	if a._lieb_type~="rectangle" then return false end
	if type(a.x)~="number" then return false end
	if type(a.y)~="number" then return false end
	if type(a.w)~="number" then return false end
	if type(a.h)~="number" then return false end
	return true
end

-- add metamethods to the class
rectangle = setmetatable(rectangle, {
	__call = function(self,x,y,w,h) return setmetatable({x = x or 0, y = y or 0, w = w or 0, h = h or 0}, rectangle) end
})