-- TODO anim: Bezier function as an easing function

easing = {
	timestamp = 0,		-- at what time the easing start (delay)
	from = 0,
	to = 1,
	duration = 1,
	fn = nil,			-- function that take normalized time (between 0 and 1) and an optional parameter
	param = nil,		-- object sent as parameter to dn
	timing = "in"		-- type of easing time "in", "out", "inout", "outin"
}
easing_parse_cache = {}
easing.__index = easing

function easing.new(easing_type,from,to,duration,delay)
	local new_object

	if type(easing_type)=="string" then
		local fn, timing = easing.parse(easing_type)
		new_object = {
			timestamp = delay,
			from = from,
			to = to,
			duration = duration,
			fn = fn,
			timing = timing
		}
	else
		new_object = easing_type or {}
	end

	-- default paramaters
	if not new_object.param then
		if new_object.fn==easing.soft		then new_object.param = 2.5 end
		if new_object.fn==easing.back		then new_object.param = 1.70158 end
		if new_object.fn==easing.elastic	then new_object.param = {period=0.32, amplitude=(2/4)} end
	end

	return setmetatable(new_object, easing)
end

function easing:init(easing_type,from,to,duration,delay)
	if not self then return end
	if type(easing_type)~="string" then return end

	local fn, timing = easing.parse(easing_type)

	self.timestamp = delay
	self.from = from
	self.to = to
	self.duration = duration
	self.fn = fn
	self.timing = timing

	if self.fn==easing.soft		then self.param = 2.5 end
	if self.fn==easing.back		then self.param = 1.70158 end
	if self.fn==easing.elastic	then self.param = {period=0.32, amplitude=(2/4)} end
end

function easing.copy(easing_object)
	return easing.new(copy(easing_object))
end

function easing.parse(easing_type)
	-- check if we have it in the cache
	local cached_result = easing_parse_cache[easing_type]
	if cached_result then
		return cached_result.fn, cached_result.timing
	end

	-- if not in cache, we properly parse it
	local params = easing_type:split('-')
	local fn = easing.soft
	local timing = "inout"

	for k,p in pairs(params) do
		if easing[p] then
			fn = easing[p]
		else
			timing = p
		end
	end

	-- cache the result
	easing_parse_cache[easing_type] = {
		fn = fn,
		timing = timing
	}

	return fn, timing
end

function easing:Get(time)
	if self.duration==0 then
		return self.to
	end

	-- scale time to be normalized
	local nt = (time-self.timestamp) / self.duration

	-- scale result
	return self.from + self:_get_normalized(nt)*(self.to-self.from)
end

function easing:_get_normalized(nt)
	if not self.fn then
		return 0
	end

	-- easing in
	local l_easeIn = function(self, nt)
		return self.fn(nt,self.param)
	end

	-- easing out
	local l_easeOut = function(self, nt)
		return 1-self.fn(1-nt,self.param)
	end

	-- easing type
	if self.timing=="out" then
		return l_easeOut(self, nt)

	elseif self.timing=="inout" then
		if nt < 0.5 then return 0.5*l_easeIn(self,nt*2) end
		return 0.5+0.5*l_easeOut(self,(nt-0.5)*2)

	elseif self.timing=="outin" then
		if nt < 0.5 then return 0.5*l_easeOut(self,nt*2) end
		return 0.5+0.5*l_easeIn(self,(nt-0.5)*2)
	end

	-- "in"
	return l_easeIn(self, nt)
end


-- All easing functions
-- nt: normalized time (between 0 and 1)

function easing.flat(nt)		return 0 end
function easing.linear(nt)		return nt end
function easing.blink(nt)		if nt < 0.5 then return 0 else return 1 end end
function easing.sine(nt)		return (1-math.sin((nt+1)*math.pi/2)) end
function easing.soft(nt,p)		return nt^p end
function easing.soft2(nt)		return nt*nt end
function easing.soft3(nt)		return nt*nt*nt end
function easing.soft4(nt)		return nt*nt*nt*nt end
function easing.circ(nt)		return(-1 * (math.sqrt(1 - math.pow(nt, 2)) - 1)) end
function easing.back(nt,p)		return nt * nt * ((p + 1) * nt - p) end
function easing.rand(nt)		return love.math.random() end				-- plain random between 0 and 1
function easing.randfade(nt)	return nt*love.math.random() end			-- increase randomness over time; ends between 0 and 1
function easing.randfunnel(nt)	return (nt*2)*love.math.random()-nt end		-- increase randomness over time but with a funnel shape; ends between 1 and -1
function easing.expo(nt)
    if nt == 0 then
      return 0
    else
      return math.pow(2, 10 * (nt - 1))
    end
end
function easing.bounce(nt)
    local t = 1 - nt
    if t < 1 / 2.75 then
      return 1 - (7.5625 * t * t)
    elseif t < 2 / 2.75 then
      t = t - (1.5 / 2.75)
      return 1 - (7.5625 * t * t + 0.75)
    elseif t < 2.5 / 2.75 then
      t = t - (2.25 / 2.75)
      return 1 - (7.5625 * t * t + 0.9375)
    else
      t = t - (2.625 / 2.75)
      return 1 - (7.5625 * t * t + 0.984375)
    end
end
function easing.elastic(nt, p)
  if nt == 0 then return 0 end
  if nt == 1 then return 1 end

  if type(p)~='table' then p = {} end

  if not p.period then p.period = 0.3 end

  local s

  if not p.amplitude or p.amplitude < 1 then
    p.amplitude = 1
    s = p.period / 4
  else
    s = p.period / (2 * math.pi) * math.asin(1/p.amplitude)
  end

  nt = nt - 1

  return -(p.amplitude * math.pow(2, 10 * nt) * math.sin((nt - s) * (2 * math.pi) / p.period))
end