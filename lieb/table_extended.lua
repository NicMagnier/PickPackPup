function table.random( t )
	if type(t)~="table" then return nil end
    return t[math.ceil(rand(#t))]
end

-- remove all elements of the table
-- slower than assigning a new empty table, but avoid trashing the memory
function table.reset( t )
	for key, value in pairs(t) do
		t[key] = nil
	end
end

-- insert a new element if it is unique (i.e. the same object)
function table.insert_unique( t, o)
	-- specific to playdate SDK
	if table.indexOfElement( t, o)==nil then
		table.insert( t, o)
		return true
	end

	return false
end

function table.last( t )
    return t[#t]
end

function table.each( t, fn )
	if not fn then return end
	for _, e in pairs(t) do
		fn(e)
	end
end

function table.copy( t )
	local copy = {}
	for k,v in pairs(t) do
		copy[k] = v
	end
	return copy
end
