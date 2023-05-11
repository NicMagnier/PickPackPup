function add_to_query_result( tile )
	table.insert(game.tile_query_result, tile)
	tile.is_in_query_result = true
end

function clear_tile_query_result()
	for i in ipairs(game.tile_query_result) do
		game.tile_query_result[i].is_in_query_result = false
		game.tile_query_result[i] = nil
	end
end

-- add a tile to the tile_query_result and try to add adjacent tiles of the same type
function recurcive_tile_matching_group(t)
	local function check_adjacent_tile(t2)
		if not t2 then return end
		if t2.is_moving then return end
		if t2.is_boxed then return end
		if t2.type~=t.type then return end
		if t2.is_in_query_result then return end

		recurcive_tile_matching_group(t2, true)
	end

	-- add current tile
	add_to_query_result( t )

	-- check adjacent tiles
	check_adjacent_tile( get_tile( t.gx - 1, t.gy))
	check_adjacent_tile( get_tile( t.gx, t.gy - 1))
	check_adjacent_tile( get_tile( t.gx, t.gy + 1))
	check_adjacent_tile( get_tile( t.gx + 1, t.gy))
end

function query_tile_matching_group( tile )
	clear_tile_query_result()
	recurcive_tile_matching_group(tile)

	return #game.tile_query_result>=3
end

function query_robot_and_matching_group( tile )
	if tile.type=="robot1" or tile.type=="robot2" or tile.type=="robot3" then
		return query_robot( tile )
	end

	return query_tile_matching_group( tile )
end

function query_robot( tile )
	local head_type = "robot1"
	local body_type = "robot2"
	local legs_type = "robot3"
	local battery_type = "robot4"

	-- of the tile is a battery, we run a normal query
	if tile.type==battery_type then
		return query_tile_matching_group(tile)
	end

	local get_robot_tile = function( part_type, gx, gy)
		local part_tile = get_tile(gx, gy)
		if part_tile==nil then return nil end
		if part_tile.type~=part_type or part_tile.is_boxed or part_tile.is_moving then
			return nil
		end

		return part_tile
	end

	clear_tile_query_result()

	-- we look for the head
	local head_tile = tile
	while head_tile.type~=head_type do
		head_tile = get_tile( head_tile.gx, head_tile.gy-1)
		if head_tile==nil then
			return false
		end
		if head_tile.is_boxed or head_tile.is_moving then
			return false
		end
	end

	-- check torso below
	local body_tile = get_robot_tile( body_type, head_tile.gx, head_tile.gy+1)
	local legs_tile = get_robot_tile( legs_type, head_tile.gx, head_tile.gy+2)

	if head_tile and body_tile and legs_tile then
		add_to_query_result( head_tile )
		add_to_query_result( body_tile )
		add_to_query_result( legs_tile )

		return true
	end

	return false
end