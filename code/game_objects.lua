game = {
	modename = "game",
	mode = "normal",
	is_running = false,

	board_width = 6,
	board_height = 5,
	board_x = 0,
	board_y = 0,
	tile_size = 44,

	tiles = nil,
	boxes = nil,
	grid = nil,

	query_function = nil,
	tile_query_result = nil,

	spawn_function = nil,
	spawn_tile_max_try = 3,
	spawn_tile_by_tile_parameters = {
		time = 0,
		duration = 2,
		column = 1,
		callback_spawn = nil,
		callback_cannot_spawn = nil,
	},

	spawn_tiles = table.create(4),
	spawn_tileset = "default",

	rare_tile_spawn_rate = 90, -- how many normal tiles before a rare tie appear
	rare_tile_anim = anim_loop.new(),

	initial_filled_lines = 0, -- set in new_game()
	trash_line_count = 1,

	spawn_danger_counter = -1,
	danger_level = 0,

	box_value = {
		1,
		1,
		3, -- 3 tiles box
		10, -- 4 tiles box
		35, -- 5
		100, -- 6
		300, -- 7, used to be 500
	},
	box_value_rare_multiplier = 30, -- wow


	has_moving_tile = false,
	is_trashing = false,

	shipping_count = 0,
	trashing_count = 0,
	unmatched_count = 0,
	matched_count = 0,

	-- Score
	combo = 0,
	points = 0,

	real_score = 0,
	score = 0,
	score_goal = 0,

	drop_speed = 500, -- also set in new_game()
	swap_speed = 400,

	lifecount = 3,
	lifecount_max = 3,

	story_index = 1,
	unlocked_story_index = 1,
	challenge_progress = 0,
	challenge_progress_extra = 0,
	challenge_reward_given = false,

	-- callbacks (for story mode)
	callback_box_shipped = nil, -- function( box )
	callback_box_created = nil, -- function( box )
	callback_box_trashed = nil, -- function( box )
	callback_tile_trashed = nil, -- function( tile )
	callback_combo_finished = nil, -- function ( score, combo_level )
	callback_line_trashing = nil, -- called before bottom tiles are trashed
	callback_shipping = nil,
	callback_score_finished_counting = nil,

	memo = nil,
	music_track = nil,
	character_rating = true, -- does the game allow the character to talk during a shipment
	show_point_notification = true,
	show_combo = true,
	show_fps = false,
	shipping_enable = true,

	normalmode = {
		level = 0, -- difficulty level
		save_update_timeout = 0,
		safe_score = 0, -- last saved score with final line penalty to avoid cheating
		boxlist = table.create(7),
		highscore = 0
	},

	timeattack = {
		time = 0,
		highscore = 0
	},

	bomb = {
		has_exploded = false,

		highscore = 0
	},

	relax = {
		highscore = -1,
		result_index = 1,
		result_size = 10,
		previous_results = table.create(10)
	},

	secret = {
		enable = false,
		highscore = 0,

		shipment_count = 0,
	},

	point_notifications = nil,

	score_frame = playdate.graphics.nineSlice.new("images/frames/small", 3, 3, 2, 2),

	-- stats
	stats = {
		box_created = 0,
		box_trashed = 0,
		box_shipped = 0,
		biggest_shipment = 0,
	}
}

-- preallocate all the tiles and the grid
local tile_count = game.board_width*game.board_height
game.tiles = table.create(tile_count, 0)
game.grid = table.create(tile_count, 0)
game.tile_query_result = table.create(tile_count, 0)
for i = 1, tile_count do
	local new_tile = {
		x = 0,
		y = 0,
		gx = 1,
		gy = 1,
		type = false,
		sprite = playdate.graphics.sprite.new(),
		value = 1,

		state = "gameplay",

		is_boxed = false,
		is_moving = false,
		is_free = true,
		is_rare = false,
		is_bomb = false,
		is_in_query_result = false,

		box = nil,

		group_depth = 0,

		swap_dx = 0,
		swap_dy = 0,
		anim_x = sequence.new(),
		anim_y = sequence.new(),
		trash_anim_x = nil,
		trash_anim_y = nil,
	}


	table.insert(game.tiles, new_tile)
	new_tile.sprite:setCenter(0,0)

	game.grid[i] = false
end

-- preallocate all the box
local box_max = math.ceil(tile_count/3)
game.boxes = table.create(box_max, 0)
for i = 1, box_max do
	table.insert(game.boxes, {
		is_free = true,

		boxtile_size = 0,

		x = 0,
		y = 0,
		gx = 0,
		gy = 0,

		center_x = 0,
		center_y = 0,
		left = 0,

		value = 0,

		state = "gameplay",

		anim_x = sequence.new(),
		anim_y = sequence.new(),
		trash_anim_x = nil,
		trash_anim_y = nil,
		direction = "down",

		time = 0,

		boxtiles = table.create(7, 0),
		tiles_top = table.create(game.board_width, 0),
		tiles_bottom = table.create(game.board_width, 0),
	})

	local boxtiles = game.boxes[i].boxtiles
	for j = 1, 7 do
		local boxtile = {
			x = 0,
			y = 0,
			tile = nil,
			sprite = playdate.graphics.sprite.new(),
		}

		table.insert(boxtiles, boxtile)
		boxtile.sprite:setCenter(0,0)
	end
end

-- preallocate point notifications
max_point_notifications = 20
game.point_notifications =  table.create(max_point_notifications, 0)
for i = 1, max_point_notifications do
	local new_pn = {
		is_free = true,
		image = playdate.graphics.image.new(100, 26),--26),
		sprite = playdate.graphics.sprite.new(),
		x_anim = sequence.new(),
		y_anim = sequence.new(),
	}

	new_pn.sprite:setImage(new_pn.image)
	new_pn.sprite:setZIndex(layer.point_notification)

	table.insert(game.point_notifications, new_pn)
end
