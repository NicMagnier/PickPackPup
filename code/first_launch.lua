first_launch = {
	passed = true,
	is_running = false,
}

-- private members
local _state = "page01"

function first_launch.init()
	first_launch.is_running = true
	_state = "page01"
end

function first_launch.update(dt)
	if _state=="page01" then
		comic_reader.view_comic( "page01", true )
		_state = "tutorial"
		return
	end

	if _state=="tutorial" then
		mode.push( game, "tutorial")
		_state = "page02"
		return
	end

	if _state=="page02" then
		comic_reader.view_comic( "page02", true )
		_state = "end"
		return
	end

	if _state=="end" then
		first_launch.finish()
	end
end

function first_launch.finish()
	first_launch.is_running = false
	first_launch.passed = true
	save_game.save()
	mode.set( menu )
end