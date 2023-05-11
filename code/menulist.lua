menulist = {
	offset_y = 0
}

local _list = nil
local _index = 1

local _cursor = playdate.graphics.image.new( "images/menu_cursor" )
local _cw, _ch = _cursor:getSize()
local _cursor_animx = sequence.new()
local _cursor_animy = sequence.new()
local _cursor_command = nil

function menulist.set_cursor( x, y )
	-- get position at the end of the target
	local from_x = _cursor_animx:get( _cursor_animx.duration )
	local from_y = _cursor_animy:get( _cursor_animy.duration )

	local diff_x = from_x-x
	local shift_x = math.sign(diff_x) * math.min(7,math.abs(diff_x))

	_cursor_animx:from(x+shift_x):to(x, 0.15, "outCirc"):start()

	local shift_y = 7
	if from_y>y then
		shift_y = -shift_y
	end

	_cursor_animy:from(y+shift_y):sleep(0.1):to(y, 0.7, "outElastic"):start()
end

function menulist.draw_cursor()
	_cursor:draw( _cursor_animx:get()-_cw/2, menulist.offset_y + _cursor_animy:get()-_ch/2)
end

function menulist.set_list( list, default_index )
	_list = list
	_index = default_index or 1
	_alignement = kTextAlignment.left

	_cursor_command = "jump"

	menulist.offset_y = 0
end

function menulist.get_current_entry()
	return _list[_index]
end

function menulist.get_current_entry_index()
	return _index
end

function menulist.update( dt )
	if not _list then return end

	local original_index = _index
	local entry = _list[_index]

	if input.on(buttonA) then
		call(entry.onPressed)
		sfx.play( "menu_select" )
	elseif input.on(buttonDown) then
		_index = _index + 1
		if _index > #_list then
			_index = 1
		end
	elseif input.on(buttonUp) then
		_index = _index - 1
		if _index < 1 then
			_index = #_list
		end
	end

	if original_index~=_index then
		local new_entry = _list[_index]
		call(entry.onUnselected)
		call(new_entry.onSelected)

		sfx.play( "menu_move" )
		if _cursor_command~="jump" then
			_cursor_command = "update"
		end
	end
end

function menulist.draw_entry( entry, is_selected, x, y, alignement )
	local margin_top = entry.margin_top or 0
	local margin_bottom = entry.margin_bottom or 0
	alignement = alignement or kTextAlignment.left

	y = y + margin_top

	-- get localized text
	local text = loc(entry.label)

	-- we put the text in bold if selected
	if is_selected then
		text = "*"..text.."*"
		if type(entry.after_label)=="string" then
			text = text.." "..entry.after_label
		end
	end

	playdate.graphics.drawTextAligned(text, x, menulist.offset_y + y, alignement)

	-- get Text size
	local tw, th = playdate.graphics.getTextSize(text)
	if is_selected and _cursor_command~=nil then
		local cx, cy = x, y

		if alignement==kTextAlignment.left then
			cx = x - _cw
		elseif alignement==kTextAlignment.center then
			cx = x - _cw - tw/2
		elseif alignement==kTextAlignment.right then
			cx = x - _cw - tw
		end

		cy = y + th/2

		if _cursor_command=="jump" then
			_cursor_animx:from(cx)
			_cursor_animy:from(cy)
			_cursor_command = nil
		elseif _cursor_command=="update" then
			menulist.set_cursor( cx, cy )
			_cursor_command = nil
		end
	end

	y = y + th + margin_bottom

	return x, y
end

function menulist.draw( x, y, alignement)
	x = x or 0
	y = y or 0

	for index, entry in pairs(_list) do
		local new_x, new_y = menulist.draw_entry( entry, index==_index, x, y, alignement )

		y = new_y
	end

	menulist.draw_cursor()
end