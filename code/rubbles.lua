rubbles = {}

local _active_count = 0
local _list = {}

local _rumble_images = {
	playdate.graphics.image.new('images/rubble_01'),
	playdate.graphics.image.new('images/rubble_02'),
	playdate.graphics.image.new('images/rubble_03'),
}

for i=1, 16 do
	local new_rubble = {
		x = 0,
		y = 0,
		fall_speed = 0,
		sprite = playdate.graphics.sprite.new(),
	}

	new_rubble.sprite:setCenter(0,0)
	new_rubble.sprite:setVisible(false)
	new_rubble.sprite:setZIndex(layer.rubbles)

	table.insert(_list, new_rubble)
end

function rubbles.reset()
	for index, rubble in pairs(_list) do
		rubble.sprite:setVisible(false)
		rubble.sprite:remove()
	end
	_active_count = 0
end

function rubbles.update( dt )
	if _active_count==0 then
		return
	end

	_active_count = 0
	for index, rubble in pairs(_list) do
		if rubble.sprite:isVisible() then
			rubble.y = rubble.y + rubble.fall_speed * dt

			local sprite = rubble.sprite
			if rubble.y>240 then
				sprite:setVisible(false)
				sprite:remove()
			else
				sprite:moveTo(rubble.x, rubble.y)
				_active_count = _active_count + 1
			end
		end
	end
end

function rubbles.spawn( count )
	count = max(count, 0)

	while count>0 do
		-- find a free rubble
		local new_rubble = nil
		for index, rubble in pairs(_list) do
			if rubble.sprite:isVisible()==false then
				new_rubble = rubble
				break
			end
		end

		if new_rubble==nil then
			print("Warning, no more free rubble")
			return
		end

		-- setup rubble
		new_rubble.x = rand(0,380)
		new_rubble.y = rand(-200,0)
		new_rubble.fall_speed = rand(300,500)

		local sprite = new_rubble.sprite
		sprite:setVisible(true)
		sprite:setImage(table.random(_rumble_images))
		sprite:moveTo(new_rubble.x, new_rubble.y)
		sprite:add()

		_active_count = _active_count + 1

		count = count - 1 
	end
end