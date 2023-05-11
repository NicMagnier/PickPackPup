game_ui = {
	top_margin = 3,
	left_margin = 270,
	between_space = 10,

	x = 0,
	y = 0,
}

-- function draw_widget(sprite, x, y, w, h)
-- 	playdate.graphics.setClipRect(x, y, w, h)
-- 	sprite.render:draw(0, 0)
-- 	playdate.graphics.clearClipRect()
-- end

local _widget_max = 2
local _widget_width = 125
local _widgets = table.create(_widget_max)
local _widget_index = 1
for i = 1, _widget_max do
	local render = playdate.graphics.image.new(_widget_width, 50)

	local sprite = playdate.graphics.sprite.new()
	sprite:setCenter(0,0)
	sprite:add()
	sprite:setZIndex(layer.game_ui)
	sprite:setImage(render)
--	sprite.draw = draw_widget
--	sprite.render = render

	local new_widget = {
		render = render,
		sprite = sprite,
		height = 0,

		dirty = true,
		arguments = table.create(4)
	}

	_widgets[i] = new_widget
end

function game_ui.reset()
	for index, widget in pairs(_widgets) do
		widget.force = true
		widget.sprite:setVisible(false)
		table.reset(widget.arguments)
	end
end

function game_ui.new_widget()
	_widget_index = _widget_index + 1
	if ( _widget_index > _widget_max ) then
		print( "game_ui: maximum widget number reached." )
		print( where() )

		_widget_index = _widget_max
	end

	local result = _widgets[_widget_index]
	result.sprite:setVisible(true)
	result.sprite:moveTo(game_ui.x, game_ui.y)

	return result
end

function game_ui.start_render( widget, a1, a2, a3, a4 )
	local args = widget.arguments
	local need_render = widget.dirty or a1~=args[1] or a2~=args[2] or a3~=args[3] or a4~=args[4]

	-- update arguments
	widget.dirty = false
	args[1] = a1
	args[2] = a2
	args[3] = a3
	args[4] = a4

	if need_render then
		playdate.graphics.lockFocus(widget.render)
		playdate.graphics.clear(playdate.graphics.kColorClear)
	else
		game_ui.y = game_ui.y + widget.height + game_ui.between_space
	end

	return need_render
end

function game_ui.end_render( widget, height )
	playdate.graphics.unlockFocus()
	widget.sprite:markDirty()
	widget.height = height
	--	widget.sprite:setSize( _widget_width, height )

	game_ui.y = game_ui.y + height + game_ui.between_space
end

function game_ui.start_frame( left_margin, top_margin )
	game_ui.x = left_margin or game_ui.left_margin
	game_ui.y = top_margin or game_ui.top_margin

	_widget_index = 0
end

function game_ui.draw()
	game_ui.start_frame()

	if game.mode=="normal" then
		game_ui.draw_normalmode_score()
		game_ui.draw_highscore( game.normalmode.highscore )
	end

	if game.mode=="story" then
		story.draw_ui()
	end

	if game.mode=="bomb" then
		game_ui.draw_score()
	end

	if game.mode=="timeattack" then
		game_ui.draw_timeattack_timer()
		game_ui.draw_score()
	end

	if game.mode=="relax" then
		game_ui.draw_relax()
	end

	if game.mode=="secret" then
		game_ui.draw_score()
		game_ui.draw_shipment_count( game.secret.shipment_count, 10 )
	end
end

function game_ui.draw_bar( y, value, max_value, extra_value )
	extra_value = extra_value or 0
	max_value = max_value or 1

	local scorebar_x = 6
	local scorebar_y = y
	local scorebar_w = 114
	local scorebar_h = 10
	local progress = math.clamp( value / max_value, 0, 1)


	-- outline
	playdate.graphics.setColor(black)
	playdate.graphics.drawRect(scorebar_x, scorebar_y, scorebar_w, scorebar_h)

	-- extra value with dithering
	if extra_value>0 then
		local progress_extra = math.clamp( (value+extra_value) / max_value, 0, 1)

		playdate.graphics.setDitherPattern(0.74)
		playdate.graphics.fillRect(scorebar_x+1, scorebar_y+1, (scorebar_w-2)*progress_extra, scorebar_h-2)
		playdate.graphics.setColor(black)
	end

	playdate.graphics.fillRect(scorebar_x+1, scorebar_y+1, (scorebar_w-2)*progress, scorebar_h-2)
end

function game_ui.draw_box( label, value, max_value, extra_value )
	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, label, value, max_value, extra_value )==false then
		return
	end

	local show_bar = value and max_value and max_value>0

	local margin = 3
	local x, y, w, h = 0, 0, _widget_width, margin
	if label then h = h + playdate.graphics.getFont():getHeight() + margin end
	if show_bar then h = h + 10 + margin end

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)

	if label then
		playdate.graphics.drawTextAligned( label, 6, y + margin, kTextAlignment.left)
		y = y + playdate.graphics.getFont():getHeight() + margin
	end

	if show_bar then
		game_ui.draw_bar( y, value, max_value, extra_value )
	end

	game_ui.end_render( widget, h )
end

function game_ui.draw_label_and_bar( label, value, max_value, extra_value )
	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, label, value, max_value, extra_value )==false then
		return
	end

	local label_w, label_h = playdate.graphics.getTextSize( label, fonts["label"] )
	local bar_h = 10
	
	local margin = 3
	local x, y, w, h = 0, 0, _widget_width, label_h + bar_h + 5

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)
	y = y + 2

	-- label
	set_font("label")
	playdate.graphics.drawTextAligned( label, 6, y, kTextAlignment.left)
	y = y + label_h - 2

	game_ui.draw_bar( y, value, max_value, extra_value )

	game_ui.end_render( widget, h)
end

function game_ui.draw_label_and_text( label, score, score_font )
	score_font = score_font or "score"

	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, label, score, score_font )==false then
		return
	end

	local label_w, label_h = playdate.graphics.getTextSize( label, fonts["label"] )
	local score_w, score_h = playdate.graphics.getTextSize( score, fonts[score_font] )

	local x, y, w, h = 0, 0, _widget_width, label_h + score_h + 3

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)
	y = y + 2

	-- label
	set_font("label")
	playdate.graphics.drawTextAligned( label, 6, y, kTextAlignment.left)
	y = y + label_h

	-- score
	set_font(score_font)
	playdate.graphics.drawTextAligned( score, 6, y, kTextAlignment.left)

	default_font()
	game_ui.end_render( widget, h )
end

function game_ui.draw_order_sheet( label, tiletype, count, max_count )

	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, label, tiletype, count, max_count )==false then
		return
	end

	local x, y, w, h = 0, 0, _widget_width, game.tile_size + 6

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)
	y = y + 3

	-- label
	set_font("label")
	playdate.graphics.drawTextAligned( label, 6, y, kTextAlignment.left)

	-- tile
	tile_images[tiletype]:draw(x+w-50, y)

	-- bar
	if count~=nil then
		local bar_w = 68
		local bar_h = 10
		local bar_x = 6
		local bar_y = y + 44 - bar_h - 2
		local progress = math.clamp( count / max_count, 0, 1)

		playdate.graphics.setColor(black)
		playdate.graphics.drawRect(bar_x, bar_y, bar_w, bar_h)
		playdate.graphics.fillRect(bar_x+1, bar_y+1, (bar_w-2)*progress, bar_h-2)
	end

	default_font()
	game_ui.end_render( widget, h )
end

function game_ui.draw_shipment_count( count, max_count )

	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, count, max_count )==false then
		return
	end

	local label = loc("ui_shipments")
	local label_w, label_h = playdate.graphics.getTextSize( label, fonts["label"] )

	local count_per_line = 5
	local line_count = math.ceil(max_count / count_per_line)

	local margin = 3
	local x, y, w, h = 0, 0, _widget_width, label_h + 12*line_count + 5

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)
	y = y + 2

	-- label
	set_font("label")
	playdate.graphics.drawTextAligned( label, 6, y, kTextAlignment.left)
	default_font()
	y = y + label_h - 2

	local iw, ih = images.dot_on:getSize()
	local ispace = 3
	local left = math.floor((w-((iw+ispace)*min(max_count,count_per_line)-ispace))/2)

	-- progress
	for i=1, max_count do
		local line = math.floor((i-1)/count_per_line)
		local index_x = i - line*count_per_line - 1

		local ix = left + index_x*(iw+ispace)
		local iy = y + line*12

		if i<=count then
			images.dot_off:draw( ix, iy)
		else
			images.dot_on:draw( ix, iy)
		end

		ix = ix + iw + ispace
	end

	game_ui.end_render( widget, h)
end






function game_ui.draw_score()
	local text_score = '$ '..math.floor(game.score)
	local potential_score = score.get_potential_score()
	if potential_score>0 then
		text_score = text_score..' _+'..potential_score..'_'
	end

	local bonus = 0
	if game.score_goal then
		if game.mode=="story" and story_level and game.challenge_progress<1 then
			bonus = story_level.challenge_reward
		end
	end

	set_font("score")
	game_ui.draw_box( text_score, game.score, game.score_goal, bonus )
	default_font()
end

function game_ui.draw_normalmode_score()

	local current_score = math.floor(game.score)
	local potential_score = score.get_potential_score()
	local penalty_multiplier = score.get_penalty_multiplier()

	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, current_score, potential_score, penalty_multiplier )==false then
		return
	end

	-- create score
	local text_score = '$ '..current_score
	if potential_score>0 then
		text_score = text_score..' _+'..potential_score..'_'
	end

	-- create state
	local text_state = loc("ui_penatly").." x"..penalty_multiplier

	local score_w, score_h = playdate.graphics.getTextSize( text_score, fonts["score"] )
	local state_w, state_h = playdate.graphics.getTextSize( text_state, fonts["label"] )

	local margin = 5
	local x, y, w, h = 0, 0, _widget_width, score_h + state_h + 2*margin - 5

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)
	y = y + margin

	-- score
	set_font("score")
	playdate.graphics.drawTextAligned( text_score, 6, y, kTextAlignment.left)
	y = y + score_h

	-- status
	set_font("label")
	playdate.graphics.drawTextAligned( text_state,6, y, kTextAlignment.left)

	default_font()
	game_ui.end_render( widget, h )
end

function game_ui.draw_highscore( highscore, label )

	highscore = math.floor(highscore)
	label = label or loc("ui_highscore")

	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, label, highscore )==false then
		return
	end

	local score = '$ '..highscore

	local label_w, label_h = playdate.graphics.getTextSize( label, fonts["label"] )
	local score_w, score_h = playdate.graphics.getTextSize( score, fonts["score"] )

	local margin = 3
	local x, y, w, h = 0, 0, _widget_width, label_h + score_h + 2*margin

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)
	y = y + margin

	-- label
	set_font("label")
	playdate.graphics.drawTextAligned( label, 6, y, kTextAlignment.left)
	y = y + label_h

	-- score
	set_font("score")
	playdate.graphics.drawTextAligned( score, 6, y, kTextAlignment.left)

	default_font()
	game_ui.end_render( widget, h)
end

function game_ui.draw_challenge()
	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, game.challenge_progress, game.challenge_progress_extra, game.challenge_reward_given )==false then
		return
	end

	local label = loc("ui_challenge")
	local label_w, label_h = playdate.graphics.getTextSize( label, fonts["label"] )
	local bar_h = 10
	
	local margin = 3
	local x, y, w, h = 0, 0, _widget_width, label_h + bar_h + 5

	-- now we draw the background box
	game.score_frame:drawInRect(x, y, w, h)
	y = y + 2

	-- label
	set_font("label")
	playdate.graphics.drawTextAligned( label, 6, y, kTextAlignment.left)
	default_font()

	y = y + label_h - 2
	game_ui.draw_bar( y, game.challenge_progress, 1, game.challenge_progress_extra )

	if game.challenge_reward_given then
		images["challenge_checkmark"]:draw(104, y - 17)
	end

	game_ui.end_render( widget, h)
end

function game_ui.draw_timeattack_timer( time )
	local time = math.ceil(time or game.timeattack.time)
	local minutes = math.floor(time/60)
	local seconds = time - minutes*60
	local blink_visible = time > 5 or blink(10, 3)

	local widget = game_ui.new_widget()
	if game_ui.start_render( widget, minutes, seconds, blink_visible )==false then
		return
	end

	-- create the string
	local timer = minutes..":"
	if seconds<10 then
		timer = timer.."0"
	end
	timer = timer..seconds

	set_font("large")
	local tw, th = playdate.graphics.getTextSize( timer )

	local vertical_margin = 8
	local x, y, w, h = 0, 0, _widget_width, th + 10
	game.score_frame:drawInRect(x, y, w, h)

	if blink_visible then
		playdate.graphics.drawText( timer, 6, y + vertical_margin)
	end

	default_font()
	game_ui.end_render( widget, h )
end

function game_ui.draw_relax( time )
	-- check if we have enough results
	local results = game.relax.previous_results
	local missing_result = game.relax.result_size - #results
	local total = 0
	if missing_result==0 then
		for i, score in pairs(results) do
			total = total + score
		end
	end

	if missing_result>0 then
		game_ui.draw_label_and_bar( loc("ui_relax_total"), #results, game.relax.result_size, 1 )
	else
		game_ui.draw_label_and_text( loc("ui_relax_total"), get_relax_average( total ) )
	end

	-- current count
	game_ui.draw_label_and_text( loc("ui_relax_score"), game.matched_count )
end

