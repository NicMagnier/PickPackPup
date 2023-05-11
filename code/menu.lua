menu = {
	modename = "menu",
}

-- private members
local _last_mode = 1
local _secret_background = playdate.graphics.image.new( "images/menu/secret_background" )
local _background = playdate.graphics.image.new( "images/menu/background" )

local _pick = playdate.graphics.image.new( "images/menu/pick" )
local _pack = playdate.graphics.image.new( "images/menu/pack" )
local _pup = playdate.graphics.image.new( "images/menu/pup" )

local _pick_outline = playdate.graphics.image.new( "images/menu/pick_outline" )
local _pack_outline = playdate.graphics.image.new( "images/menu/pack_outline" )
local _pup_outline = playdate.graphics.image.new( "images/menu/pup_outline" )

local _pick_anim_x = sequence.new():from(150):sleep(0.4):to(50, 0.3, "outCirc"):to(0, 0.5, "outExpo")
local _pick_anim_y = sequence.new():from(-240):sleep(0.4):to(0, 0.3, "inQuad"):to(-30, 0.2, "outBack"):to(0, 0.5, "outBounce")

local _pack_anim_x = sequence.new():from(150):sleep(0.2):to(50, 0.3, "outCirc"):to(0, 0.2, "outExpo")
local _pack_anim_y = sequence.new():from(-240):sleep(0.2):to(0, 0.3, "inQuad"):to(-30, 0.2, "outBack"):to(0, 0.5, "outBounce")

local _pup_anim_x = sequence.new()
local _pup_anim_y = sequence.new():from(-240):to(0, 0.5, "outBack")

local _scroll_offset = 0
local _scroll_anim = sequence.new()

local _pick_sfx_triggered = false
local _pack_sfx_triggered = false
local _pup_sfx_triggered = false

local _safe_on = false
local _safe_combination = { 30, 12, 16, -10, 45 }
local _safe_combination_index = 1
local _safe_tick = 0
local _safe_fail = false

local _selected_level

function safe_init()
	_safe_on = false
	_safe_combination_index = 1
	_safe_number = 0
	_safe_tick = 0
	_safe_fail = false
end

function safe_update()
	if game.secret.enable then
		return
	end

	if input.off(buttonLeft) then
		if _safe_on then
			sfx.play("safe_off")
		end

		safe_init()
		return
	end

	if input.on(buttonLeft) and playdate.isCrankDocked()==false then
		safe_init()
		sfx.play("safe_click")
	end

	if input.is(buttonLeft) and playdate.isCrankDocked()==false then
		_safe_on = true

		local delta_tick = playdate.getCrankTicks(30)
		if delta_tick~=0 then
			sfx.play("safe_tick")
		end

		local target_tick = _safe_combination[_safe_combination_index]
		if not target_tick then
			return
		end

		if delta_tick~=0 and math.sign(delta_tick)~=math.sign(target_tick-_safe_tick) then
			_safe_fail = true
		end

		if not _safe_fail then
			_safe_tick = _safe_tick + delta_tick
			if _safe_tick==target_tick then
				sfx.play("safe_click")
				_safe_combination_index = _safe_combination_index + 1
				if _safe_combination_index>#_safe_combination then
					game.secret.enable = true
					save_game.save()
					sfx.play("challenge_completed")
					_safe_on = false
					_last_mode = 7
					mode.set( menu )
				end
			end
		end
	end
end

local _menu_list = {
	{
		label = "ModeTutorial",
		margin_bottom = 10,
		onPressed = function()
			mode.push( game, "tutorial")
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModeStory",
		onPressed = function()
			mode.push( story, _selected_level )
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModePlay",
		onPressed = function()
			mode.push( game, "normal")
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModeRelax",
		onPressed = function()
			mode.push( game, "relax")
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModeBomb",
		onPressed = function()
			mode.push( game, "bomb")
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModeTimeAttack",
		onPressed = function()
			mode.push( game, "timeattack")
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModeComic",
		margin_top = 10,
		onPressed = function()
			mode.push( comic_menu )
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModeHighcore",
		onPressed = function()
			mode.push( highscore )
			_last_mode = menulist.get_current_entry_index()
		end
	},

	{
		label = "ModeSettings",
		onPressed = function()
			mode.push( settings )
			_last_mode = menulist.get_current_entry_index()
		end
	},

}

function menu.init()
	music.stop()
	pause.resetSystem()
	character.talk()
	safe_init()

	if game.secret.enable and _menu_list[7].label~="ModeSecret" then
		table.insert(_menu_list, 7, {
			label = "ModeSecret",
			onPressed = function()
				mode.push( game, "secret" )
				_last_mode = menulist.get_current_entry_index()
			end
		})
	end

	menulist.set_list( _menu_list, _last_mode )

	_scroll_offset = 0

	_pick_anim_x:restart()
	_pack_anim_x:restart()
	_pup_anim_x:restart()

	_pick_anim_y:restart()
	_pack_anim_y:restart()
	_pup_anim_y:restart()

	_pick_sfx_triggered = false
	_pack_sfx_triggered = false
	_pup_sfx_triggered = false

	_selected_level = game.unlocked_story_index
end

function menu.resume()
	menu.init()
	safe_init()
end

function menu.enable_debug_menu()
	table.insert(_menu_list, {
		label = "ModeDebug",
		onPressed = function()
			mode.push( menu_debug )
			_last_mode = menulist.get_current_entry_index()
		end
	})
end


function menu.update(dt)
	menulist.update( dt )

	local pick_time = _pick_anim_x.time
	local pack_time = _pack_anim_x.time
	local pup_time = _pup_anim_x.time

	-- play sounds
	if _pup_sfx_triggered==false and 0.2<_pup_anim_x.time then
		sfx.play("title_pup")
		_pup_sfx_triggered = true
	end

	if _pack_sfx_triggered==false and 0.55<_pack_anim_x.time then
		sfx.play("title_pack")
		_pack_sfx_triggered = true
	end

	if _pick_sfx_triggered==false and 0.75<_pick_anim_x.time then
		sfx.play("title_pick")
		_pick_sfx_triggered = true
	end

	local current_entry = menulist.get_current_entry()
	if current_entry.label=="ModeStory" then
		if input.on(buttonLeft) then _selected_level = _selected_level - 1 end
		if input.on(buttonRight) then _selected_level = _selected_level + 1 end
		_selected_level = math.clamp( _selected_level, 1, game.unlocked_story_index)

		current_entry.after_label = "Level "..tostring(_selected_level)
	end

	if input.onCrankDock() or input.on(buttonLeft) then
		_scroll_anim:from(_scroll_offset):to(0, 1.2, "outElastic"):start()
	end

	if playdate.isCrankDocked() or _safe_on then
		_scroll_offset = _scroll_anim:get()
	else
		local crank_delta = playdate.getCrankChange()
		_scroll_offset = math.clamp(_scroll_offset + crank_delta/10, -100, 100)
	end

	menulist.offset_y = _scroll_offset

	safe_update()
end

function menu.draw()
	_secret_background:draw(0,0)

	playdate.graphics.setColor(black)
	playdate.graphics.drawRect(-1,_scroll_offset-1,402,242)
	_background:draw(0,_scroll_offset)

	local logo_offset_x = 5
	local logo_offset_y = 3
	_pick_outline:draw( logo_offset_x + _pick_anim_x:get(), logo_offset_y + _scroll_offset + _pick_anim_y:get())
	_pack_outline:draw( logo_offset_x + _pack_anim_x:get(), logo_offset_y + _scroll_offset + _pack_anim_y:get())
	_pup_outline:draw( logo_offset_x + _pup_anim_x:get(), logo_offset_y + _scroll_offset + _pup_anim_y:get())

	_pick:draw( logo_offset_x + _pick_anim_x:get(), logo_offset_y + _scroll_offset + _pick_anim_y:get())
	_pack:draw( logo_offset_x + _pack_anim_x:get(), logo_offset_y + _scroll_offset + _pack_anim_y:get())
	_pup:draw( logo_offset_x + _pup_anim_x:get(), logo_offset_y + _scroll_offset + _pup_anim_y:get())

	menulist.draw( 240, 10 )

	if betamax then
		playdate.graphics.setColor(white)
		playdate.graphics.fillRect(0,215,400,25)
		playdate.graphics.setColor(black)
		playdate.graphics.drawRect(-1,215,402,26)
		playdate.graphics.drawText("V"..playdate.metadata.version.." Rev."..playdate.metadata.buildNumber.." *Betamax is running*", 5, 220)
	end

end

function menu.save_last_mode()
	return _menu_list[_last_mode].label
end

function menu.load_last_mode( last_mode_label )
	_last_mode = 2
	if not last_mode_label then
		return 
	end

	for index, entry in pairs(_menu_list) do
		if entry.label==last_mode_label then
			_last_mode = index
			return
		end
	end
end