sfx = {
	list = table.create(0,32)
}

-- read the files in the sfx folder
-- for index, file in pairs(playdate.file.listFiles( "sfx" )) do
-- 	name = file:match('^(.-).pda')
-- 	if name then
-- 		sfx.list[name] = playdate.sound.sampleplayer.new("sfx/"..name)
-- 	 end
-- end

local _load_sfx_list = {
	"boost",
	"challenge_completed",
	"clock",
	"combo",
	"counting_down",
	"counting_up",
	"trashing",
	"fail",
	"menu_move",
	"menu_select",
	"page_turn_next",
	"page_turn_prev",
	"promotion",
	"robot_explosion",
	"explosion",
	"shipping",
	"select",
	"sfx_goose_honk_02",
	"sfx_goose_honk_03",
	"sfx_goose_honk_06",
	"swap",
	"tick_002",
	"title_pack",
	"title_pick",
	"title_pup",
	"wind",
	"safe_tick",
	"safe_click",
	"safe_off",
}
for _, name in pairs(_load_sfx_list) do
	sfx.list[name] = playdate.sound.sampleplayer.new("sfx/"..name)
end

function sfx.play( name, volume )
	volume = volume or 1
	sfx.list[name]:setVolume( volume * settings.sound_volume )
	sfx.list[name]:play()
end

function sfx.playAtLeast( name, minimumLength, volume )
	local playtime = sfx.list[name]:getOffset()
	if sfx.list[name]:isPlaying() and playtime<minimumLength then
		return
	end

	sfx.play( name, volume )
end

function sfx.playAtRate( name, rate, fn, ... )
	sfx.list[name]:setVolume( settings.sound_volume )
	sfx.list[name]:setFinishCallback(fn, ...)
	sfx.list[name]:setRate(rate or 1)
	sfx.list[name]:play()
end

function sfx.setVolume( name, volume )
	volume = volume or 1
	sfx.list[name]:setVolume( volume * settings.sound_volume )
end

function sfx.getVolume(name)
	return sfx.list[name]:getVolume()
end

function sfx.get( name )
	return sfx.list[name]
end