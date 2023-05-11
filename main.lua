--import 'lieb/betamax'

import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/object'
import 'CoreLibs/nineslice'
import 'CoreLibs/ui'
import 'CoreLibs/utilities/where'
import 'CoreLibs/crank'

import 'lieb/all'
import 'code/anim_loop'

-- game code
import 'code/game_assets'
import 'code/game_objects'
import 'code/sfx'
import 'code/font'

import 'code/mode'
import "code/menu"
import "code/game"
import "code/tile"
import "code/box"
import "code/bag"
import 'code/matching'
import "code/score"
import 'code/gameover'
import 'code/promotion'
import 'code/point_notification'
import 'code/memo'
import 'code/pause'
import "code/story"
import 'code/story_level_intro'
import 'code/story_fail'
import "code/story_levels"
import 'code/character'
import 'code/clock'
import 'code/game_ui'
import 'code/tutorial'
import 'code/highscore'
import 'code/first_launch'
import 'code/custom_tileset'
import 'code/background'
import 'code/cursor'
import 'code/screenshake'
import 'code/rubbles'
import 'code/trashing_anim'

import 'code/menulist'
import 'code/comic_menu'
import 'code/comic_reader'
import 'code/music'

import 'code/save'
import 'code/settings'
import 'code/reset_progress'

import 'code/menu_debug'

import 'lieb/deltaTime'

playdate.display.setRefreshRate(30)

function is_debug_version()
	return string.find(playdate.metadata.version,"d")~=nil
end

if is_debug_version() then
	menu.enable_debug_menu()
end

local frame_count = 0
function even_frame()
	return (frame_count%2)==0
end

function frame_id()
	return frame_count
end

function bool_cycle(frame_duration)
	return (math.floor(frame_count/frame_duration)%2)==0
end

function blink(frame_on, frame_off)
	return frame_count%(frame_on+frame_off)<frame_on
end

-- load the latest save
save_game.load()

-- launch the game
if first_launch.passed then
	mode.set( menu )
else
	mode.set( first_launch )
end

function playdate.update()
	dt = getDeltaTime_Legacy()

	frame_count = frame_count + 1

	input.update(dt)
	sequence.update()

	-- main update and draw
	mode.update( dt )

	if game.show_fps then
		playdate.drawFPS(0,0)
		-- print(mode.get_metrics())
	end
end

function playdate.gameWillTerminate()
	save_game.save()
end

function playdate.deviceWillSleep()
	save_game.save()
end

function playdate.showGameOptions()
	mode.push( settings )
end

-- only on the simulator
function playdate.keyPressed(key)
	if key=="o" then
		mode.back()
	end
end


--betamax_eof(-300)
