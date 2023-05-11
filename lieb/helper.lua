
local _lastRefreshTime = nil
function getDeltaTime_Legacy( time_type )
	time_type = time_type or "variable"

	if time_type=="fixed" then
		return 1 / playdate.display.getRefreshRate()
	end

	if time_type=="variable" then
		local currentTime = playdate.getCurrentTimeMilliseconds()

		if not _lastRefreshTime then
			_lastRefreshTime = currentTime
			return 0
		end

		local result = max( 0, (currentTime/1000) - (_lastRefreshTime/1000) )
		_lastRefreshTime = currentTime

		return result
	end

	return 1/30
end

function rand(min, max)
	local random_number = math.random()

	if min==nil and max==nil then
		return random_number
	end

	if not max then max = 0 end
	if min > max then
		local swap = min
		min = max
		max = swap
	end

	return min + (max-min)*random_number
end

function rand_int(min, max)
	return math.ceil(min + math.ceil(rand(0,max-min+1)-1))
end

function hasLocalizedText( key, language )
	return key~=playdate.graphics.getLocalizedText(key, language)
end

function loc_format( key, ...)
	local text = loc(key)
	local arg = {...}

	-- limited number of argument, but avoid making text manupulation to create {X}
	if arg[1] then text = text:gsub("{1}", arg[1]) end
	if arg[2] then text = text:gsub("{2}", arg[2]) end
	if arg[3] then text = text:gsub("{3}", arg[3]) end
	return text
end

function call( fn, ...)
	if type(fn)=="function" then
		fn(...)
	end
end

function enum( t )
	local result = {}

	for index, name in pairs(t) do
		result[name] = index
	end

	return result
end