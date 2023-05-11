bag = {
	callback_empty = nil,
	callback_init = nil
}

-- private members
local _bag = table.create(100)
local _input = table.create(100)

function bag.print()
	if #_bag==0 then
		print("Bag is empty!")
		return
	end

	print("Bag content ["..#_bag.."]")
	for index, value in pairs(_bag) do
		print(index, ":", value)
	end
	print("____")
end

function bag.get()
	if #_bag==0 then
		call( bag.callback_empty )
		bag.shuffle()
		if #_bag==0 then
			print("Warning: bag was not filled", where())
		end
	end

	return table.remove(_bag)
end

function bag.add( content, count )
	if type(content)=="table" then
		count = count or #content

		local fixed_count = math.floor(count/#content)
		local random_count = count - fixed_count * #content

		-- fixed content, evenly distributed
		for i=1, fixed_count do
			for content_index = 1, #content do
				table.insert(_input, content[content_index] )
			end
		end

		-- random content
		for i=1, random_count do
			table.insert(_input, table.random(content) )
		end
	else
		count = count or 1

		for i=1, count do
			table.insert(_input, content)
		end
	end
end

function bag.shuffle()
	while #_input>0 do
		local randon_index = math.ceil(rand(#_input))
		table.insert(_bag, _input[randon_index])

		-- instead of table.remove() the random_index that would need to shift the whole array
		-- we put the last one in the random_index and remove the last index which is faster
		_input[randon_index] = _input[#_input]
		table.remove(_input)
	end
end

function bag.reset()
	table.reset(_bag)
	table.reset(_input)
end

function bag.init()
	bag.reset()
	call( bag.callback_init )
	bag.shuffle()
end

function bag.default_init_fill()
	bag.add( game.spawn_tiles, game.board_width * game.board_height + 15 )
end

function bag.default_fill()
	if game.rare_tile_spawn_rate>1 then
		bag.add( game.spawn_tiles, game.rare_tile_spawn_rate )
		bag.add( tilesets["rare"] )
	else
		bag.add( game.spawn_tiles, game.board_width * game.board_height )
	end
end

local _bomb_list_easy = { "danger1" }
local _bomb_list_medium = { "danger1", "danger2" }
local _bomb_list_hard = { "danger1", "danger2", "danger3" }
function bag.bomb_fill()
	local bomb_count = math.floor(math.infinite_approach(1, 29, 20, game.danger_level))
	local normal_tile_count = game.board_width * game.board_height - bomb_count

	local bomb_list
	if game.danger_level>=8 then
		bomb_list = _bomb_list_hard
	elseif game.danger_level>=2 then
		bomb_list = _bomb_list_medium
	else
		bomb_list = _bomb_list_easy
	end

	-- add the tiles
	bag.add( game.spawn_tiles, normal_tile_count )
	bag.add( bomb_list, bomb_count )
	bag.add( tilesets["rare"] )
end

function bag.count_in_input( tiletype )
	local count = 0
	for index, value in pairs(_input) do
		if value==tiletype then
			count = count + 1
		end
	end

	return count
end