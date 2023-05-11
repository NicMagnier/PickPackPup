story_level_intro = {
	modename = "story_level_intro",
	no_input_cooldown = 0
}

function story_level_intro.init()
	story_level_intro.no_input_cooldown = 0.5
	memo.create( story.get_memo_locakey() )
end

function story_level_intro.update( dt )
	if story_level_intro.no_input_cooldown>0 then
		story_level_intro.no_input_cooldown = story_level_intro.no_input_cooldown - dt
	elseif input.on(buttonA) and (memo.is_last_page() or story.fail_count>0) then
		mode.back()
	end

	if input.on(buttonB) then
		mode.push_overlay( pause )
	end

	if input.on(buttonLeft) then
		memo.previous_page()
	end
	if input.on(buttonRight) then
		memo.next_page()
	end

	memo.update( dt )
end

function story_level_intro.draw()
	playdate.graphics.clear(white)

	if blink(20, 10) then
		images["dpad"]:draw(84, 104)
	else
		images["dpad_right"]:draw(84, 104)
	end
	images["buttonA"]:draw(284, 104)

	memo.draw_interactive()
end