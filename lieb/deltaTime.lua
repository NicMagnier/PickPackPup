local _lastUpdateTime = nil
local _cachedDeltaTime = nil

local _historySize = 5
local _history = table.create(_historySize)
local _historyIndex = 1

function updateDeltaTime()
	local now = playdate.getCurrentTimeMilliseconds()

	if not _lastUpdateTime then
		_lastUpdateTime = now
		_cachedDeltaTime = 0

		-- initialize history with target delta time
		local idealDeltaTime = 1 / playdate.display.getRefreshRate()
		for i = 1, _historySize do
			_history[i] = idealDeltaTime
		end

		return _cachedDeltaTime
	end

	local newDeltaTime = max( 0, (now-_lastUpdateTime) / 1000 )

	-- calculate min and max from the history
	local minDeltaTime = newDeltaTime
	local maxDeltaTime = newDeltaTime
	local totalDeltaTime = newDeltaTime
	for i = 1, _historySize do
		totalDeltaTime = totalDeltaTime + _history[i]

		if _history[i] < minDeltaTime then minDeltaTime = _history[i] end
		if _history[i] > maxDeltaTime then maxDeltaTime = _history[i] end
	end

	-- calculate the average without the possible outliers
	_cachedDeltaTime = (totalDeltaTime - minDeltaTime - maxDeltaTime) / (1 + _historySize - 2)

	-- update history
	_history[ _historyIndex ] = _cachedDeltaTime
	_historyIndex = 1 + _historyIndex%_historySize

	return _cachedDeltaTime
end

function getDeltaTime()
	return _cachedDeltaTime
end