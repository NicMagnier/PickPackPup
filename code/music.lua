music = {
	-- we have two players so that one player can play a sequence while the second one buffers the next sequence
	player = nil,
	next_player = nil,

	player_sequence = nil,
	next_player_sequence = nil,

	track = nil,
	tracks = {}
}

music.tracks["test"] = {
	path = "music/test",
	sequences = {
		{ start = 0, finish = 2.084 },
		{ start = 2.084, finish = 6.988 },
		{ start = 6.988, finish = 10.836 },
		{ start = 10.836, finish = 15.187 },
		{ start = 15.187, finish = 18 },
	}
}

function music.switch_players()
	local tmp = music.player
	music.player = music.next_player
	music.next_player = tmp

	tmp = music.player_sequence
	music.player_sequence = music.next_player_sequence
	music.next_player_sequence = tmp
end

function music.pick_next_sequence()
	local seq = table.random(music.track.sequences)
	music.next_player:setLoopRange(seq.start, seq.finish, music.sequence_callback)
	music.next_player:setOffset(seq.start)

	music.next_player_sequence = seq
end

function music.sequence_callback()
	music.player:pause()
	music.switch_players()
	music.pick_next_sequence()
	music.player:play(0)
end

function music.play( track, loop )
	local repeatCount = 0
	if loop==false then
		repeatCount = 1
	end

	if not track then
		return
	end

	music.stop()

	if not music.tracks[track] then
		 music.tracks[track] = {
		 	path = "music/"..track
		 }
	end

	music.track = music.tracks[track]

	if music.track.sequences then
		music.player = playdate.sound.fileplayer.new( music.track.path )
		music.player:setVolume(settings.music_volume)
		music.player:setStopOnUnderrun(false)

		music.next_player = playdate.sound.fileplayer.new( music.track.path )
		music.next_player:setVolume(settings.music_volume)
		music.next_player:setStopOnUnderrun(false)

		music.pick_next_sequence()
		music.switch_players()
		music.pick_next_sequence()
		music.player:play(repeatCount)
	else
		music.player = playdate.sound.fileplayer.new( music.track.path )
		music.player:setStopOnUnderrun(false)
		music.player:setVolume(settings.music_volume)
		music.player:play(repeatCount)
	end
end

function music.stop()
	if music.player then music.player:stop() end
	if music.next_player then music.next_player:stop() end
end

function music.volume( vol )
	if music.player then music.player:setVolume(vol) end
	if music.next_player then music.next_player:setVolume(vol) end
end

function music.pause()
	if music.player then music.player:pause() end
end

function music.unpause()
	if music.player then music.player:play() end
end

function music.draw_player( player, sequence, y )
	local x, y, w, h = 5, y, 390, 10
	playdate.graphics.setColor(white)
	playdate.graphics.fillRect(x, y, w, h)

	playdate.graphics.setColor(black)
	playdate.graphics.drawRect(x, y, w, h)

	local length = player:getLength()
	local sx = x + w * ( sequence.start / length )
	local sw = w * ( (sequence.finish - sequence.start) / length )

	playdate.graphics.fillRect(sx, y, sw, h)

	playdate.graphics.setColor(white)

	playdate.graphics.fillCircleAtPoint(x + w * (player:getOffset()/length), y+5, 4)
end

function music.draw_debug()
	music.draw_player( music.player, music.player_sequence, 5 )
	music.draw_player( music.next_player,  music.next_player_sequence, 20 )
end
