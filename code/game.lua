
function new_game( game_mode )
	game.mode = game_mode or "normal"

	-- default values
	game.board_x = 0
	game.board_y = 0
	cursor.gx = 3
	cursor.gy = 3
	game.score = 0
	game.score_goal = 0
	game.real_score = 0
	game.lifecount = game.lifecount_max
	game.danger_level = 0
	game.set_tileset( "default" )
	game.spawn_tile_max_try = 3
	game.rare_tile_spawn_rate = 90
	game.character_rating = true
	game.show_point_notification = true
	game.show_combo = true
	game.shipping_enable = true
	game.drop_speed = 500
	game.initial_filled_lines = game.board_height
	game.trash_line_count = 1

	game.music_track = "Radix"
	background.set(images.game_background)

	game.query_function = nil
	game.spawn_function = spawn_full_board
	game.callback_box_shipped = nil
	game.callback_box_created = nil
	game.callback_box_trashed = nil
	game.callback_tile_trashed = nil
	game.callback_combo_finished = nil
	game.callback_line_trashing = nil
	game.callback_shipping = nil
	game.callback_score_finished_counting = nil
	game.spawn_tile_by_tile_parameters.callback_cannot_spawn = nil
	game.spawn_tile_by_tile_parameters.callback_spawn = nil


	bag.callback_empty = bag.default_fill
	bag.callback_init = bag.default_init_fill

	reset_danger_counter()
	clock.reset()
	game_ui.reset()
	character.reset()
	point_notification.reset()
	cursor.enable()
	rubbles.reset()
	cursor.reset()
	score.reset_combo_display()

	-- init game modes
	if game.mode=="normal" then
		character.quicktalk( "talk_intro_normal_mode" )
		game.memo = "normal_pause_memo"

		game.real_score = game.normalmode.safe_score or 0
		game.score = game.normalmode.safe_score or 0
		update_normalmode_level()

		game.normalmode.save_update_timeout = 15
	end

	if game.mode=="tutorial" then
		game.initial_filled_lines = 0
		game.music_track = "If_Im_Wrong"
		game.memo = "tutorial_pause_memo"
		game.spawn_function = nil
		game.character_rating = false
		game.show_point_notification = false
		game.trash_line_count = 0
		game.rare_tile_spawn_rate = 0
		tutorial.init()
	end

	if game.mode=="relax" then
		clock.disable()
		game.board_y = 10
		game.rare_tile_spawn_rate = 0
		game.show_point_notification = false
		game.trash_line_count = 0
		game.show_combo = false
		game.character_rating = false
--		game.music_track = "Were_Finally_Landing"
		game.memo = "relax_pause_memo"
		character.talk( "talk_intro_relax_mode", 5 )

		table.reset(game.relax.previous_results)
		game.relax.result_index = 1
		game.relax.result_size = 10
	end

	if game.mode=="withgameover" then
		game.memo = "withgameover_pause_memo"
	end

	if game.mode=="drop" then
		game.spawn_function = spawn_tile_by_tile
		game.spawn_tile_by_tile_parameters.time = 0
		game.spawn_tile_by_tile_parameters.duration = 2
		game.spawn_tile_by_tile_parameters.column = 0
		game.initial_filled_lines = 3

		game.memo = "drop_pause_memo"

		clock.disable()
	end

	if game.mode=="story" then
		story.game_init()
	end

	if game.mode=="timeattack" then
		game.timeattack.time = 2*60
		game.memo = "timeattack_pause_memo"
		rare_tile_spawn_rate = 50
		character.talk( "talk_intro_timeattack_mode", 5 )
	end

	if game.mode=="bomb" then
		game.bomb.has_exploded = false
		game.memo = "bomb_pause_memo"
		bag.callback_empty = bag.bomb_fill
		character.talk( "talk_intro_bomb_mode", 5 )

		game.callback_box_shipped = function( box )
			local tile = box.boxtiles[1].tile
			if tile.is_bomb then
				game.danger_level = game.danger_level + 1
			end
		end
	end

	if game.mode=="secret" then
		game.memo = "secret_pause_memo"

		game.spawn_function = spawn_full_board
		game.secret.shipment_count = 0
		game.set_tileset( "secret" )
		clock.disable()

		bag.callback_init = function()
			bag.add( game.spawn_tiles, 200 )
			bag.add( tilesets["rare"], 5 )
		end

		bag.callback_empty = function()
			bag.add( game.spawn_tiles, 12 )
		end

		game.callback_shipping = function()
			game.secret.shipment_count = game.secret.shipment_count + 1

			-- we immediatly stop spawning tiles
			if game.secret.shipment_count>=10 then
				game.spawn_function = nil
			end
		end

		game.callback_combo_finished = function()
			if game.secret.shipment_count<10 then return end

			-- stop the game
			game.shipping_enable = false
		end

		game.callback_score_finished_counting = function()
			if game.secret.shipment_count<10 then return end

			local old_highscore = game.secret.highscore
			game.real_score = math.floor(game.real_score)

			if game.real_score > game.secret.highscore then
				game.secret.highscore = game.real_score
				save_game.save()
			end

			-- check highscore
			mode.push( gameover, old_highscore, game.secret.highscore )
		end
	end

	-- clean the board
	free_all_tiles()
	free_all_box()
	for i = 1, game.board_width*game.board_height do
		game.grid[i] = false
	end

	-- create new sub-tileset to use for this board
	bag.reset()
	if type(game.spawn_tileset)=="table" then
		bag.add( game.spawn_tileset )
	else
		bag.add( tilesets[game.spawn_tileset] )
	end
	bag.shuffle()
	table.reset(game.spawn_tiles)
	table.insert(game.spawn_tiles, bag.get())
	table.insert(game.spawn_tiles, bag.get())
	table.insert(game.spawn_tiles, bag.get())
	table.insert(game.spawn_tiles, bag.get())
	bag.reset()

	-- setup rare tile animation
	local anim = game.rare_tile_anim
	anim.imageTable = tilesets_images["rare"]
	anim.delay = 110
	anim.loop = true

	-- fill the board
	bag.init()
	for gy = game.board_height, game.board_height - game.initial_filled_lines + 1, -1 do
		for gx = 1, game.board_width do
			local tile = new_tile(gx, gy)
			tile.y = tile.y - 10 - (game.board_height-gy)*(game.board_height-gy)*5 - gx*gx
			tile.is_moving = true
		end
	end

	-- play the game music
	music.play( game.music_track )

	-- prepare pause screen (story mode handle memos on its own )
	pause.prepareSystem()
end


function game.init( game_mode )
	new_game( game_mode )
end

function game.shutdown()
	score.stop_sfx()
	clock.stop_sfx()
	screenshake.disable()
end

--used by story mode
function game.quit()
	score.stop_sfx()
	music.stop()
	mode.back()
	save_game.save()
end

function game.resume()
end

function game.set_tileset( normal_set, force )
	if (not force) and custom_tileset.enable then
		game.spawn_tileset = custom_tileset.list
		return
	end

	game.spawn_tileset = normal_set or "default"
end

function game.update(dt)
	-- pause the game
	if input.on(buttonB) then
		mode.push_overlay( pause )
		return
	end

	-- we drop the tile we were holding
	-- we do it before moving the cursor
	if input.off(buttonA) then
		drop_tile( get_current_tile() )
	end


	-- Inputs
	local dx, dy = 0, 0
	if cursor.is_patting()==false then
		if input.onRepeat(buttonDown)	then dy = dy + 1 end
		if input.onRepeat(buttonUp)		then dy = dy - 1 end
		if input.onRepeat(buttonRight)	then dx = dx + 1 end
		if input.onRepeat(buttonLeft)	then dx = dx - 1 end
	end

	local new_cursor_gx = math.clamp(cursor.gx + dx, 1, game.board_width)
	local new_cursor_gy = math.clamp(cursor.gy + dy, 1, game.board_height)
	local has_cursor_moved = new_cursor_gx~=cursor.gx or new_cursor_gy~=cursor.gy

	-- Update cursor
	local previous_gx = cursor.gx
	local previous_gy = cursor.gy
	cursor.gx = new_cursor_gx
	cursor.gy = new_cursor_gy

	-- Tile swapping
	if has_cursor_moved and input.is(buttonA) then
		local dragged_tile = get_tile(previous_gx, previous_gy)

		if drag_tile( dragged_tile, new_cursor_gx, new_cursor_gy) then
			sfx.play( "swap" )
		else
			cursor.gx = previous_gx
			cursor.gy = previous_gy
			has_cursor_moved = false
		end
	end

	if has_cursor_moved then
		sfx.play( "select" )
	end

	-- shipping handling
	local tile = get_tile(cursor.gx, cursor.gy)
	local on_box = tile and tile.is_boxed and tile.box.state=="gameplay" and tile.is_moving==false
	if game.shipping_enable and input.on(buttonA) and on_box and cursor.is_patting()==false then
		sfx.play( "shipping" )
		call( game.callback_shipping )

		-- ship all boxes
		local shippedBoxCount = 0
		for _, box in ipairs(game.boxes) do
			if box.is_free==false and box.state=="gameplay" then
				ship_box( box, (abs(box.gx - cursor.gx) + abs(box.gy - cursor.gy))*0.05 )
				shippedBoxCount = shippedBoxCount + 1
			end
		end
		score.start_combo_display( shippedBoxCount )

		-- in relax mode, trash all the tiles on screen
		if game.mode=="relax" then
			local trash_count = 0
			local tile_count = game.board_width * game.board_height
			for i = tile_count, 1, -1 do
				local tile = game.grid[i]
				if tile and (tile.state=="gameplay" or tile.state=="dropping") then
					trash_tile( tile , 0.7 + trash_count * 0.04)
					trash_count = trash_count + 1
				end
			end

			local relax_score = tile_count - trash_count

			startTrashAnim()
			sfx.play("trashing")

			-- comments on result
			if trash_count==0 then
				character.talk_string(loc_format("relax_rating_perfect", relax_score))
			elseif trash_count==1 then
				character.talk_string(loc_format("relax_rating_near_perfect", relax_score))
			elseif trash_count<=3 then
				character.talk_string( loc_format("relax_rating_excellent", relax_score), 3)
			elseif trash_count<=6 then
				character.talk_string( loc_format("relax_rating_great", relax_score), 3)
			elseif trash_count<=9 then
				if rand_int(1,2)==1 then
					character.talk_string(loc_format("relax_rating_good_1", relax_score), 3)
				else
					character.talk_string( loc_format("relax_rating_good_2", relax_score), 3)
				end
			elseif trash_count<=15 then
				if rand_int(1,2)==1 then
					character.talk_string( loc_format("relax_rating_low_1", relax_score), 3)
				else
					character.talk_string( loc_format("relax_rating_low_2", relax_score), 3)
				end
			else
				if rand_int(1,2)==1 then
					character.talk_string(loc_format("relax_rating_bad_1", relax_score), 3)
				else
					character.talk_string( loc_format("relax_rating_bad_2", relax_score), 3)
				end
			end

			-- we save the result in the result table
			local relax_mode = game.relax
			local results = relax_mode.previous_results

			results[relax_mode.result_index] = relax_score
			relax_mode.result_index = relax_mode.result_index + 1
			if relax_mode.result_index>relax_mode.result_size then
				relax_mode.result_index = 1
			end

			-- check if we have enough results
			if #results>=relax_mode.result_size then
				local total = 0
				for i, score in pairs(results) do
					total = total + score
				end

				if relax_mode.highscore==-1 then
					character.talk("talk_relax_first_highscore", 5)
					relax_mode.highscore = total
					save_game.save()
					sfx.play("challenge_completed")
				elseif total>relax_mode.highscore then
					character.talk_string(loc_format("talk_relax_new_highscore", get_relax_average( total )), 3)
					relax_mode.highscore = total
					sfx.play("challenge_completed")
					save_game.save()
				end
			end

		end

		if game.character_rating then
			local shipping_score = score.get_potential_score()
			if shipping_score==5 then
				character.quicktalk("rating_onebox")
			elseif shipping_score<=50 then
				character.quicktalk("rating_1")
			elseif shipping_score<=100 then
				character.quicktalk("rating_2")
			elseif shipping_score<=300 then
				character.quicktalk("rating_3")
			elseif shipping_score<=500 then
				character.quicktalk("rating_4")
			elseif shipping_score<=700 then
				character.quicktalk("rating_5")
			elseif shipping_score<=1000 then
				character.quicktalk("rating_6")
			else
				character.quicktalk("rating_7")
			end
		end
	end

	-- Various updates that need to run even when tiles are moving
	point_notification.update( dt )

	-- check if there is tiles that are moving
	game.has_moving_tile = false
	for i, tile in ipairs(game.tiles) do
		if tile.is_free==false and (tile.state=="trashing" or tile.state=="shipping") then
			game.has_moving_tile = true
			break
		end
	end

	-- optimization, we don't run GB during animations, Save the frames
	-- Disable this for now since it seems it might affect a random crash
	-- https://dev.panic.com/Playdate/Playdate/-/issues/328
	playdate.setCollectsGarbage(not game.has_moving_tile)

	-- check if this is gameover
	if game.mode=="withgameover" and game.lifecount<=0 then
		mode.push( gameover )
	end

	-- update timer
	clock.update( dt )

	-- we remove all the tiles at the bottom
	if clock.has_ended() and game.trash_line_count>0 then

		call( game.callback_line_trashing )
		score.clear_penalty()

		for y = 1, game.trash_line_count do
			local gy = game.board_height + 1 - y
			for gx=1, game.board_width do
				local tile = get_tile(gx, gy)
				if tile and tile.is_moving==false then
					trash_tile( tile , gx * 0.04)

					if tile.is_bomb and not tile.is_boxed then
						game.bomb_explodes( tile )
					end
				end
			end
		end

		startTrashAnim()
		sfx.play("trashing")

		local total_penalty = score.sum_penalty()
		if total_penalty > 0 then
			score.substract( total_penalty )
			point_notification.new( -total_penalty, game.board_width*game.tile_size*0.5, 200 )
		end
	end

 	-- We call the function that spawn tiles
	if game.has_moving_tile==false then
		call( game.spawn_function, dt)
	end

	-- update all the tiles
	game.is_trashing = false
	game.shipping_count = 0
	game.trashing_count = 0
	game.unmatched_count = 0
	game.matched_count = 0

	for i = game.board_width*game.board_height, 1, -1 do
		local tile = game.grid[i]

		if not tile then
			goto skip_loop
		end

		if tile.is_boxed then
			goto skip_loop
		end

		if tile.is_free then
			goto skip_loop
		end

		if tile.swap_dx~=0 or tile.swap_dy~=0 then
			local x_done, y_done
			tile.swap_dx, x_done = math.approach(tile.swap_dx, 0, game.swap_speed*dt)
			tile.swap_dy, y_done = math.approach(tile.swap_dy, 0, game.swap_speed*dt)

			if x_done and y_done then
				match_tiles(tile) 

				if not tile.is_boxed then
					drop_tile(tile)
				end
			end
		end

		game.unmatched_count = game.unmatched_count + 1

		-- when tile is being trashed
		if tile.state=="gameplay" then
			local bounce_anim = tile.anim_y
			if bounce_anim:isEmpty()==false then
				local tx, ty = get_tile_position(tile.gx, tile.gy)
				if tile.anim_y:isDone() then
					bounce_anim:clear()
					tile.y = ty
				else
					tile.y = ty + tile.anim_y:get()
				end
			end
		elseif tile.state=="trashing" then
			game.is_trashing = true
			game.trashing_count = game.trashing_count + 1

			local x, y = get_tile_position(tile.gx, tile.gy)
			tile.x = x + tile.trash_anim_x:get()
			tile.y = y + tile.trash_anim_y:get()

			if tile.trash_anim_y:isDone() then
				free_tile(tile)
			end

		-- when the tile is dropping
		elseif tile.state=="dropping" then
			if game.has_moving_tile==false then
				local step_y = game.drop_speed*dt
				local can_drop = tile_can_drop( tile )

				-- should be rare case, when framerate is so bad or drop_speed is massive
				while step_y>game.tile_size do
					if can_drop then
						local gx, gy = tile.gx, tile.gy
						local new_gy = gy + 1
						local below_new_gy = new_gy + 1

						-- move down tile
						set_tile_position(tile, gx, new_gy, false)
						set_grid(gx, gy, nil)

						-- check if we will be able to still go down
						local below_tile = get_tile( gx, below_new_gy )
						local grabbed_by_cursor = cursor.gx==gx and cursor.gy==new_gy and input.is(buttonA)
						can_drop = new_gy<game.board_height and below_tile==nil and grabbed_by_cursor==false

						step_y = step_y - game.tile_size
						tile.y = tile.y + game.tile_size

					-- if we cannot drop, we say the tile will not move further and let below code handling it
					else
						step_y = 0
						_, tile.y = get_tile_position(tile.gx, tile.gy)
					end
				end

				-- Finner tile placement
				if can_drop then
					local gx, gy = tile.gx, tile.gy
					local tx, ty = get_tile_position(gx, gy)
					ty = ty + 15 -- we go lower than the tile border to actually change tile
					local diff_y = ty - tile.y

					tile.y = tile.y + step_y
					tile.is_moving = true

					if step_y>diff_y then
						set_tile_position(tile, gx, gy+1, false)
						set_grid(gx, gy, nil)
					end
				else
					local tx, ty = get_tile_position(tile.gx, tile.gy)
					local diff_y = ty - tile.y

					if step_y<diff_y then
						tile.y = tile.y + step_y
						tile.is_moving = true
					else
						tile.y = ty
						tile.is_moving = false
						tile.state = "gameplay"
						tile.anim_y:from(0)--:to( 1+rand(0,3), 0.1+rand(0,0.05), "outBack"):to( 0, 0.1):start()
						match_tiles(tile)
					end
				end
			end
		end

		-- update sprite
		tile.sprite:moveTo( game.board_x + tile.x + tile.swap_dx, game.board_y + tile.y + tile.swap_dy )
		if tile.is_rare then
			tile.sprite:setImage( game.rare_tile_anim:image() )
		end

		::skip_loop::
	end

	-- update all the boxes
	for _, box in ipairs(game.boxes) do
		if box.is_free then
			goto skip_update_box_loop
		end

		game.matched_count = game.matched_count + box.boxtile_size

		-- when box is being shipped
		if box.state=="shipping" then
			game.shipping_count = game.shipping_count + 1

			box.x = box.anim_x:get()
			box.y = box.anim_y:get()

			if box.anim_x:isDone() and box.anim_y:isDone() then
				call( game.callback_box_shipped, box)
				score.add_combo( box.value )
				free_box(box)
			end

		-- when box is being trashed
		elseif box.state=="trashing" then
			game.trashing_count = game.trashing_count + 1

			local x, y = get_tile_position(box.gx, box.gy)
			box.x = x + box.trash_anim_x:get()
			box.y = y + box.trash_anim_y:get()

			if box.trash_anim_y:isDone() then
				free_box(box)

				if game.mode=="withgameover" then
					game.lifecount = game.lifecount - 1
				end
			end

		-- normal gameplay
		else
			-- check if the box under is free
			if game.has_moving_tile==false then
				-- move the tile to its target
				local tx, ty = get_tile_position(box.gx, box.gy)
				local y_done

				box.x = tx
				box.y, y_done = math.approach( box.y, ty, game.drop_speed*dt)

				box.x = box.x + box.anim_x:get()
				box.y = box.y + box.anim_y:get()

				local is_moving = not y_done
				for i = 1, box.boxtile_size do
					box.boxtiles[i].tile.is_moving = is_moving
				end
			end
		end

		-- update sprite
		box_update_sprite( box )

		::skip_update_box_loop::
	end

	-- update character animation
	local is_in_danger = clock.in_danger()
	if game.mode=="drop" then
		is_in_danger = false
	end
	if playdate.isCrankDocked() then
		if game.has_moving_tile then
			character.set_animation( "happy-wag", 100 )
		elseif is_in_danger then
			character.set_animation( "danger", 130 )
		else
			character.set_animation( "idle", 150 )
		end
	else
		if playdate.getCrankChange()~=0 then
			character.set_animation( "happy-wag", 100 )
		else
			character.set_animation( "idle", 100 )
		end
	end 

	-- Updates
	score.update( dt )
	character.update( dt )
	cursor.update( dt )
	game.rare_tile_anim:update( dt )

	-- Mode Updates
	if game.mode=="normal" then

		update_normalmode_level()

		if game.real_score > game.normalmode.highscore then
			game.normalmode.highscore = game.real_score
			save_game.save()
		end

		game.normalmode.save_update_timeout = game.normalmode.save_update_timeout - dt
		if game.normalmode.save_update_timeout<0 then
			game.normalmode.save_update_timeout = 15

			-- get potential penatly points
			score.clear_penalty()
			table.reset(game.normalmode.boxlist)

			for gx=1, game.board_width do
				local tile = get_tile(gx, game.board_height)
				if tile then
					if tile.is_boxed then
						table.insert_unique(game.normalmode.boxlist, tile.box)
					else
						score.add_penalty( tile )
					end
				end
			end
			
			for _, box in pairs(game.normalmode.boxlist) do
				score.add_penalty( box )
			end

			local maximum_score = game.real_score - score.sum_penalty()
			game.normalmode.safe_score = max(maximum_score - maximum_score%1000, 0)
			save_game.save()
		end

	end

	if game.mode=="story" then
		story.game_update( dt )
	end

	if game.mode=="tutorial" then
		tutorial.update( dt )
	end

	if game.mode=="bomb" then
		clock.set_duration( max(5, clock.duration - (dt/35)) )

		if game.bomb.has_exploded then
			if game.trashing_count==0 then
				local old_highscore = game.bomb.highscore
				game.real_score = math.floor(game.real_score)

				if game.real_score > game.bomb.highscore then
					game.bomb.highscore = game.real_score
					save_game.save()
				end

				mode.push( gameover, old_highscore, game.bomb.highscore )
			end
		end
	end

	if game.mode=="timeattack" then
		game.timeattack.time = game.timeattack.time - dt
		if game.timeattack.time <= 0 then
			local old_highscore = game.timeattack.highscore
			game.real_score = math.floor(game.real_score)

			if game.real_score > game.timeattack.highscore then
				game.timeattack.highscore = game.real_score
				save_game.save()
			end

			-- check highscore
			mode.push( gameover, old_highscore, game.timeattack.highscore )
		end
	end

end

function game.draw()
	game_ui.draw()

	-- render sprites
	playdate.graphics.sprite.update()

	-- for index, tile in pairs(game.tiles) do
	-- 	if tile.is_free==false then
	-- 		local x, y = get_tile_position(tile.gx, tile.gy)
	-- 		playdate.graphics.drawRect(game.board_x + x, game.board_y + y, game.tile_size, game.tile_size)
	-- 	end
	-- end
end

function game.bomb_explodes( bomb_tile )
	game.bomb.has_exploded = true
	game.spawn_function = nil

	local bx, by = get_tile_position(bomb_tile.gx, bomb_tile.gy)

	for i=1, game.board_width*game.board_height do
		local tile = game.grid[i]
		if tile then
			explode_tile(tile, bx, by)
		end
	end

	sfx.play("explosion")
	screenshake.set( 6, 0.6)

end

-- spawn titles to always make the board full
function spawn_full_board()
	for gx = 1, game.board_width do
		local lowest_free_gy = get_lowest_free_position(gx)

		if lowest_free_gy>0 then
			local tile = new_top_tile( gx )
			if not tile then
				break
			end
		end
	end
end

function spawn_tile_by_tile( dt )
	local params = game.spawn_tile_by_tile_parameters

	params.time = params.time + dt

	-- we have to drop a new tile
	if params.time>params.duration then
		params.time = params.time - params.duration

		-- find next column to drop into
		local found_free_column = false
		local last_free_column = 0
		for gx = game.board_width, 1, -1 do

			if gx==params.column and found_free_column then
				break
			end

			local tile = get_tile(gx, 1)
			if not tile then
				found_free_column = true
				last_free_column = gx
			end
		end

		params.column = last_free_column

		-- gameover if there is no free column anymore
		if not found_free_column then
			call(params.callback_cannot_spawn)
		else
			-- drop a new tile in the free column
			local lowest_free_gy = get_lowest_free_position(params.column)
			if lowest_free_gy>0 then
				local tile = new_top_tile( params.column )
				tile.y = -game.tile_size
				call(params.callback_spawn, tile)
			end
		end
	end
end

function update_normalmode_level()
	if not game.real_score then
		game.normalmode.level = 0
	else
		game.normalmode.level = math.floor(game.real_score/1000)
	end
end

function get_relax_average( score )
	return string.format("%.1f", score/10)
end

function print_board()
	for gy = 1, game.board_height do
		local line = ""
		for gx = 1, game.board_width do
			local tile = get_tile(gx, gy)

			if not tile then
				line = line.." "
			elseif tile.gx~=gx or tile.gy~=gy then
				line = line.."!"
			elseif tile.is_boxed then
				if tile.box then
					line = line.."B"
				else
					line = line.."#"
				end
			else
				line = line.."X"
			end
		end

		print(line)
	end
end
