highscore = {}

-- private members
local _background = playdate.graphics.image.new("images/highscore_background")

function highscore.init()
end

function highscore.update(dt)
	if input.on(buttonB) or input.on(buttonA) then
		mode.back()
	end
end

function highscore.draw()
	_background:draw(0,0)

	local label_x = 225
	local score_x = 240

	local y = 40
	local y_big_step = 30
	local y_small_step = 23

	local score_normal = "$ "..math.floor(game.normalmode.highscore)
	local score_relax
	if game.relax.highscore==-1 then
		score_relax = "- No score yet -"
	else
		score_relax = get_relax_average( game.relax.highscore ) .." / "..(game.board_width*game.board_height)
	end
	local score_bomb = "$ "..math.floor(game.bomb.highscore)
	local score_timeattack = "$ "..math.floor(game.timeattack.highscore)
	local score_secret = "$ "..math.floor(game.secret.highscore)

	local stat_box_shipped = game.stats.box_shipped
	local stat_biggest_shipment = "$ "..game.stats.biggest_shipment

	if save_game.is_cheating() then
		score_normal = "???"
		score_relax = "???"
		score_bomb = "???"
		score_timeattack = "???"
		score_secret = "???"

		stat_box_shipped = "???"
		stat_biggest_shipment = "???"
	end

	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)

	-- Story Mode
	set_font( "default", playdate.graphics.font.kVariantBold )
	playdate.graphics.drawTextAligned( loc("ModeStory") , label_x, y, kTextAlignment.right)
	set_font( "default", playdate.graphics.font.kVariantNormal )
	playdate.graphics.drawTextAligned( "Level "..game.unlocked_story_index.." / "..#story_levels , score_x, y, kTextAlignment.left)
	y = y + y_small_step

	-- Infinity Mode
	set_font( "default", playdate.graphics.font.kVariantBold )
	playdate.graphics.drawTextAligned( loc("ModePlay") , label_x, y, kTextAlignment.right)
	set_font( "default", playdate.graphics.font.kVariantNormal )
	playdate.graphics.drawTextAligned( score_normal, score_x, y, kTextAlignment.left)
	y = y + y_small_step

	-- Relax Mode
	set_font( "default", playdate.graphics.font.kVariantBold )
	playdate.graphics.drawTextAligned( loc("ModeRelax") , label_x, y, kTextAlignment.right)
	set_font( "default", playdate.graphics.font.kVariantNormal )
	playdate.graphics.drawTextAligned( score_relax, score_x, y, kTextAlignment.left)
	y = y + y_small_step

	-- Danger Mode
	set_font( "default", playdate.graphics.font.kVariantBold )
	playdate.graphics.drawTextAligned( loc("ModeBomb") , label_x, y, kTextAlignment.right)
	set_font( "default", playdate.graphics.font.kVariantNormal )
	playdate.graphics.drawTextAligned( score_bomb, score_x, y, kTextAlignment.left)
	y = y + y_small_step

	-- Time Attack Mode
	set_font( "default", playdate.graphics.font.kVariantBold )
	playdate.graphics.drawTextAligned( loc("ModeTimeAttack") , label_x, y, kTextAlignment.right)
	set_font( "default", playdate.graphics.font.kVariantNormal )
	playdate.graphics.drawTextAligned( score_timeattack, score_x, y, kTextAlignment.left)

	if game.secret.enable then
		y = y + y_small_step

		-- Secret Mode
		set_font( "default", playdate.graphics.font.kVariantBold )
		playdate.graphics.drawTextAligned( loc("ModeSecret") , label_x, y, kTextAlignment.right)
		set_font( "default", playdate.graphics.font.kVariantNormal )
		playdate.graphics.drawTextAligned( score_secret, score_x, y, kTextAlignment.left)
		y = y + y_big_step

	else
		y = y + y_big_step
	end

	-- Stats
	set_font( "default", playdate.graphics.font.kVariantBold )
	playdate.graphics.drawTextAligned( loc("ui_total_shipped") , label_x, y, kTextAlignment.right)
	set_font( "default", playdate.graphics.font.kVariantNormal )
	playdate.graphics.drawTextAligned( stat_box_shipped, score_x, y, kTextAlignment.left)
	y = y + y_small_step

	set_font( "default", playdate.graphics.font.kVariantBold )
	playdate.graphics.drawTextAligned( loc("ui_biggest_shipment") , label_x, y, kTextAlignment.right)
	set_font( "default", playdate.graphics.font.kVariantNormal )
	playdate.graphics.drawTextAligned( stat_biggest_shipment, score_x, y, kTextAlignment.left)
	y = y + y_small_step

	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)

	if blink(40, 10) then
		images.buttonA:draw( 360, 200)
	end

end