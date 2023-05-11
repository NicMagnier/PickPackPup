-- create a new object based on a class
-- will call automatically the new function of the class if it has one
-- local pos = new(vector,0,1)	
function new(class,...)
	if not class then return {} end

	if type(class.new)=="function" then
		return class.new(...)
	end

	-- make sure the class has the proper fallback
	class.__index = class

	new_object = select(1, ...)
	if type(new_object)~="table" then
		new_object = {}
	end

	-- init metatables
	return setmetatable(new_object, object)
end
