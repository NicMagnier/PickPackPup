story_levels = {
	{
		-- make 10 boxes
		comic = "page03",

		prefix = "lvl1",
		level = "Level 01",
		score_goal = 500,
		challenge_reward = 300,

		init = function()
			story_state.box_created = game.stats.box_created
			clock.disable()
			game.rare_tile_spawn_rate = 0
		end,

		update = function(dt)
			local box_created_challenge = game.stats.box_created - story_state.box_created
			game.challenge_progress = math.clamp( box_created_challenge / 10, 0, 1 )
		end,
	},

	{
		-- create a 4 items box
		prefix = "lvl2",
		level = "Level 02",
		score_goal = 1000,
		challenge_reward = 600,

		init = function()
			clock.disable()
			game.rare_tile_spawn_rate = 0
		end,

		update = function(dt)
			if game.challenge_progress>0 then return end

			for boxIndex, box in valid_boxes() do
				if box.boxtile_size>=4 then
					game.challenge_progress = 1
					return
				end
			end
		end,
	},

	{
		-- ship 5 boxes in one go
		prefix = "lvl3",
		level = "Level 03",
		score_goal = 1000,
		challenge_reward = 600,

		init = function()
			clock.disable()
			game.rare_tile_spawn_rate = 0

			story_state.count = 0

			game.callback_box_created = function()
				if game.challenge_progress>=1 then return end

				story_state.count = story_state.count + 1
				game.challenge_progress_extra = story_state.count/5
			end

			game.callback_combo_finished = function( score, combo )
				if game.challenge_progress>=1 then return end

				story_state.count = 0
				game.challenge_progress_extra = 0
				if combo>=5 then
					game.challenge_progress = 1
				end
			end
		end,
	},

	{
		-- Fill the bottom line with boxes
		prefix = "lvl4",
		level = "Level 04",
		score_goal = 1000,
		challenge_reward = 600,

		init = function()
			clock.disable()
			game.rare_tile_spawn_rate = 0
		end,

		update = function(dt)
			if game.challenge_progress>=1 then return end

			local count = 0

			local bottom = game.board_height
			for i = 1, game.board_width do
				local tile = get_tile(i, bottom)
				if tile and tile.is_boxed then
					count = count + 1
				end
			end

			game.challenge_progress = (count/game.board_width)
		end,
	},

	{
		-- Banana order
		prefix = "banana",
		level = "Banana Surge",

		tileset = { "fruit1", "fruit2", "fruit3", "fruit5" },

		goal = 60,

		init = function()
			story_state.count = 0
			game.rare_tile_spawn_rate = 0

			clock.disable()
			game.set_tileset( story_level.tileset, true )

			game.callback_box_shipped = function( box )
				if box.boxtiles[1].tile.type=="fruit5" then
					story_state.count = story_state.count + box.boxtile_size
				end
			end

			game.callback_box_trashed = function( box )
				if box.boxtiles[1].tile.type=="fruit5" then
					story_state.count = max(story_state.count - box.boxtile_size, 0)
				end
			end

			game.callback_tile_trashed = function( tile )
				if tile.type=="fruit5" then
					story_state.count = max(story_state.count - 1, 0)
				end
			end

		end,

		update = function ( dt )
			if story_state.count>story_level.goal then
				story.level_done()
			end
		end,

		draw_ui = function()
			game_ui.draw_order_sheet( loc("ui_order_sheet"), "fruit5", story_state.count, story_level.goal )
		end
	},

	{
		-- Do not lose a box
		comic = "page04",
		prefix = "lvl5",
		level = "Level 05",
		score_goal = 1500,
		challenge_reward = 1000,

		init = function()
			story_state.time = 0
			story_state.box_trashed = game.stats.box_trashed

			clock.set_duration( 20 )
			game.rare_tile_spawn_rate = 0
		end,

		update = function(dt)
			if game.challenge_progress>=1 then return end

			story_state.time = story_state.time + dt

			if game.stats.box_trashed>story_state.box_trashed then
				story_state.time = 0
				story_state.box_trashed = game.stats.box_trashed
			end

			local goal_duration = 60
			game.challenge_progress = story_state.time / goal_duration
		end,
	},

	{
		-- Match 5 items, 3 times
		prefix = "match_five",
		level = "Match 5 Items",
		score_goal = 2000,
		challenge_reward = 1000,

		init = function()
			story_state.count = 0
			clock.disable()
			game.rare_tile_spawn_rate = 0

			game.callback_box_created = function( box )
				if box.boxtile_size>=5 then
					story_state.count = story_state.count + 1
					game.challenge_progress = story_state.count / 3
				end
			end
		end,
	},

	{
		-- Apple order
		prefix = "apple",
		level = "Rotten Apples",

		tileset = { "fruit1", "fruit2", "fruit4", "fruit6" },

		init = function()
			story_state.count = 0
			story_state.time = 2*60 + 30 + 20 * math.clamp(story.fail_count, 0, 3)
			game.set_tileset( story_level.tileset, true )
			game.rare_tile_spawn_rate = 0
			game.spawn_tile_max_try = 5

			game.show_point_notification = false
			clock.disable()

			bag.callback_empty = function()
				bag.add("fruit1", 20)
				bag.add("fruit2", 10)
				bag.add("fruit4", 10)
				bag.add("fruit6", 10)
			end

			game.callback_box_shipped = function( box )
				if box.boxtiles[1].tile.type=="fruit1" then
					story_state.count = story_state.count + box.boxtile_size
				end
			end

			game.callback_box_trashed = function( box )
				if box.boxtiles[1].tile.type=="fruit1" then
					story_state.count = max(story_state.count - box.boxtile_size, 0)
				end
			end

			game.callback_tile_trashed = function( tile )
				if tile.type=="fruit1" then
					story_state.count = max(story_state.count - 1, 0)
				end
			end

		end,

		update = function ( dt )
			story_state.time = story_state.time - dt
			if story_state.time<=0 then
				story.level_failed()
			end

			if story_state.count>100 then
				story.level_done()
			end
		end,

		draw_ui = function()
			game_ui.draw_timeattack_timer( story_state.time )
			game_ui.draw_order_sheet( loc("ui_order_sheet"), "fruit1", story_state.count, 100 )
		end
	},

	{
		-- Book break
		prefix = "book",
		level = "Books",
		score_goal = 1200,

		init = function()
			game.set_tileset( "book", true )
			game.rare_tile_spawn_rate = 0
		end,
	},

	{
		-- Only boxes on the edge of the board
		prefix = "boxed_edge",
		level = "Boxes around the edge",
		score_goal = 6000,
		challenge_reward = 6000,

		init = function()
			clock.disable()
			game.rare_tile_spawn_rate = 0
		end,

		update = function(dt)
			if game.challenge_progress>=1 then return end

			local count = 0

			local is_box = function(x,y)
				local tile = get_tile(x, y)
				if not tile then return false end
				return tile.is_boxed
			end
			local x, y

			-- check top
			y = 1
			for x = 1, game.board_width do
				if is_box(x,y) then count = count + 1 end
			end

			-- check bottom
			y = game.board_height
			for x = 1, game.board_width do
				if is_box(x,y) then count = count + 1 end
			end

			-- check left
			x = 1
			for y = 2, game.board_height-1 do
				if is_box(x,y) then count = count + 1 end
			end

			-- check right
			x = game.board_width
			for y = 2, game.board_height-1 do
				if is_box(x,y) then count = count + 1 end
			end

			game.challenge_progress = (count/18)
		end,
	},

	{
		-- Slow big score
		prefix = "big_score",
		level = "Big score",
		score_goal = 1000,

		init = function()
			game.rare_tile_spawn_rate = 0
			clock.disable()

			story_state.count = 0
			story_state.time = -1

			game.callback_shipping = function()
				story_state.count = story_state.count + 1
				local tile_count = game.board_width * game.board_height
				local trash_count = 0
				for i = tile_count, 1, -1 do
					local tile = game.grid[i]
					if tile and tile.is_boxed==false then
						tile.value = 0
						trash_tile( tile , 0.7 + trash_count * 0.04)
						trash_count = trash_count + 1
					end
				end

				startTrashAnim()
				sfx.play("trashing")
			end

			game.callback_combo_finished = function()
				if story_state.count >= 5 and story_state.time<0 then
					story_state.time = 0
				end
			end
		end,

		update = function(dt)
			if story_state.time>=0 then
				story_state.time = story_state.time + dt
				if story_state.time>1 then
					story.level_failed()
				end
			end
		end,

		draw_ui = function()
			game_ui.draw_score()
			game_ui.draw_shipment_count( story_state.count, 5 )
		end
	},

	{
		-- Two big box in the same screen
		comic = "page05",

		prefix = "two_big_boxes",
		level = "Two Big Boxes",
		score_goal = 2000,
		challenge_reward = 1000,

		init = function()
			game.rare_tile_spawn_rate = 0
		end,

		update = function(dt)
			if game.challenge_progress>=1 then return end

			local count = 0
			for boxIndex, box in valid_boxes() do
				if box.boxtile_size>=5 then
					count = count + 1
				end
			end

			game.challenge_progress = count/2
		end
	},

	{
		-- Match 7 items
		prefix = "match_seven",
		level = "Match 7 Items",
		score_goal = 5000,
		challenge_reward = 3500,

		init = function()
			clock.disable()
			game.rare_tile_spawn_rate = 0

			game.callback_box_created = function( box )
				if game.challenge_progress >= 1 then return end

				if box.boxtile_size>=7 then
					game.challenge_progress = 1
				else
					game.challenge_progress = 0
				end
			end
		end,
	},

	{
		-- Prevent tile trashing
		prefix = "prevent_trashing",
		level = "Prevent Trashing",
		score_goal = 2000,
		challenge_reward = 1500,

		init = function()
			story_state.count = 0
			game.rare_tile_spawn_rate = 0

			game.callback_line_trashing = function()
				for gx=1, game.board_width do
					local tile = get_tile(gx, game.board_height)
					if not tile then
						story_state.count = story_state.count + 1
					end
				end

				game.challenge_progress = story_state.count / 6
			end
		end,
	},

	{
		-- Panic level
		prefix = "panic",
		level = "Level Panic",
		score_goal = 1000,

		pull_anim = sequence.new()
			:from(0)
			:sleep(0.3)
			:to(7, 0.3, "outBack")
			:sleep(0.2)
			:to(0, 0.5, "inOutCubic")
			:sleep(0.3)
			:to(7, 0.3, "outCirc")
			:to(20, 0.2, "outExpo"),

		init = function()
			story_state.time = 5
			story_state.state = "normal"
			story_state.tile = nil
			story_state.tile_is_boxed = false
			story_state.x = nil
			game.character_rating = false
			game.set_tileset("playdate", true)

			game.rare_tile_spawn_rate = 0

			character.unlock_animation()
			character.set_animation( "goose" )
			character.lock_animation()
		end,

		update = function(dt)
			if game.has_moving_tile==false then
				story_state.time = story_state.time - dt
			end

			if story_state.state == "honk" then
				character.unlock_animation()
				character.set_animation( "goose_honk", 140 )
				character.lock_animation()

				if story_state.honk_time==0 then
--					character.talk( "talk_goose", 1 )
					local r = rand_int(1,3)
					if r==1 then sfx.play("sfx_goose_honk_02") end
					if r==2 then sfx.play("sfx_goose_honk_03") end
					if r==3 then sfx.play("sfx_goose_honk_06") end
				end

				story_state.honk_time = story_state.honk_time + dt
				if story_state.honk_time>0.14*4 then
					story_state.state = "pull"
					story_level.pull_anim:restart()
				end

				if story_state.tile~=get_tile(6,4) or story_state.tile_is_boxed~=story_state.tile.is_boxed then
					story_state.state = "normal"
					story_state.time = rand(2,4)
				end

			elseif story_state.state == "normal" then
				character.unlock_animation()
				character.set_animation( "goose" )
				character.lock_animation()
				character.offset_x = 0

				if story_state.time<0 then
					local tile = get_tile(6,4)
					if tile then
						story_state.state = "honk"
						story_state.honk_time = 0

						story_state.tile = tile
						if tile.is_boxed and tile.box then
							story_state.x = get_tile_position(tile.box.gx, tile.box.gy)
							story_state.tile_is_boxed = true
						else
							story_state.x = get_tile_position(6, 4)
							story_state.tile_is_boxed = false
						end
					else
						story_state.time = 1
					end
				end
			elseif story_state.state == "pull" then
				character.unlock_animation()
				character.set_animation( "goose_pull" )
				character.lock_animation()

				character.offset_x = story_level.pull_anim:get()

				-- if the player changed tile grabbed by the goose
				if story_state.tile~=get_tile(6,4) or story_state.tile_is_boxed~=story_state.tile.is_boxed or story_state.tile.state~="gameplay" then
					story_state.state = "normal"
					story_state.time = rand(2,4)

				-- if the anim is finished we trash
				elseif story_level.pull_anim:isDone() then
					story_state.state = "normal"
					story_state.time = rand(4,10)

					trash_tile(story_state.tile)

					local object = story_state.tile
					if object.is_boxed then
						object = object.box
					end
					object.anim_x:from(0):to( 15, 0.5):start()
					object.anim_y:from(0):to( 240, 0.5, "inBack"):start()
					object.trash_anim_x = object.anim_x
					object.trash_anim_y = object.anim_y

					sfx.play("trashing")

				-- normal update
				else
					local x = story_state.x
					local tile = story_state.tile
					if tile.is_boxed and tile.box then
						tile.box.x = x + character.offset_x
						box_update_sprite( tile.box )
					else
						tile.x = x + character.offset_x
					end
					
				end

			end
		end,
	},

	{
		-- match 3 diamonds or more
		comic = "page06",
		prefix = "match_diamond",
		level = "Match Diamonds",
		score_goal = 2000,
		challenge_reward = 600,

		init = function()
			game.rare_tile_spawn_rate = 50
			game.callback_box_created = function( box )
				if box.boxtiles[1].tile.is_rare then
					game.challenge_progress = 1
				end
			end
		end,
	},

	{
		-- Only one shipment to do a masshive score
		prefix = "one_shot_diamond",
		level = "One shot",
		score_goal = 800,

		init = function()
			story_state.count = 0
			game.spawn_function = spawn_full_board
			clock.disable()

			bag.callback_init = function()
				local rare_count = 3 + math.floor(story.fail_count/2)
				bag.add(tilesets["rare"], rare_count)
				bag.add(game.spawn_tiles, 20 - rare_count)
			end

			bag.callback_empty = function()
				bag.add(game.spawn_tiles, 15)
			end

			game.callback_shipping = function()
				story_state.count = story_state.count + 1
				game.spawn_function = nil
			end

			game.callback_score_finished_counting = function()
				if game.real_score < story_level.score_goal then
					story.level_failed()
				end
			end
		end,

		draw_ui = function()
			game_ui.draw_score()
			game_ui.draw_shipment_count( story_state.count, 1 )
		end
	},

	{
		-- Match 5 diamonds
		prefix = "match_five_diamonds",
		level = "Match 5 diamonds",
		score_goal = 3000,
		challenge_reward = 1800,

		init = function()
			game.rare_tile_spawn_rate = 30
			game.callback_box_created = function( box )
				if box.boxtiles[1].tile.is_rare and box.boxtile_size>=5 then
					game.challenge_progress = 1
				end
			end
		end,
	},

	{
		-- quick trash
		prefix = "quick_trash",
		level = "Quick Trash",
		score_goal = 200,
		challenge_reward = 150,

		init = function()
			game.rare_tile_spawn_rate = 10
			clock.set_duration( 1, 0 )
			story_state.count = 0

			game.callback_box_shipped = function( box )
				if game.challenge_progress>=1 then return end

				if box.boxtiles[1].tile.is_rare then
					story_state.count = story_state.count + 1
					game.challenge_progress = story_state.count/5
				end
			end
		end,
	},

	{
		-- Holiday break
		comic = "page07",

		prefix = "holiday",
		level = "Glorious Holidays",
		score_goal = 2000,

		init = function()
			game.set_tileset( "holiday", true )
			game.music_track = "If_Im_Wrong"
			background.set(images.holiday_background_1)

			story_state.time = 0
			story_state.count = 1
		end,

		update = function(dt)
			story_state.time = story_state.time + dt

			local frame_delay = 0.06
			if story_state.time>frame_delay then
				story_state.time = story_state.time - frame_delay
				story_state.count = math.ring_int(story_state.count+1, 1, 3)

				if story_state.count==1 then background.set(images.holiday_background_1) end
				if story_state.count==2 then background.set(images.holiday_background_2) end
				if story_state.count==3 then background.set(images.holiday_background_3) end
			end
		end
	},

	{
		-- Cannot ship, avoid overflow
		prefix = "overflow",
		level = "No overflow",

		init = function()
			game.rare_tile_spawn_rate = 0
			clock.set_duration( 10, 1 )

			story_state.time = 3*60

			game.initial_filled_lines = 2
			game.shipping_enable = false

			game.spawn_function = spawn_tile_by_tile
			game.spawn_tile_by_tile_parameters.time = 0
			game.spawn_tile_by_tile_parameters.duration = 1 + story.fail_count * 0.1
			game.spawn_tile_by_tile_parameters.column = 1
			game.spawn_tile_by_tile_parameters.callback_cannot_spawn = function()
				story.level_failed()
			end
		end,

		update = function( dt )
			story_state.time = story_state.time - dt
			if story_state.time<=0 then
				story.level_done()
			end
		end,

		draw_ui = function()
			game_ui.draw_timeattack_timer(story_state.time)
		end
	},

	{
		-- Tetris level
		prefix = "tetromino",
		level = "Tetromino",
		score_goal = 500,
		challenge_reward = 350,

		init = function()
			game.callback_box_shipped = function( box )
				local tile = box.boxtiles[1].tile

				if tile.type~="tetromino1" then return end
				if box.boxtile_size<5 then return end

				for i=2, box.boxtile_size do
					if tile.gx~=box.boxtiles[i].tile.gx then
						return
					end
				end
				
				game.challenge_progress = 1
			end

			bag.callback_init = function()
				bag.add( tilesets["tetromino"], game.board_width * game.board_height )
			end

			bag.callback_empty = function()
				bag.add( tilesets["tetromino"], game.board_width * game.board_height )
			end
		end,
	},

	{
		-- Timeattack
		prefix = "timeattack1",
		level = "Time Attack 1",
		score_goal = 2000,

		init = function()
			game.rare_tile_spawn_rate = 30 + (1 - math.clamp( story.fail_count/3, 0, 1)) * 40
			story_state.time = 3*60
		end,

		update = function(dt)
			story_state.time = story_state.time - dt
			if story_state.time<=0 then
				story.level_failed()
			end
		end,

		draw_ui = function()
			game_ui.draw_timeattack_timer(story_state.time)
			game_ui.draw_score()
		end
	},

	{
		-- Dropping pasta
		prefix = "pasta",
		level = "Pasta Party",
		score_goal = 1500,

		init = function()
			game.rare_tile_spawn_rate = 0
			game.set_tileset( "pasta", true )
			clock.disable()
			game.initial_filled_lines = 2

			story_state.time = 0
			story_state.is_overflowing = false

			game.spawn_function = spawn_tile_by_tile
			game.spawn_tile_by_tile_parameters.time = 0
			game.spawn_tile_by_tile_parameters.duration = 1
			game.spawn_tile_by_tile_parameters.column = 0
			game.spawn_tile_by_tile_parameters.callback_cannot_spawn = function()
				story_state.is_overflowing = true
			end
			game.spawn_tile_by_tile_parameters.callback_spawn = function()
				story_state.is_overflowing = false
				story_state.time = 0
			end
		end,

		update = function(dt)
			local speed = (1/1000) * (1 - math.clamp( story.fail_count/3, 0, 1))
			game.spawn_tile_by_tile_parameters.duration = max( game.spawn_tile_by_tile_parameters.duration-dt*speed, 0.4)

			if story_state.is_overflowing and game.has_moving_tile==false then
				story_state.time = story_state.time + dt

				local force = 3 + story_state.time
				
				game.board_x = rand(-force,force)
				game.board_y = 10

				if story_state.time>2 then
					story.level_failed()
				end
			else
				game.board_x = 0
				game.board_y = 10
			end
		end
	},

	{
		-- All the soap
		prefix = "send_all",
		level = "Send all",

		tileset = { "cosmetics3", "dogs1", "dogs4", "tutorial1" },

		init = function()
			clock.disable()
			game.set_tileset( story_level.tileset, true )

			story_state.count = 0
			story_state.tile_count = 0
			story_state.time = -1
			game.show_point_notification = false

			bag.callback_init = function()
				bag.add( "cosmetics3", 50 )
				bag.add( "dogs1", 33 )
				bag.add( "dogs4", 33 )
				bag.add( "tutorial1", 34 )
			end

			bag.callback_empty = function()
				bag.add( "dogs1", 33 )
				bag.add( "dogs4", 33 )
				bag.add( "tutorial1", 34 )
			end

			game.callback_shipping = function()
				if story_state.time>=0 then return end

				story_state.count = story_state.count + 1
				local tile_count = game.board_width * game.board_height
				local trash_count = 0
				local has_forbidden_tile = false

				for i = tile_count, 1, -1 do
					local tile = game.grid[i]
					if tile and tile.is_boxed==false then
						tile.value = 0
						if tile.type~="cosmetics3" then
							trash_tile( tile , 0.7 + trash_count * 0.04)
						elseif story_state.time<0 then
							has_forbidden_tile = true


							-- hack hack hack
							trash_tile( tile )
							tile.anim_y:from(0):sleep(10)
							tile.anim_x:from(0)
							tile.trash_anim_y = tile.anim_y
							tile.trash_anim_x = tile.anim_x
						end
						trash_count = trash_count + 1
					end
				end

				startTrashAnim()
				sfx.play("trashing")


				if has_forbidden_tile then
					story_state.time = 0.7 + trash_count * 0.04 + 0.5
				end
			end

			game.callback_combo_finished = function()
				if story_state.count >= 5 and story_state.time<0 then
					story.level_done()
				end
			end
		end,

		update = function(dt)
			if story_state.time>=0 then
				story_state.time = story_state.time - dt
				if story_state.time<=0 then
					story.level_failed()
				end
			end
		end,

		draw_ui = function()
			local count, total = 0, 0
			for index, tile in grid() do
				if tile.type=="cosmetics3" then
					total = total + 1
					if tile.is_boxed then
						count = count + 1
					end
				end
			end

			game_ui.draw_order_sheet( loc("ui_order_sheet"), "cosmetics3", count, total)
			game_ui.draw_shipment_count( story_state.count, 5 )
		end
	},

	{
		-- Insurance scam
		prefix = "insurance_scam",
		level = "Insurance scam",

		goal = 30,

		init = function()
			story_state.time = 2*60 + story.fail_count * 20
			story_state.count = 0
			game.rare_tile_spawn_rate = 0
			clock.set_duration(10, 5)
			game.show_point_notification = false

			game.callback_box_trashed = function( box )
				story_state.count = story_state.count + 1
			end
		end,

		update = function(dt)
			if story_state.count>=story_level.goal then
				story.level_done()
			end

			story_state.time = story_state.time - dt
			if story_state.time<=0 then
				story.level_failed()
			end
		end,

		draw_ui = function()
			game_ui.draw_timeattack_timer( story_state.time )
			game_ui.draw_label_and_bar( loc("ui_insurance"), story_state.count, story_level.goal )
		end
	},

	{
		-- Robot tutorial
		comic = "page08",

		prefix = "robot0",
		level = "Robot uprising tutorial",
		robot_goal = 10,

		init = function()
			clock.disable()
			game.set_tileset("robot", true)
			game.query_function = query_robot
			game.drop_speed = 100
			game.initial_filled_lines = 0
			game.character_rating = false
			game.show_point_notification = false
			game.rare_tile_spawn_rate = 0

			story_state.robot = 0
			story_state.time = 0
			story_state.initial_spawn = false

			bag.callback_init = nil
			bag.callback_empty = function()
				bag.add("robot1", 10)
				bag.add("robot2", 10)
				bag.add("robot3", 10)
			end

			game.spawn_function = function(dt)
				if story_state.robot==0 then
					if story_state.initial_spawn==false then
						story_state.initial_spawn = true
						new_tile( 1, game.board_height, "robot1" )
						new_tile( 3, game.board_height, "robot2" )
						new_tile( 5, game.board_height, "robot3" )
					end
					return
				end
				story_state.time = story_state.time + dt
				if story_state.time > 3 then
					story_state.time = 0
					new_top_tile( 1 )
				end
			end

			game.callback_box_shipped = function( box )
				story_state.robot = story_state.robot + 1

				if story_state.robot==1 then
					character.quicktalk("talk_robot_more")
				end
			end
		end,

		update = function(dt)
			if story_state.robot==0 then
				character.talk("talk_robot_instruction")
			end

			if story_state.robot>=story_level.robot_goal then
				story.level_done()
			end
		end,

		draw_ui = function()
			game_ui.draw_order_sheet( loc("ui_robots"), "robot1", story_state.robot, story_level.robot_goal )
		end
	},

	{
		-- robot level
		prefix = "robot1",
		level = "Robot uprising part 2",
		robot_goal = 40,
		energy_goal = 20,

		init = function()
			game.set_tileset("robot", true)
			game.query_function = query_robot
			game.show_point_notification = false
			game.rare_tile_spawn_rate = 0

			story_state.energy = 0
			story_state.robot = 0

			character.talk("talk_robot_energy", 5)

			game.spawn_function = spawn_tile_by_tile
			game.spawn_tile_by_tile_parameters.time = 0
			game.spawn_tile_by_tile_parameters.duration = 1
			game.spawn_tile_by_tile_parameters.column = 0
			game.initial_filled_lines = 3


			game.callback_box_shipped = function( box )
				local tile = box.boxtiles[1].tile
				if tile.type=="robot4" then
					story_state.energy = story_state.energy + box.boxtile_size
				else
					story_state.robot = story_state.robot + box.boxtile_size
				end
			end
		end,

		update = function(dt)
			if story_state.robot>=story_level.robot_goal and story_state.energy>=story_level.energy_goal then
				story.level_done()
			end
		end,

		draw_ui = function()
			game_ui.draw_order_sheet( loc("ui_robots"), "robot1", story_state.robot, story_level.robot_goal )
			game_ui.draw_order_sheet( loc("ui_energy"), "robot4", story_state.energy, story_level.energy_goal )
		end
	},

	{
		-- robot level
		comic = "page09",

		prefix = "robot2",
		level = "Robot uprising part 3",
		robot_goal = 8,

		init = function()
			game.set_tileset()
			game.query_function = query_robot_and_matching_group
			game.show_point_notification = false
			game.rare_tile_spawn_rate = 0

			story_state.robot = 0

			game.character_rating = false
			character.talk("talk_robot_trash", 5)

			bag.callback_init = nil
			bag.callback_empty = function()
				bag.add( game.spawn_tiles, 24 )
				bag.add("robot1", 2)
				bag.add("robot2", 2)
				bag.add("robot3", 2)
			end

			game.callback_box_created = function( box )
				box.time = 0
			end
		end,

		update = function(dt)
			rubbles.update( dt )

			for index, box in valid_boxes() do
 				if box.state=="gameplay" and box.boxtiles[1].tile.type=="robot1" then

					box.time = box.time + dt

					if box.time>=1 then
						story_state.robot = story_state.robot + 1

						for i=1, box.boxtile_size do
							local tile = box.boxtiles[i].tile
							explode_tile( get_tile(tile.gx, tile.gy), tile.x, tile.y )
							explode_tile( get_tile(tile.gx+1, tile.gy), tile.x, tile.y )
							explode_tile( get_tile(tile.gx-1, tile.gy), tile.x, tile.y )
							explode_tile( get_tile(tile.gx, tile.gy-1), tile.x, tile.y )
							explode_tile( get_tile(tile.gx, tile.gy+1), tile.x, tile.y )

						end
						sfx.play("robot_explosion")
						screenshake.set( 6, 0.6)
						rubbles.spawn( story_state.robot*2 )
						game.trashing_count = game.trashing_count + 1
					else
						box.x, box.y = get_tile_position(box.gx, box.gy)

						local rand_range = 2 + 5*box.time
						box.x = box.x + rand(-rand_range, rand_range)
						box.y = box.y + rand(-rand_range, rand_range)
						box_update_sprite( box )
					end
				end
			end

			if story_state.robot>=story_level.robot_goal and game.trashing_count==0 then
				story.level_done()
			end
		end,

		draw_ui = function()
			game_ui.draw_order_sheet( loc("ui_robots_in_trash"), "robot1", story_state.robot, story_level.robot_goal )
		end
	},

	{
		-- Final level
		comic = "page10",

		prefix = "Finale",
		level = "Final Level",
		max_boost = 30,
		duration = 240,--270,

		init = function()
			background.set(story_state.background_image)
			game.music_track = nil
			music.play("Were_Finally_Landing", false)
			game.rare_tile_spawn_rate = 50
			character.disable()
			game.show_point_notification = false
			game.character_rating = false
			game.set_tileset( "space", true )
			clock.disable()

			story_state.count = 40000000
			story_state.speed = 100
			story_state.boost = sequence.new():from(1)
			story_state.time = 0

			story_state.earth_position = sequence.new():from(110):to(240, 15, "linear"):start()
			story_state.mars_position = sequence.new():from(-210):sleep(story_level.duration-40):to(0, 40, "linear"):start()

			story_state.moon_position = sequence.new():from(-210):sleep(90):to(240, 60, "linear")
			story_state.moon_time = 0

			local star_count = 70
			story_state.stars = table.create(star_count)
			for i=1, star_count do
				table.insert(story_state.stars, {
					x = rand(1, 400),
					y = rand(1, 400),
					d = rand(1, 0.3)
				})
			end

			game.callback_combo_finished = function(score, combo)
				local current_boost = story_state.boost:get()
				story_state.boost:from(current_boost):to(math.infinite_approach(1, story_level.max_boost, 600, score), 0.3, "inOutCubic"):sleep(0.13*combo):to(1, 0.7, "inOutCubic"):start()
				sfx.play("boost", math.clamp( combo/4, 0, 1))
				sfx.play("wind", 0)
			end
		end,

		update = function(dt)
			story_state.time = story_state.time + dt
			if story_state.time >= story_level.duration then
				mode.set(menu)
				comic_reader.view_comic( "page11", true )
			end

			game.board_x = 68 + math.cos(story_state.time*0.5)*20
			game.board_y = 0 + math.sin(story_state.time*0.8)*6

			-- speed/Boost
			local boost = story_state.boost:get()
			story_state.speed = 100 * boost
			sfx.setVolume( "wind", math.clamp((boost-1)/10, 0, 1) )

			-- assets position
			story_state.moon_time = story_state.moon_time + dt*boost

			-- distance to go (with catching up)
			local level_progress01 = story_state.time / story_level.duration
			story_state.count = story_state.count - story_state.speed*dt*1000 * (1-level_progress01)

			local timeleft = story_level.duration - story_state.time
			if timeleft then
				local catch_up_per_second = story_state.count/timeleft * level_progress01
				story_state.count = story_state.count - catch_up_per_second*dt
			end

			for index, star in pairs(story_state.stars) do
				star.y = star.y + star.d*story_state.speed*dt
				if star.y > 400 then
					star.x = rand(1, 400)
					star.y = 1
				end
			end

			call( story_level.draw_space )
			background.force_redraw()
		end,

		draw_space = function()
			local gfx = playdate.graphics
			gfx.lockFocus(story_state.background_image)
			gfx.clear(black)
			gfx.setColor(white)

			for index, star in pairs(story_state.stars) do
				local length = max(star.d*story_state.speed*0.03, 1)
				gfx.drawLine(star.x, star.y, star.x, star.y - length )
			end

			-- format big number
			local number = math.floor(story_state.count)
			local million = math.floor(number/1000000)
			number = number - million*1000000
			local thousand = math.floor(number/1000)
			number = number - thousand*1000

			local format = "Miles: "
			if million>0 then
				format = format..million.."."
			end
			if thousand>0 then
				local thousand_string = tostring(thousand)
				format = format..string.rep("0", 3-string.len(thousand_string))..thousand_string.."."
			end
			local remain_string = tostring(number)
			format = format..string.rep("0", 3-string.len(remain_string))..number

			set_font("space")
			playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			gfx.drawText( format, 5, 220)
			playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
			default_font()

			images.earth:draw(0, story_state.earth_position:get())
			images.moon:draw(300, story_state.moon_position:get(story_state.moon_time))
			images.mars:draw(0, story_state.mars_position:get())
			images.spacesuit:draw(math.cos(story_state.time*0.6)*5-5, 50 + math.cos(story_state.time*0.4)*10 + math.cos(story_state.time)*6)

			gfx.unlockFocus()

		end,
	},

}

-- create memo lists
for index, store_level in pairs(story_levels) do
	local prefix = store_level.prefix

	if not prefix then
		print("!! Warning. Missing prefix in story level"..index..store_level.name)
	end

	-- check memo_pause
	if not store_level.memo_pause then
		local key = prefix.."_pause_memo"
		if hasLocalizedText( key ) then
			store_level.memo_pause = key
		else
			print("!! Warning. Story level "..index.." - "..prefix.." miss pause_memo loca key")
		end
	end

	-- check memo intro
	if not store_level.memo_intro then
		store_level.memo_intro = table.create(8,0)

		local count = 1
		local keyfound

		if hasLocalizedText( prefix.."_memo_"..count )==false then
			print("!! Warning. Story level"..prefix.."miss memo_1 loca key")
		end

		repeat
			local key = prefix.."_memo_"..count
			keyfound = hasLocalizedText( key )
			if keyfound then
				table.insert(store_level.memo_intro, key)
				count = count + 1
			end
		until keyfound==false
	end
end