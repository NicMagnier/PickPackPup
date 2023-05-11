save_game = {}

local _version = 3
local _is_cheating = false

local save_state = {
	first_launch_passed = false,

	story_index = 1,

	stats = {
		box_created = 0,
		box_trashed = 0,
		box_shipped = 0,
		biggest_shipment = 0,
	},

	last_mode = nil,

	highscores = {
		normal = 0,
		timeattack = 0,
		bomb = 0,
		relax = -1,
		secret = 0,
	},

	enable_custom_tileset = false,
	custom_tileset = table.create(4),

	normal_mode_score = 0,
	secret = false,

	unlocked_comics = table.create(16)
}

-- very dumb checksum
local function compute_scores_checksum()
	local checksum = 0xFA16C0
	checksum = checksum ~ ( save_state.stats.box_created << 1 )
	checksum = checksum ~ ( save_state.stats.box_trashed << 3 )
	checksum = checksum ~ ( save_state.stats.box_shipped << 6 )
	checksum = checksum ~ ( save_state.stats.biggest_shipment & 0xFE )

	checksum = checksum ~ ( save_state.highscores.normal )
	checksum = checksum ~ ( save_state.highscores.timeattack )
	checksum = checksum ~ ( save_state.highscores.bomb )
	checksum = checksum ~ ( save_state.highscores.relax )
	checksum = checksum ~ ( save_state.highscores.secret )

	checksum = checksum ~ ( save_state.normal_mode_score )

	return checksum
end

local function reset_save_scores()
	save_state.stats.box_created = 0
	save_state.stats.box_trashed = 0
	save_state.stats.box_shipped = 0
	save_state.stats.biggest_shipment = 0

	save_state.highscores.normal = 0
	save_state.highscores.timeattack = 0
	save_state.highscores.bomb = 0
	save_state.highscores.relax = -1
	save_state.highscores.secret = 0

	save_state.normal_mode_score = 0
end

local function compute_save_state()
	save_state.version = _version

	-- first launch sequence
	save_state.first_launch_passed = first_launch.passed

	-- story mode progress
	save_state.story_index = game.unlocked_story_index

	-- stats
	save_state.stats.do_not_change = "Otherwise you might lose your stats"
	save_state.stats.box_created = game.stats.box_created
	save_state.stats.box_trashed = game.stats.box_trashed
	save_state.stats.box_shipped = game.stats.box_shipped
	save_state.stats.biggest_shipment = game.stats.biggest_shipment

	-- settings
	save_state.music_volume = settings.music_volume
	save_state.sound_volume = settings.sound_volume

	-- menu
	save_state.last_mode = menu.save_last_mode()

	-- highscores
	save_state.highscores.do_not_change = "Otherwise you might lose your scores"
	save_state.highscores.normal = game.normalmode.highscore
	save_state.highscores.timeattack = game.timeattack.highscore
	save_state.highscores.bomb = game.bomb.highscore
	save_state.highscores.relax = game.relax.highscore
	save_state.highscores.secret = game.secret.highscore

	-- custom tileset
	save_state.enable_custom_tileset = custom_tileset.enable
	for i=1, 4 do
		save_state.custom_tileset[i] = custom_tileset.list[i]
	end

	-- normal mode progress
	save_state.normal_mode_score = game.normalmode.safe_score

	-- secret mode
	save_state.secret = game.secret.enable	

	-- comics
	comic_menu.save_unlock_list( save_state.unlocked_comics )

	if _is_cheating == false then
		save_state.scores = compute_scores_checksum()
	end
end

local function apply_save_state()
	if type(save_state)~="table" then
		save_state = {}
	end

	local array_count, hash_count = table.getsize(save_state)
	local is_new_save = (hash_count<=1)

	-- first launch sequence
	first_launch.passed = save_state.first_launch_passed or false

	-- story mode progress
	game.unlocked_story_index = math.clamp(save_state.story_index or 1, 1, #story_levels)

	-- stats
	save_state.stats = save_state.stats or {}
	game.stats.box_created = save_state.stats.box_created or 0
	game.stats.box_trashed = save_state.stats.box_trashed or 0
	game.stats.box_shipped = save_state.stats.box_shipped or 0
	game.stats.biggest_shipment = save_state.stats.biggest_shipment or 0

	-- settings
	settings.music_volume = math.clamp( save_state.music_volume or 0.6, 0, 1)
	settings.sound_volume = math.clamp( save_state.sound_volume or 1.0, 0, 1)
	music.volume( settings.music_volume )

	-- menu
	menu.load_last_mode(save_state.last_mode)

	-- highscores
	save_state.highscores = save_state.highscores or {}
	game.normalmode.highscore = save_state.highscores.normal or 0
	game.timeattack.highscore = save_state.highscores.timeattack or 0
	game.bomb.highscore = save_state.highscores.bomb or 0
	game.relax.highscore = save_state.highscores.relax or -1
	game.secret.highscore = save_state.highscores.secret or 0

	-- custom tileset
	custom_tileset.enable = save_state.enable_custom_tileset or false
	save_state.custom_tileset = save_state.custom_tileset or {}
	for i=1, 4 do
		custom_tileset.list[i] = save_state.custom_tileset[i]
	end
	custom_tileset_cleanup()

	-- normal mode progress
	game.normalmode.safe_score = save_state.normal_mode_score or 0

	-- secret mode
	game.secret.enable = save_state.secret or false

	-- comics
	if not save_state.unlocked_comics then
		save_state.unlocked_comics = table.create(16)
	end
	comic_menu.load_unlock_list( save_state.unlocked_comics )

	_is_cheating = false
	if is_new_save==false then
		if save_state.scores~=compute_scores_checksum() then
			print("Bad Save Checksum")
			_is_cheating = true
		end
	end
end

function save_game.save()
	-- save game progress
	compute_save_state()
	playdate.datastore.write(save_state, "game_progress")
end

function save_game.load()
	-- load game progress
	save_state = playdate.datastore.read("game_progress") or {}

	if save_state.version==3 then
		apply_save_state()
	else
		save_game.reset()
	end
end

function save_game.print()
	printT(save_state)
end

function save_game.reset()
	comic_menu.reset_unlock_list( save_array )
	save_state = {}
	apply_save_state()
	save_game.save()
end

function save_game.is_cheating()
	return _is_cheating
end



