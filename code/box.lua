-- private members
local _box_count = 0
local _box_gameplay_count = 0

function new_box()
	local result = nil

	if #game.tile_query_result==0 then
		return result
	end

	-- look for a free box
	for boxId, box in ipairs(game.boxes) do
		if box.is_free then
			result = box
			goto found_free_box
		end
	end

	if result==nil then
		print("Warning new_box(): no box available anymore")
		return nil
	end

	::found_free_box::

	local first_tile = game.tile_query_result[1]

	result.is_free = false
	result.boxtile_size = 0
	result.gx = first_tile.gx
	result.gy = first_tile.gy

	result.x, result.y = get_tile_position(result.gx, result.gy)

	result.value = 0

	result.state = "gameplay"
	_box_gameplay_count = _box_gameplay_count + 1
	_box_count = _box_count + 1

	local direction = first_tile.direction
	if direction=="down" then
		result.anim_x:from(0)
		result.anim_y:from(0):to( 3, 0.13, "outBack"):to( 0, 0.1):start()
	elseif direction=="up" then
		result.anim_x:from(0)
		result.anim_y:from(0):to( -3, 0.13, "outBack"):to( 0, 0.1):start()
	elseif direction=="left" then
		result.anim_x:from(0):to( -3, 0.13, "outBack"):to( 0, 0.1):start()
		result.anim_y:from(0)
	elseif direction=="right" then
		result.anim_x:from(0):to( 3, 0.13, "outBack"):to( 0, 0.1):start()
		result.anim_y:from(0)
	end

	-- initialize the bottom tiles
	for i = 1, game.board_width do
		result.tiles_bottom[i] = nil
		result.tiles_top[i] = nil
	end

	local min_gx, min_gy, max_gx, max_gy = 99, 99, 0, 0

	-- parse all query result
	for tileId, tile in ipairs(game.tile_query_result) do
		-- set reference to the new box in the tile
		tile.box = result
		tile.is_boxed = true
		tile.sprite:remove()

		-- alloc the new tile reference
		result.boxtile_size = result.boxtile_size + 1
		local boxtile = result.boxtiles[result.boxtile_size]

		min_gx = min(min_gx, tile.gx)
		min_gy = min(min_gy, tile.gy)
		max_gx = max(max_gx, tile.gx)
		max_gy = max(max_gy, tile.gy)

		boxtile.x, boxtile.y = get_tile_position(tile.gx, tile.gy)

		boxtile.x = boxtile.x - result.x 
		boxtile.y = boxtile.y - result.y

		boxtile.tile = tile

		local sprite = boxtile.sprite
		sprite:setImage( get_boxtile_img(tile) )
		sprite:add()
		sprite:setZIndex(layer.boxtile)
		sprite:setVisible(true)

		-- check if it's a top/bottom tile
		local gx, gy = tile.gx, tile.gy

		local bottom = result.tiles_bottom[gx]
		if not bottom then
			result.tiles_bottom[gx] = tile
		elseif bottom.gy < gy then
			result.tiles_bottom[gx] = tile
		end

		local top = result.tiles_top[gx]
		if not top then
			result.tiles_top[gx] = tile
		elseif top.gy > gy then
			result.tiles_top[gx] = tile
		end
	end

	-- value of box increase depending of its size
	result.value = game.box_value[result.boxtile_size]
	if first_tile.is_rare then
		result.value = result.value * game.box_value_rare_multiplier
	end

	-- calculate center
	local min_x, min_y = get_tile_position(min_gx, min_gy)
	local max_x, max_y = get_tile_position(max_gx, max_gy)
	max_x = max_x + game.tile_size
	max_y = max_y + game.tile_size
	result.center_x = min_x + (max_x - min_x)/2
	result.center_y = min_y + (max_y - min_y)/2

	point_notification.new( result.value, result.center_x, result.center_y )

	result.center_x = result.center_x - result.x
	result.center_y = result.center_y - result.y
	result.left = min_x - result.x

	game.stats.box_created = game.stats.box_created + 1

	call( game.callback_box_created, result )

	return result
end

function free_box( box )
	if box.is_free then
		return
	end

	box.is_free = true
	_box_count = _box_count - 1

	for i = 1, box.boxtile_size do
		local boxtile = box.boxtiles[i]
		free_tile( boxtile.tile )
		boxtile.sprite:remove()
	end

	if box.state=="gameplay" then
		_box_gameplay_count = _box_gameplay_count - 1
	end
end

function build_box( tiletype,...)
	local tiles = {...}

	if (#tiles%2)~=0 then
		print("build_box() warning, odd number of tile coordinates")
		print(where())
		return
	end

	clear_tile_query_result()

	for i = 1, #tiles, 2 do
		add_to_query_result( new_tile(tiles[i], tiles[i+1], tiletype) )
	end

	return new_box()
end

function free_all_box()
	for i, b in ipairs(game.boxes) do
		free_box( b )
	end
end

function box_count()
	return _box_count
end

function box_gameplay_count()
	return _box_gameplay_count
end

function get_boxtile_img(tile)
	-- local function to check if a tile is in the result query
	local is_tile_in_query = function(gx, gy)
		local t = get_tile(gx, gy)
		if not t then return false end

		return t.is_in_query_result
	end

	-- check every neighbour position
	local index = 1

	if is_tile_in_query(tile.gx - 1, tile.gy) then
		index = index + 8
	end

	if is_tile_in_query(tile.gx, tile.gy - 1) then
		index = index + 4
	end

	if is_tile_in_query(tile.gx + 1, tile.gy) then
		index = index + 2
	end

	if is_tile_in_query(tile.gx, tile.gy + 1) then
		index = index + 1
	end

	return images[table.random(box_img[index])]
end

function drop_box( box_to_drop )
	if not box_to_drop then return end

	if box_to_drop.state=="shipping" or box_to_drop.state=="trashing" then
		return
	end

	local drop_box_group_tiles = table.create(20,0)
	local drop_box_group_boxes = table.create(8,0)
	local drop_box_group_top = table.create(game.board_width)
	local drop_box_group_bottom = table.create(game.board_width)
	
	-- we define the group of tile that we will need to move
	-- for example if two boxes are interlocked
	local update_group = nil
	local function _update_group( box )
		if not table.insert_unique( drop_box_group_boxes, box) then
			return
		end

		-- update group boundaries
		for i=1, game.board_width do
			if drop_box_group_top[i]==nil then
				drop_box_group_top[i] = box.tiles_top[i]
			elseif box.tiles_top[i] and drop_box_group_top[i].gy > box.tiles_top[i].gy then
				drop_box_group_top[i] = box.tiles_top[i]
			end

			if drop_box_group_bottom[i]==nil then
				drop_box_group_bottom[i] = box.tiles_bottom[i]
			elseif box.tiles_bottom[i] and drop_box_group_bottom[i].gy < box.tiles_bottom[i].gy  then
				drop_box_group_bottom[i] = box.tiles_bottom[i]
			end
		end

		-- check all tiles between top and bottom
		for gx=1, game.board_width do
			local top, bottom = drop_box_group_top[gx], drop_box_group_bottom[gx]

			if top and bottom then
				for gy = top.gy+1, bottom.gy-1 do
					local tile = get_tile( gx, gy)
					if tile then
						if tile.is_boxed then
							update_group( tile.box )
						else
							table.insert_unique( drop_box_group_tiles, tile)
						end
					end
				end
			end
		end
	end
	update_group = _update_group

	-- add the box and its interlocked tile and boxes
	update_group( box_to_drop )

	-- figure out the drop we can do
	local min_drop = game.board_height
	for i = 1, game.board_width do
		local tile = drop_box_group_bottom[i]
		if tile then
			local dest_gy = get_lowest_free_position(tile.gx, tile.gy)
			local drop = dest_gy - tile.gy

			if drop<=0 then
				return
			end

			if drop < min_drop then
				min_drop = drop
			end
		end
	end

	-- update the boxes
	for _, box in ipairs(drop_box_group_boxes) do
		-- we drop the box
		box.gy = box.gy + min_drop

		-- we drop the tiles of the box
		for i = 1, box.boxtile_size do
			local tile = box.boxtiles[i].tile
			local gx, gy = tile.gx, tile.gy

			set_tile_position(tile, gx, gy + min_drop, false)
		end
	end

	-- update the single tiles
	for _, tile in ipairs(drop_box_group_tiles) do
		local gx, gy = tile.gx, tile.gy
		set_tile_position(tile, gx, gy + min_drop, false)
	end

	-- we free the space at the top
	for gx = 1, game.board_width do
		local top = drop_box_group_top[gx]
		if top then
			for y=1, min_drop do
				set_grid( gx, top.gy - y, nil)
			end
		end
	end
end

function trash_box( box, delay )
	if not box then return end
	delay = delay or 0

	if box.state=="trashing" then return end

	box.state = "trashing"
	box.trash_anim_x, box.trash_anim_y = getTrashAnim()

	for i = 1, box.boxtile_size do
		local boxtile = box.boxtiles[i]
		boxtile.tile.is_moving = true
		boxtile.sprite:setZIndex(layer.boxtile_trashed)
	end

	score.add_penalty( box )

	call( game.callback_box_trashed, box )
	game.stats.box_trashed = game.stats.box_trashed + 1
	_box_gameplay_count = _box_gameplay_count - 1
end

function explode_box( box, bomb_x, bomb_y )
	if not box then return end

	if box.state=="trashing" then return end

	box.state = "trashing"
	box.anim_x:from(0):to( box.x-bomb_x, 0.5):start()
	box.anim_y:from(0):to( bomb_y + 240, 0.5, "inBack"):start()
	box.trash_anim_x = box.anim_x
	box.trash_anim_y = box.anim_y

	for i = 1, box.boxtile_size do
		local boxtile = box.boxtiles[i]
		boxtile.tile.is_moving = true
		boxtile.sprite:setZIndex(layer.boxtile_trashed)
	end

	_box_gameplay_count = _box_gameplay_count - 1
end

function ship_box( box, delay )
	if not box then return end
	if box.state=="shipping" then return end

	box.state = "shipping"

	local target_x = 400 - box.left
	local target_y = 30 + (box.y + box.center_y - 120) / 2

	box.anim_x:from(box.x):sleep(delay):to( target_x, 0.5 + rand(0.3), "inBack"):start()
	box.anim_y:from(box.y):sleep(delay):to( target_y, 0.8, "inOutBack"):start()

	for i = 1, box.boxtile_size do
		local tilebox = box.boxtiles[i]
		tilebox.sprite:setZIndex(layer.boxtile_shipped)

		local tile = tilebox.tile
		tile.state = "shipping"
		tile.is_moving = true
	end

	game.stats.box_shipped = game.stats.box_shipped + 1
	_box_gameplay_count = _box_gameplay_count - 1
end

function box_update_sprite( box )
	local x = game.board_x + box.x
	local y = game.board_y + box.y
	local boxtiles = box.boxtiles

	for i = 1, box.boxtile_size do
		local boxtile = boxtiles[i]
		boxtile.sprite:moveTo( x + boxtile.x, y + boxtile.y )
	end
end

function box_tile_type( box )
	return box.boxtiles[1].tile.type
end

function box_size( box )
	return box.boxtile_size
end

function next_box( array, index)
	local box

	repeat
		index, box = next(array, index)
	until box==nil or box.is_free==false

	return index, box
end

function valid_boxes()
	return next_box, game.boxes
end