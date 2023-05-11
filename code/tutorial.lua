tutorial = {}

-- private members
local _steps = {
	"welcome",
	"move_tile",
	"move_tile_end",
	"match_3tiles",
	"ship_box",
	"ship_single_boxes",
	"ship_single_boxes_end",
	"ship_multiple_box",
	"ship_multiple_box_end",
	"advanced_diagonal",
	"advanced_diagonal_end",
	"tryout_intro",
	"tryout",
}
local _step_index = 1
local _step = 1
local _time = 0
local _tile = nil
local _ship_count = 0

function tutorial.init()
	_step_index = 1
	_step = _steps[_step_index]
	_time = 0
	_ship_count = 0

	game.set_tileset( "tutorial" )
	cursor.gx = 3
	cursor.gy = 3
	clock.disable()
end

function tutorial.next_step()
	_step_index = _step_index + 1
	_step = _steps[_step_index]
	_time = 0

	-- init steps
	if _step=="move_tile" then
		_tile = new_top_tile(1, "tutorial1")
	end

	if _step=="match_3tiles" then
		new_tile(1, 3, "tutorial1")
		new_tile(3, 1, "tutorial1")
	end

	if _step=="ship_single_boxes" then
		_ship_count = 0

		game.callback_box_shipped = function()
			_ship_count = _ship_count + 1
		end
	end

	if _step=="ship_multiple_box" then
		local box

		box = build_box("tutorial1",  2,5,  3,5,  4,5,  2,4,  2,3)
		box.y = box.y - 240
		drop_box( box )
		box_update_sprite( box )

		box = build_box("tutorial1",  3,4,  4,4,  5,4)
		box.y = box.y - 240
		drop_box( box )
		box_update_sprite( box )

		box = build_box("tutorial1",  6,5,  6,4,  6,3,  6,2,  6,1)
		box.y = box.y - 240
		drop_box( box )
		box_update_sprite( box )

		box = build_box("tutorial1",  1,2,  2,2,  3,2,  4,2,  4,3)
		box.y = box.y - 240
		drop_box( box )
		box_update_sprite( box )
	end

	if _step=="advanced_diagonal" then
		game.shipping_enable = false

		box = build_box("tutorial1",  1,3,  1,4,  1,5,  2,3,  2,5)
		box_update_sprite( box )

		box = build_box("tutorial1",  2,2,  3,2,  4,2,  5,2,  6,2)
		box_update_sprite( box )

		box = build_box("tutorial1",  3,4,  3,5,  4,4)
		box_update_sprite( box )

		box = build_box("tutorial1",  4,5,  5,5,  6,5)
		box_update_sprite( box )

		box = build_box("tutorial1",  5,4,  6,4,  6,3)
		box_update_sprite( box )

		new_tile(2, 4, "tutorial1")
		new_tile(3, 3, "tutorial4")
		new_tile(4, 3, "tutorial1")
		new_tile(5, 3, "tutorial1")

		game.callback_box_created = function()
			game.shipping_enable = true
			tutorial.next_step()
			game.callback_box_created = nil
		end
	end

	if _step=="advanced_diagonal_end" then
		game.shipping_enable = true

		game.callback_box_shipped = function()
			tutorial.next_step()
			game.callback_box_shipped = nil
		end
	end

	if _step=="tryout" then
		game.spawn_function = spawn_full_board
		_ship_count = 0

		game.callback_box_shipped = function()
			_ship_count = _ship_count + 1
		end
	end

end

function tutorial.update( dt )
	_time = _time + dt

	if _step=="welcome" then
		character.talk("tutorial_welcome")
		if _time>5 or (_time>2 and input.on(buttonA)) then
			tutorial.next_step()
			return
		end
	end

	if _step=="move_tile" then
		character.talk("tutorial_move_tile")
		if _tile and _tile.gx>=5 and _tile.gy>=4 and input.is(buttonA)==false then
			tutorial.next_step()
			return
		end
	end

	if _step=="move_tile_end" then
		character.talk("tutorial_move_tile_end")
		if character.get_animation()~="bark" or character.is_playing()==false then
			character.set_animation( "happy-wag", 100 )
			character.lock_animation()
		end

		if _time>2 then
			tutorial.next_step()
			character.unlock_animation()
			return
		end
	end

	if _step=="match_3tiles" then
		character.talk("tutorial_match_three_tiles")
		if box_count()>0 then
			tutorial.next_step()
		end
	end

	if _step=="ship_box" then
		if box_count()>0 then
			if _time>2 then
				if game.shipping_count==0 then
					character.talk("tutorial_ship_box")
				end
			else
				character.talk("tutorial_match_three_tiles_end")
			end
		else
			tutorial.next_step()
		end
	end

	if _step=="ship_single_boxes" then
		character.talk("tutorial_ship_single_boxes")

		local box_count = 0
		for i, box in valid_boxes() do
			box_count = box_count + 1
		end

		if _ship_count>=3 and game.shipping_count==0 then
			tutorial.next_step()
		elseif box_count==0 and game.shipping_count==0 then
			local gx

			clear_tile_query_result()

			if cursor.gx<3.5 then
				gx = rand_int(cursor.gx+2, game.board_width)

				if rand_int(0,1)==0 then
					add_to_query_result( new_tile(gx, 5, "tutorial1") )
					add_to_query_result( new_tile(gx, 4, "tutorial1") )
					add_to_query_result( new_tile(gx, 3, "tutorial1") )
				else
					add_to_query_result( new_tile(gx, 5, "tutorial1") )
					add_to_query_result( new_tile(gx-1, 5, "tutorial1") )
					add_to_query_result( new_tile(gx, 4, "tutorial1") )
				end
			else
				gx = rand_int(1, cursor.gx-2)

				if rand_int(0,1)==0 then
					add_to_query_result( new_tile(gx, 5, "tutorial1") )
					add_to_query_result( new_tile(gx, 4, "tutorial1") )
					add_to_query_result( new_tile(gx, 3, "tutorial1") )
				else
					add_to_query_result( new_tile(gx, 5, "tutorial1") )
					add_to_query_result( new_tile(gx+1, 4, "tutorial1") )
					add_to_query_result( new_tile(gx, 4, "tutorial1") )
				end
			end

			-- create a new box
			box = new_box()
			box.y = box.y - 240
			drop_box( box )
			box_update_sprite( box )
		end
	end

	if _step=="ship_single_boxes_end" then
		character.talk("tutorial_ship_single_boxes_end")
		if _time>5 or (_time>2 and input.on(buttonA)) then
			tutorial.next_step()
			return
		end
	end

	if _step=="ship_multiple_box" then
		if box_count()>0 then
			character.talk("tutorial_ship_multiple_box")
		else
			tutorial.next_step()
		end
	end

	if _step=="ship_multiple_box_end" then
		if _time>1.3 then
			tutorial.next_step()
		elseif _time<1 then
		character.talk("tutorial_ship_multiple_box_end")
		end
	end

	if _step=="advanced_diagonal" then
		character.talk("tutorial_advanced_diagonal")
	end

	if _step=="advanced_diagonal_end" then
		character.talk("tutorial_advanced_diagonal_end", 4)
	end

	if _step=="tryout_intro" then
		character.talk("tutorial_tryout_intro", 4)
		if _time>2 then
			tutorial.next_step()
		end
	end

	if _step=="tryout" then
		if _ship_count>5 then
			if _time>15 then
				_time = 0
				character.talk("tutorial_tryout_end", 5)
			end
		else
			if _time>10 then
				_time = 0
				local random_loca = rand_int(1,3)

				if box_count()==0 then
					character.talk("tutorial_tryout_nobox", 2.5)
				elseif random_loca==1 then
					character.talk("tutorial_tryout_1", 1.5)
				elseif random_loca==2 and game.shipping_count==0 then
					character.talk("tutorial_tryout_2", 2.5)
				else
					character.talk("tutorial_tryout_3", 1.5)
				end
			end
		end
	end
end

function tutorial.draw()
end