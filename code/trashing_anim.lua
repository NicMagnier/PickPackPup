local _anim_y = sequence.new():from(0):to( 240, 0.5, "inBack")
local _anim_x_list = {
	sequence.new():from(0):sleep(rand(0,0.6)):to( rand(-100, 0), 0.5),
	sequence.new():from(0):sleep(rand(0,0.6)):to( rand(0, 100), 0.5),
	sequence.new():from(0):sleep(rand(0,0.6)):to( rand(-50, 0), 0.5),
	sequence.new():from(0):sleep(rand(0,0.6)):to( rand(0, 50), 0.5),
	sequence.new():from(0):sleep(rand(0,0.6)):to( rand(-50, 50), 0.5),
}

local _next = 1

function startTrashAnim()
	_anim_y:restart()
	for index, seq in pairs(_anim_x_list) do
		seq:restart()
	end
end

function getTrashAnim()
	_next = math.ring_int(_next+rand_int(1,4), 1, #_anim_x_list)
	return _anim_x_list[_next], _anim_y
end