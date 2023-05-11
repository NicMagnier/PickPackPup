menu_debug = {
	modename = "menu_debug",
	list = {},
	list_index = 1,
}

local _button_anim = sequence.new():from(-5):to(5, 0.4, "inOutSine"):mirror()

function menu_debug.register( mode )
	table.insert(menu_debug.list, mode)
end

function menu_debug.init()
	_button_anim:start()
end

function menu_debug.shutdown()
	_button_anim:stop()
end

function menu_debug.update(dt)
	if input.on(buttonDown) then
		menu_debug.list_index = math.ring_int( menu_debug.list_index + 1, 1, #menu_debug.list)
	elseif input.on(buttonUp) then
		menu_debug.list_index = math.ring_int( menu_debug.list_index - 1, 1, #menu_debug.list)
	elseif input.on(buttonA) then
		mode.push(menu_debug.list[menu_debug.list_index])
	elseif input.on(buttonB) then
		mode.back()
	end
end

function menu_debug.draw()
	playdate.graphics.clear(white)
	local y = 5
	for i, mode in pairs(menu_debug.list) do
		-- check if the mouse is there
		if i==menu_debug.list_index then
			playdate.graphics.drawText( '*'..mode.name..'*', 20 + _button_anim:get(), y)
		else
			playdate.graphics.drawText( mode.name, 20, y)
		end
		y = y + 20
	end
end

-- Select Story
menu_debug.register({
	name = "Go to story level",

	init = function()
		menu_debug.story_index = nil
	end,

	update = function(dt)
		if input.on(buttonRight) then
			menu_debug.story_index = next(story_levels, menu_debug.story_index)
		elseif input.on(buttonLeft) then
			menu_debug.story_index = menu_debug.story_index - 1
			if menu_debug.story_index<=0 then
				menu_debug.story_index = #story_levels
			end
		elseif input.on(buttonUp) then
			menu_debug.story_index = min( menu_debug.story_index + 5, #story_levels)
		elseif input.on(buttonDown) then
			menu_debug.story_index = max( menu_debug.story_index - 5, 1)
		elseif input.on(buttonA) then
			mode.push( story, menu_debug.story_index)
		elseif input.on(buttonB) then
			mode.back()
		end

		if menu_debug.story_index==nil then
			menu_debug.story_index = next(story_levels, nil)
		end

		local story_level = story_levels[menu_debug.story_index]

		playdate.graphics.clear(white)
		playdate.graphics.drawText( "Select the Level", 20, 20)

		if story_level then
			playdate.graphics.drawText( "*"..menu_debug.story_index.." - "..story_level.level.."*", 20, 40)
		else
			playdate.graphics.drawText( "*"..menu_debug.story_index.." - _no name_*", 20, 40)
		end

		playdate.graphics.drawText( "Up or Down to move by 5", 20, 80)
	end,
})

-- Unlock Comics
menu_debug.register({
	name = "Unlock all comics",

	update = function()
		comic_menu.unlock_all()
		mode.set( menu )
		mode.push( comic_menu )
	end,
})

-- Unlock Secret Mode
menu_debug.register({
	name = "Unlock Secret Mode",

	update = function()
		game.secret.enable = true
		mode.set( menu )
	end,
})

-- Reset Secret Mode
menu_debug.register({
	name = "Reset Secret Mode",

	update = function()
		game.secret.enable = false
		mode.set( menu )
	end,
})

-- Enable FPS Counter
menu_debug.register({
	name = "Toggle FPS Counter",

	update = function()
		game.show_fps = not game.show_fps
		mode.set( menu )
	end,
})


-- Character animation player
menu_debug.register({
	name = "Character Animations",

	init = function()
		if not menu_debug.anim_files then
			menu_debug.anim_files = {}

			menu_debug.anim_player = playdate.graphics.animation.loop.new()

			for _, name in pairs({"bark", "danger", "goose_honk", "goose_pull", "goose", "happy-wag", "idle"}) do
			 	table.insert(menu_debug.anim_files, {
			 		name = name,
			 		image = playdate.graphics.imagetable.new("images/characters/"..name),
			 		speed = 100
			 	})
			end
		end

		menu_debug.current_anim_file = 0
	end,

	update = function(dt)
		local previous_anim = menu_debug.anim_files[menu_debug.current_anim_file]
		if input.on(buttonDown) then
			menu_debug.current_anim_file = menu_debug.current_anim_file + 1
		elseif input.on(buttonUp) then
			menu_debug.current_anim_file = menu_debug.current_anim_file - 1
		elseif input.on(buttonB) then
			mode.back()
		end

		menu_debug.current_anim_file = math.clamp(menu_debug.current_anim_file, 1, #menu_debug.anim_files)
		local current_anim = menu_debug.anim_files[menu_debug.current_anim_file]

		if previous_anim~=current_anim then
			menu_debug.anim_player.imageTable = current_anim.image
			menu_debug.anim_player.endFrame = #current_anim.image
			menu_debug.anim_player.delay = current_anim.speed or 100
			menu_debug.anim_player.loop = true
			menu_debug.anim_player.frame = 1
		end

		if input.is(buttonRight) then
			current_anim.speed = current_anim.speed + 10
		end
		if input.is(buttonLeft) then
			current_anim.speed = math.max(current_anim.speed - 10, 10)
		end
		menu_debug.anim_player.delay = current_anim.speed

		-- render
		images["game_background"]:draw(0,0)
		local y = 5
		for _, anim in pairs(menu_debug.anim_files) do
			-- check if the mouse is there
			if anim==current_anim then
				playdate.graphics.drawText( '*'..anim.name..'* > '..anim.speed, 20 , y)
			else
				playdate.graphics.drawText( anim.name, 20, y)
			end
			y = y + 20
		end

		-- character
		local image = menu_debug.anim_player:image()
		if image then
			image:draw(270, 100)
		end
	end,
})

-- Promotion screen
menu_debug.register({
	name = "Promotion Screen",

	update = function()
		mode.push( promotion )
	end,
})

-- GameOver screen
menu_debug.register({
	name = "Game Over Screen",

	update = function()
		mode.push( gameover, 12345, 15354 )
	end,
})

-- Fail screen
menu_debug.register({
	name = "Fail Screen",

	update = function()
		mode.push( story_fail )
	end,
})

