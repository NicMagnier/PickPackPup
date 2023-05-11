score = {
	penalty = 0,
}

-- private member
local _combo_display_current = 1
local _combo_display_total = 0
local _combo_display_time = 0
local _combo_display_delay = 0
local _combo_display_anim = sequence.new():from(-10):to(0, 0.3, "outBack")

local _point_potential = 0
local _combo_potential = 0
local _score_potential = 0

local _combo_background = playdate.graphics.image.new("images/combo/combo_background")
local _combo_image = table.create(10)
_combo_image[2] = playdate.graphics.image.new("images/combo/combo_2")
_combo_image[3] = playdate.graphics.image.new("images/combo/combo_3")
_combo_image[4] = playdate.graphics.image.new("images/combo/combo_4")
_combo_image[5] = playdate.graphics.image.new("images/combo/combo_5")
_combo_image[6] = playdate.graphics.image.new("images/combo/combo_6")
_combo_image[7] = playdate.graphics.image.new("images/combo/combo_7")
_combo_image[8] = playdate.graphics.image.new("images/combo/combo_8")
_combo_image[9] = playdate.graphics.image.new("images/combo/combo_9")
_combo_image[10] = playdate.graphics.image.new("images/combo/combo_10")

local _sprite_background = playdate.graphics.sprite.new()
_sprite_background:setImage(_combo_background)
_sprite_background:setVisible(false)
_sprite_background:setCenter(1,0)
_sprite_background:moveTo(400,0)
_sprite_background:setZIndex(layer.combo_background)
_sprite_background:add()
local _sprite_combo = playdate.graphics.sprite.new()
_sprite_combo:setCenter(1,0)
_sprite_combo:setZIndex(layer.combo)
_sprite_combo:add()

function score.reset()
	game.score = 0
	game.real_score = 0
	_combo_display_current = 1
	_combo_display_total = 0
	_combo_display_time = 0
end

function score.add_combo( value )
	game.points = game.points + value
	game.combo = game.combo + 1
end

-- TODO do not scan all boxes all the time
-- add a potential score and update when boxes are created/shipped/trashed
function score.calculate_potential_score()
	_point_potential = 0
	_combo_potential = 0

	for box_index, box in valid_boxes() do
		if box.state=="gameplay" then
			_point_potential = _point_potential + box.value
			_combo_potential = _combo_potential + 1
		end
	end

	_score_potential = score.get_combo_total( _point_potential, _combo_potential )
end

function score.get_potential_score()
	return _score_potential
end

function score.get_combo_multiplier( combo )
	combo = combo or game.combo

	local combo_multiplier_table = {
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10,
		11,
		12,
		13,
		14,
	}

	return combo_multiplier_table[combo] or 1
end

function score.get_combo_total( points, combo )
	points = points or game.points
	return math.ceil( points * score.get_combo_multiplier( combo ))
end

function score.get_penalty( object )
	return object.value * score.get_penalty_multiplier()
end

function score.clear_penalty()
	score.penalty = 0
end

function score.add_penalty( object )
	score.penalty = score.penalty + score.get_penalty( object )
end

function score.get_penalty_multiplier()
	local penalty_multiplier = 1
	if game.mode=="normal" then
		penalty_multiplier = 1 + game.normalmode.level * 0.1
	end

	return penalty_multiplier
end

function score.sum_penalty( object )
	return math.floor( score.penalty * 7 ) -- penalty multiplier
end

function score.add( value )
	game.real_score = max(game.real_score + value, 0)
end

function score.substract( value )
	game.real_score = max(game.real_score - value, 0)
end

function score.challenge_reward( value )
	game.real_score = max(game.real_score + value, 0)
	game.score = max(game.score + value, 0)
end

function score.set_goal( score_goal )
	game.score_goal = score_goal
end

function score.stop_sfx()
	sfx.get( "counting_up" ):stop()
	sfx.get( "counting_down" ):stop()
end

function score.update( dt )
	score.update_combo_display( dt )

	if not game.has_moving_tile then
		if game.combo>0 then
			call( game.callback_combo_finished, score.get_combo_total(), game.combo)
		end

		score.calculate_potential_score()
		_score_potential = _point_potential * _combo_potential

		-- get score
		local shipment_value = score.get_combo_total()
		score.add( shipment_value )

		if shipment_value>game.stats.biggest_shipment then
			game.stats.biggest_shipment = shipment_value
			save_game.save()
		end

		-- reset
		game.points = 0
		game.combo = 0
	else
		_score_potential = _point_potential * _combo_potential--_combo_display_current
	end

	if game.show_point_notification then
		local counting_up_sfx = sfx.get( "counting_up" )
		local counting_down_sfx = sfx.get( "counting_down" )
		if game.score>game.real_score then
			if counting_down_sfx:isPlaying()==false then
				counting_down_sfx:play(1)
			end
			counting_down_sfx:setVolume(settings.sound_volume)
		elseif game.score<game.real_score then
			if counting_up_sfx:isPlaying()==false then
				counting_up_sfx:play(1)
			end
			counting_up_sfx:setVolume(settings.sound_volume)
		else
			counting_down_sfx:stop()
			counting_up_sfx:stop()
		end
	end

	local score_still_moving = game.score~=game.real_score
	game.score = math.approach(game.score, game.real_score, 1000*dt)

	if score_still_moving and game.score==game.real_score then
		call( game.callback_score_finished_counting )
	end
end


function score.reset_combo_display()
	_combo_display_current = 0
	_combo_display_time = 0
	_combo_display_total = 0
end

function score.start_combo_display( combo )
	score.reset_combo_display()
	_combo_display_delay = 0.5
	_combo_display_total = combo
	_combo_display_current = 0
end

function score.update_combo_display( dt )
	-- setup sprites
	local show_combo = (_combo_display_current>1) and game.show_combo and _combo_display_total>0
	_sprite_background:setVisible(show_combo)
	_sprite_combo:setVisible(show_combo)
	if show_combo then
		_sprite_combo:setImage(_combo_image[_combo_display_current])
		_sprite_combo:moveTo(400 + _combo_display_anim:get(), 0)
	end

	if _combo_display_total==0 then
		return
	end

	if _combo_display_delay>0 then
		_combo_display_delay = _combo_display_delay - dt
		return
	end

	_combo_display_time = _combo_display_time + dt

	if _combo_display_total>_combo_display_current and _combo_display_time>0.08 then
		_combo_display_current = _combo_display_current + 1
		sfx.playAtRate("combo",  0.5 + _combo_display_current*0.15)
		_combo_display_time = 0
		_combo_display_anim:restart()
	end

	if _combo_display_time>1.5 then
		score.reset_combo_display()
	end

end

function score.draw_combo_display()
	if _combo_display_current<=1 then
		return
	end

	_combo_background:drawAnchored(400, 0, 1, 0)

	local combo_image = _combo_image[_combo_display_current]
	if combo_image then
		combo_image:drawAnchored(400 + _combo_display_anim:get(), 0, 1, 0)
	end

	-- playdate.graphics.setFont(fonts.large)
	-- playdate.graphics.drawTextAligned( _combo_display_current, 390 + _combo_display_anim:get(), 10, kTextAlignment.right)
	-- playdate.graphics.setFont(fonts.default)
end

