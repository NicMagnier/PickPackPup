story = {
	fail_count = 0,
}

-- private members
local _launch_intro = false
local _launch_comic = false

local _next_level_index = nil
local _reset_level = false

story_level = nil

-- all data that are use by stories
story_state = {
	box_created = 0,
	box_shipped = 0,
	box_trashed = 0,
	time = 0,
	count = 0,
	state = nil,
	background_image = playdate.graphics.image.new(400,240),
}

-- init called from mode.lua
function story.init( level )
	story.fail_count = 0
	_next_level_index = nil
	_reset_level = false
	story.setLevel( level or game.unlocked_story_index or 1 )
end

function story.reset_level()
	story.fail_count = story.fail_count + 1
	_reset_level = true
end

-- update called from mode.lua
-- mainly dispatch to other modes
function story.update()
	if _next_level_index~=nil then
		story.setLevel( _next_level_index )
		_next_level_index = nil
	end

	if _reset_level then
		story.setLevel( game.story_index )
		_launch_intro = false
		_launch_comic = false
		_reset_level = false
	end

	-- first we play the comic
	if _launch_comic then
		comic_reader.view_comic( story_level.comic, true )
		_launch_comic = false
		return
	end

	-- when the comic is finished we return to story.update()
	-- new we can play the intro
	if _launch_intro then
		mode.push( story_level_intro )
		_launch_intro = false
		return
	end

	-- and now the game
	mode.push( game, "story" )
end

-- init called when a new game is created
function story.game_init()
	score.reset()
	score.set_goal( story_level.score_goal )
	clock.reset()

	call(story_level.init)
end

function story.level_done()
	_next_level_index = game.story_index + 1
	game.story_index = _next_level_index
	game.unlocked_story_index = min( max( game.unlocked_story_index, _next_level_index ), #story_levels )
	story.fail_count = 0

	game.quit()
	mode.push( promotion )
end

function story.level_failed()
	_next_level_index = game.story_index
	story.fail_count = story.fail_count + 1

	game.quit()
	mode.push( story_fail )
end


-- update called from game.lua
function story.game_update( dt )
	-- check if we get promoted
	if story_level.score_goal and game.score>=story_level.score_goal then
		story.level_done()
	end

	-- update the current story
	call( story_level.update, dt )

	-- check if we need to give the reward to the player
	if game.challenge_reward_given==false and game.challenge_progress>=1 then
		score.challenge_reward( story_level.challenge_reward )
		game.challenge_reward_given = true
		sfx.play("challenge_completed")
	end
end

function story.draw_ui()
	if story_level.draw_ui then
		call( story_level.draw_ui )
		return
	end

	-- check if we need to show a score
	if story_level.score_goal then
		game_ui.draw_score()
	end

	-- 
	if story_level.challenge_reward then
		game_ui.draw_challenge()
	end
end

function story.get_level_name()
	return story_level.level
end

function story.get_memo_locakey()
	return story_level.memo_intro
end

function story.setLevel( index )
	story_level = story_levels[index]

	if not story_level then
		story_level = story_levels[1]
	end

	game.story_index = index
	game.challenge_progress = 0
	game.challenge_progress_extra = 0
	game.challenge_reward_given = false
	game.memo = story_level.memo_pause

	_launch_intro = story_level.memo_intro~=nil
	_launch_comic = story_level.comic~=nil

	pause.prepareSystem()
end
