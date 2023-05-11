local _tile_count = 0

function new_top_tile( gx, force_tiletype)
	local tile = new_tile( gx, 1, force_tiletype)

	if tile then
		tile.y = -game.tile_size - game.board_y
	end

	return tile
end

function new_tile( gx, gy, force_tiletype)
	local result = nil

	-- we check if the coordinate is free
	if get_tile(gx, gy) then
		print("Warning new_tile(): tile in the grid is not free", gx, gy)
		return nil
	end

	-- look for a free tile
	for i, t in ipairs(game.tiles) do
		if t.is_free then
			result = t
			goto found_free_tile
		end
	end

	if result==nil then
		print("Warning new_tile(): no tile available anymore", gx, gy)
		print(where())
		return nil
	end

	::found_free_tile::

	-- set position
	set_tile_position(result, gx, gy, true)

	-- default values
	result.is_free = false
	result.is_boxed = false
	result.is_moving = false
	result.is_rare = false
	result.is_bomb = false
	result.is_in_query_result = false
	result.value = 1
	result.direction = "down"

	result.state = "dropping"
	result.box = nil
	result.group_depth = 0

	result.swap_dx = 0
	result.swap_dy = 0
	result.anim_x:clear()
	result.anim_y:clear()

	result.sprite:add()
	result.sprite:setZIndex(layer.tile)
	result.sprite:setVisible(true)

	_tile_count = _tile_count + 1

	if force_tiletype then
		set_tile_type( result, force_tiletype)
		return result
	end

	-- try to spawn a tile that doesn't immediatly match
	local tiletype = bag.get()
	if tiletype==nil then
		free_tile(result)
		return nil
	end
	local match_gy = get_lowest_free_position(gx, gy)

	local left = get_tile(gx-1, match_gy)
	local right = get_tile(gx+1, match_gy)
	local top = get_tile(gx, match_gy-1)
	local bottom = get_tile(gx, match_gy+1)
	local left_type = left and left.type or ""
	local right_type = right and right.type or ""
	local top_type = top and top.type or ""
	local bottom_type = bottom and bottom.type or ""

	local try_count = game.spawn_tile_max_try
	while try_count>0 do
		if left_type~=tiletype
		and right_type~=tiletype
		and top_type~=tiletype
		and bottom_type~=tiletype
		then
			break
		end

		bag.add(tiletype)
		tiletype = bag.get()
		try_count = try_count - 1
	end
	set_tile_type(result, tiletype)

	return result
end

function free_tile(tile)
	tile.is_free = true
	_tile_count = _tile_count - 1
	tile.sprite:remove()
	set_grid(tile.gx, tile.gy, nil)
end

function free_all_tiles()
	for i, t in ipairs(game.tiles) do
		t.is_free = true
		t.sprite:remove()
	end
	_tile_count = 0
end

function tile_count()
	return _tile_count
end

function reset_danger_counter(minimum, maximum)
	minimum = minimum or 30
	maximum = maximum or 40

	game.spawn_danger_counter = rand_int(minimum, maximum)
end

function get_tile(gx, gy)
	if gx < 1 then return nil end
	if gx > game.board_width then return nil end
	if gy < 1 then return nil end
	if gy > game.board_height then return nil end

	-- we check the result because it can be false or nil
	local result = game.grid[gx + (gy-1)*game.board_width]
	if not result then
		return nil
	end

	return result
end

function get_current_tile()
	return get_tile(cursor.gx, cursor.gy)
end

function get_tile_position(gx, gy)
	return (gx-1) * game.tile_size, (gy-1) * game.tile_size
end

function set_tile_position(t, gx, gy, update_position)
	if not t then return end

	set_grid(gx, gy, t)

	local x, y = get_tile_position(gx, gy)

	if x<t.x then t.direction = "left" end
	if x>t.x then t.direction = "right" end
	if y<t.y then t.direction = "up" end
	if y>t.y then t.direction = "down" end

	if update_position then
		t.x, t.y = x, y
		t.sprite:moveTo(x, y)
	end
end

function set_grid(gx, gy, t)
	local grid_index = gx + (gy-1) * game.board_width

	game.grid[ grid_index ] = t

	if t then
		t.gx = gx
		t.gy = gy
	else
		drop_tile( get_tile( gx, gy-1))
	end
end

function get_lowest_free_position(gx, gy)
	-- gy is optional, when not set we query from the top
	gy = gy or 0

	local tile
	repeat
		gy = gy + 1
		tile = get_tile(gx, gy)
		if tile then
			return gy - 1
		end
	until gy>=game.board_height

	return game.board_height
end

function tile_can_drop( tile )
	if tile.state=="trashing" then
		return false
	end

	-- we cannot drop if we are at the bottom of the board
	if tile.gy==game.board_height then
		return false
	end

	-- see if grid position below is free
	local tile_below = get_tile( tile.gx, tile.gy + 1 )
	if tile_below then
		return false
	end

	-- handle when tile if held by the player
	if tile==get_current_tile() and input.is(buttonA) then
		return false
	end

	return true
end

function drop_tile( tile )
	if not tile then return end

	if tile.is_boxed then
		drop_box( tile.box )
		return
	end

	if tile_can_drop( tile ) then
		local gx, gy = tile.gx, tile.gy

		-- move the tile to its new position
--		set_tile_position(tile, gx, gy+1, false)
		tile.state = "dropping"

		-- free the grid slot it was previously using
--		set_grid(gx, gy, nil)
	end
end

function set_tile_type( tile, tiletype)
	tile.type = tiletype
	tile.sprite:setImage(tile_images[tiletype])

	tile.is_rare = (tiletype=="rare1")

	-- fast way to check is tiletype starts with "dang" for danger
	tile.is_bomb = tiletype:byte(1)==100 and tiletype:byte(2)==97 and tiletype:byte(3)==110 and tiletype:byte(4)==103
end

function match_tiles(tile)
	if tile.is_moving or tile.is_boxed then
		return
	end

	matching_fn = game.query_function or query_tile_matching_group

	local matched = matching_fn(tile)
	if matched then
		new_box()
	end

	return matched
end

function trash_tile(tile, delay)
	if not tile then return end
	if tile.state=="trashing" then return end

	delay = delay or 0

	tile.state = "trashing"
	tile.is_moving = true
	tile.sprite:setZIndex(layer.tile_trashed)
	tile.trash_anim_x, tile.trash_anim_y = getTrashAnim()

	if tile.box then
		trash_box(tile.box, delay)
	else
		score.add_penalty( tile )
		call( game.callback_tile_trashed, tile )
	end
end

function explode_tile( tile, bomb_x, bomb_y )
	if not tile then return end
	if tile.state=="trashing" then return end

	if tile.box then
		explode_box(tile.box, bomb_x, bomb_y)
	end

	tile.state = "trashing"
	tile.sprite:setZIndex(layer.tile_trashed)
	tile.is_moving = true
	tile.anim_x:from(0):to( tile.x - bomb_x, 0.5):start()
	tile.anim_y:from(0):to( bomb_y + 240, 0.5, "inBack"):start()
	tile.trash_anim_x = tile.anim_x
	tile.trash_anim_y = tile.anim_y
end

function drag_tile( tile, new_gx, new_gy)
	if not tile then return false end
	if tile.is_boxed or tile.is_moving then return false end

	-- if there is a tile at the new position, we swap them
	local target_tile = get_tile(new_gx, new_gy)
	if target_tile then
		return swap_tiles( tile, target_tile )
	end

	-- we move the tile to an empty space
	local old_gx, old_gy = tile.gx, tile.gy

	-- we cannot move a tile upward in an empty space (gravity you know)
	-- if new_gy<old_gy then
	-- 	return false
	-- end

	local nx, ny = get_tile_position(new_gx, new_gy)
	tile.swap_dx = tile.x - nx
	tile.swap_dy = tile.y - ny

	set_tile_position(tile, new_gx, new_gy, true)
	set_grid(old_gx, old_gy, nil)

	return true
end

-- return true if the tiles have been swapped
function swap_tiles( tile1, tile2 )
	if not tile1 then return false end
	if not tile2 then return false end

	local can_be_swapped = true

	if tile1.is_boxed or tile2.is_boxed then
		return false
	end
	if tile1.is_moving or tile2.is_moving then
		can_be_swapped = false
	end

	-- set swap animation
	tile1.swap_dx = tile1.x - tile2.x
	tile1.swap_dy = tile1.y - tile2.y

	tile2.swap_dx = tile2.x - tile1.x
	tile2.swap_dy = tile2.y - tile1.y

	-- swap tiles
	local tile1_gx, tile1_gy = tile1.gx, tile1.gy
	set_tile_position(tile1, tile2.gx, tile2.gy, true)
	set_tile_position(tile2, tile1_gx, tile1_gy, true)

	return true
end

function next_tile_in_grid( array, index)
	local tile
	index = index or 0

	for i=index+1, game.board_width*game.board_height do
		tile = array[i]
		if tile and tile.is_free==false then
			return i, tile
		end
	end
end

function grid()
	return next_tile_in_grid, game.grid
end