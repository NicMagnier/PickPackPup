cursor = {
	gx = 1,
	gy = 1
}

-- private members
local _anim = sequence.new():from(0):to(4, 0.3):mirror():start()
local _pat_anim_x = sequence.new():from(310):to(340, 300):to(310, 60):loop()
local _pat_anim_y = sequence.new():from(115):to(155, 320, "inCirc"):to(115, 40):loop()
local _can_pat = false

local _sprite = playdate.graphics.sprite.new()
_sprite:add()
_sprite:setZIndex(layer.cursor)
_sprite:setCenter(0, 0)

function cursor.enable()
	_sprite:add()
end

function cursor.disable()
	_sprite:remove()
end

function cursor.is_patting()
	return _can_pat and playdate.isCrankDocked()==false and character.is_enabled()
end

function cursor.reset()
	-- we can start patting only when the crank has been docked
	-- if at the start of a level the crank is not docked, we cannot pat
	_can_pat = playdate.isCrankDocked()
end

function cursor.update( dt )

	if input.onCrankDock() then
		_can_pat = true
	end

	if cursor.is_patting() then
		local cursor_x = _pat_anim_x:get(playdate.getCrankPosition())
		local cursor_y = _pat_anim_y:get(playdate.getCrankPosition())

		_sprite:setImage(images.cursor_off)
		_sprite:moveTo(game.board_x + cursor_x, game.board_y + cursor_y)
	else
		local cursor_tile = get_current_tile()
		local swap_dx, swap_dy = 0, 0
		if cursor_tile then
			swap_dx = cursor_tile.swap_dx
			swap_dy = cursor_tile.swap_dy
		end

		local cursor_x, cursor_y = get_tile_position(cursor.gx, cursor.gy)
		local cursor_delta = _anim:get()
		cursor_x = cursor_x + swap_dx
		cursor_y = cursor_y + swap_dy

		if game.shipping_enable and cursor_tile and cursor_tile.is_boxed then
			_sprite:setImage(images.cursor_ship)
			_sprite:moveTo(game.board_x + cursor_x + cursor_delta, game.board_y + cursor_y)

		elseif input.is(buttonA) then
			_sprite:setImage(images.cursor_on)
			_sprite:moveTo(game.board_x + cursor_x + 16, game.board_y + cursor_y + 16)

		else
			_sprite:setImage(images.cursor_off)
			_sprite:moveTo(game.board_x + cursor_x + 14 + cursor_delta, game.board_y + cursor_y + 16 - cursor_delta/2)
		end
	end
end