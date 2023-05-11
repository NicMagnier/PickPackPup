custom_tileset = {
	list = table.create(4),
	enable = false
}

-- private member
local _tile_list = table.create(100)
local _slots = table.create(4)
for i=1,4 do
	table.insert(_slots,{
		index = 1,
		anim = sequence.new()
	})
end
local _slot_selected = 1
local _enable_anim = sequence.new()

local _background = playdate.graphics.image.new( "images/custom_tileset_background" )
local _arrow = playdate.graphics.image.new("images/custom_tileset_arrow")
	
function custom_tileset.init()
	table.reset(_tile_list)

	local add_tileset_to_list = function(tileset_name)
		for index, tiletype in pairs(tilesets[tileset_name]) do
			table.insert(_tile_list, tiletype)
		end
	end

	add_tileset_to_list("geometric")
	add_tileset_to_list("default")
	add_tileset_to_list("tutorial")
	add_tileset_to_list("fruit")
	add_tileset_to_list("book")
	add_tileset_to_list("playdate")
	add_tileset_to_list("dogs")
	add_tileset_to_list("pasta")
	add_tileset_to_list("tetromino")
	add_tileset_to_list("space")
	add_tileset_to_list("cosmetics")
	add_tileset_to_list("holiday")

	if game.secret.enable then
		add_tileset_to_list("secret")
	end

	for i=1,4 do
		_slots[i].index = table.indexOfElement(_tile_list, custom_tileset.list[i])
	end

	if custom_tileset.enable then
		_slot_selected = 1
	else
		_slot_selected = 0
	end
end

function custom_tileset.previous_index( index )
	index = index - 1
	if index<=0 then
		index = #_tile_list
	end
	return index
end

function custom_tileset.next_index( index )
	index = index + 1
	if index>#_tile_list then
		index = 1
	end
	return index
end

function custom_tileset.is_index_used( index )
	for i = 1, 4 do
		if _slots[i].index==index then
			return true
		end
	end

	return false
end

function custom_tileset.next_unused( index )
	local is_used = false
	repeat
		index = custom_tileset.next_index( index )
		is_used = custom_tileset.is_index_used( index )
	until not is_used

	return index
end

function custom_tileset.previous_unused( index )
	local is_used = false
	repeat
		index = custom_tileset.previous_index( index )
		is_used = custom_tileset.is_index_used( index )
	until not is_used

	return index
end

function custom_tileset.update( dt )
	-- Change slot
	if custom_tileset.enable then
		if input.on(buttonLeft) then
			_slot_selected = math.clamp(_slot_selected-1,0,4)
			sfx.play("menu_move")
		end
		if input.on(buttonRight) then
			_slot_selected = math.clamp(_slot_selected+1,0,4)
			sfx.play("menu_move")
		end
	end

	if _slot_selected==0 then
		-- enable disable custom tileset
		if input.on(buttonUp | buttonDown) then
			custom_tileset.enable = not custom_tileset.enable
		end

		if input.on(buttonUp) then
			_enable_anim:from(44):to(0, 0.3, "outBack"):start()
		elseif input.on(buttonDown) then
			_enable_anim:from(-44):to(0, 0.3, "outBack"):start()
		end
	else
		-- Change tile
		if input.on(buttonUp) then
			local index = _slots[_slot_selected].index
			index = custom_tileset.next_unused( index )
			custom_tileset.list[_slot_selected] = _tile_list[index]
			_slots[_slot_selected].index = index

			_slots[_slot_selected].anim:from(44):to(0, 0.3, "outBack"):start()
			sfx.play("swap")
		end
		if input.on(buttonDown) then
			local index = _slots[_slot_selected].index
			index = custom_tileset.previous_unused( index )
			custom_tileset.list[_slot_selected] = _tile_list[index]
			_slots[_slot_selected].index = index

			_slots[_slot_selected].anim:from(-44):to(0, 0.3, "outBack"):start()
			sfx.play("swap")
		end
	end

	if input.on(buttonB) then
		mode.back()
		save_game.save()
	end
end

function custom_tileset.draw()
	_background:draw(0,0)

	local tileset_x = 190
	local enable_x  = 20
	local enable_w = 150

	local x, y, w, h = tileset_x-10, 98-2, 44*4+20, 44+4
	playdate.graphics.setClipRect(x, y, w, h)
	for i = 1, 4 do
		local index = _slots[i].index
		local shift = _slots[i].anim:get()

		tile_images[_tile_list[index]]:draw(tileset_x + (i-1)*44, 98 + shift)

		if _slots[i].anim:isDone()==false then
			tile_images[_tile_list[custom_tileset.next_index( index )]]:draw(tileset_x + (i-1)*44, 98 + shift + 44)
			tile_images[_tile_list[custom_tileset.previous_index( index )]]:draw(tileset_x + (i-1)*44, 98 + shift - 44)
		end
	end
	playdate.graphics.clearClipRect()

	if _slot_selected>0 then
		playdate.graphics.drawLine(x, y, x+w, y)
		playdate.graphics.drawLine(x, y+h, x+w, y+h)
	end

	if custom_tileset.enable==false then
		playdate.graphics.setColor(white)
		playdate.graphics.setDitherPattern(0.5)
		playdate.graphics.fillRect(x, y, w, h)
	end

	-- arrows
	local x = tileset_x
	if _slot_selected==0 then
		_arrow:draw(enable_x + (enable_w-44)/2, 98-50 )
		_arrow:draw(enable_x + (enable_w-44)/2, 98+50, playdate.graphics.kImageFlippedY)
	else
		_arrow:draw(tileset_x + (_slot_selected-1)*44, 98-50 )
		_arrow:draw(tileset_x + (_slot_selected-1)*44, 98+50, playdate.graphics.kImageFlippedY)
	end

	x, y, w, h = enable_x, 98, enable_w, 44

	playdate.graphics.setColor(white)
	playdate.graphics.fillRect(x, y, w, h)
	playdate.graphics.setColor(black)
	if _slot_selected==0 then
		playdate.graphics.drawLine(x, y, x+w, y)
		playdate.graphics.drawLine(x, y+h, x+w, y+h)
	end

	local text = loc("custom_tileset_enabled")
	if custom_tileset.enable==false then
		text = loc("custom_tileset_disabled")
	end

	playdate.graphics.setClipRect(x, y, w, h)
	local tw, th = playdate.graphics.getTextSizeForMaxWidth(text, enable_w)
	playdate.graphics.drawTextInRect(text, enable_x, 98 + (44-th)/2 + _enable_anim:get() + 2, enable_w, 44, 0, nil, kTextAlignment.center)
	playdate.graphics.clearClipRect()
end

function custom_tileset_cleanup()
	local custom = custom_tileset.list

	-- check default
	if custom[1]==nil and custom[2]==nil and custom[3]==nil and custom[4]==nil then
		custom[1] = "geometric1"
		custom[2] = "geometric2"
		custom[3] = "geometric3"
		custom[4] = "geometric4"

		return
	end

	local find_unused_tilset = function()
		for default_index, default_tiletype in pairs(tilesets["default"]) do
			local is_used = false
			for index, custom_tiletype in pairs(custom) do
				if custom_tiletype==default_tiletype then
					is_used = true
				end
			end

			if not is_used then
				return default_tiletype
			end
		end
	end

	-- check if the tile exist
	for index = 1, 4 do
		if tile_images[custom[index]]==nil then
			print("Warning: Custom tileset doesn't exist", custom[index], index)
			custom[index] = nil
		end
	end

	-- check if tile is used twice in custom tileset
	for index, tiletype in pairs(custom) do
		local is_duplicate = false

		-- check previous entry in custom list
		for index_check = 1, index-1 do
			if custom[index_check]==tiletype then
				is_duplicate = true
				break
			end
		end

		if is_duplicate then
			print("Warning: Custom tileset is a duplicate", tiletype, index)
			custom[index] = nil
		end

		-- we also limit the number of entries
		if index>4 then
			print("Warning: Custom tileset is too long", index)
			custom[index] = nil
		end
	end

	-- find tile for empty slot
	for index = 1, 4 do
		if not custom[index] then
			custom[index] = find_unused_tilset()
		end
	end
end

