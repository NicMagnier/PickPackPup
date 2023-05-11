comic_menu = { modename = "comic_menu" }

local _comic_list = table.create(0,16)
local _comic_index = 1

local _floating_image = nil
local _floating_anim_duration = 0.2
local _floating_anim_x = sequence.new()
local _floating_anim_y = sequence.new():from(0):to(-30, _floating_anim_duration)

local _comic_locked = playdate.graphics.image.new( "images/comic/comic_locked" )
local _can_open_with_crank = true

-- load preview file and comic list
-- for _, file in pairs(playdate.file.listFiles( "images/comic/" )) do
-- 	local comic_page_name = file:match('^(.-).preview.pdi')
-- 	if comic_page_name then
-- 		table.insert(_comic_list, {
-- 			name = comic_page_name,
-- 			locked = true,
-- 			preview = playdate.graphics.image.new( "images/comic/"..comic_page_name..".preview" )
-- 		})
-- 	 end
-- end

local _loading_comic_list = {
	"page01",
	"page02",
	"page03",
	"page04",
	"page05",
	"page06",
	"page07",
	"page08",
	"page09",
	"page10",
	"page11",
}
for _, comic_page_name in pairs(_loading_comic_list) do
	table.insert(_comic_list, {
		name = comic_page_name,
		locked = true,
		preview = playdate.graphics.image.new( "images/comic/"..comic_page_name..".preview" )
	})
end


function comic_menu.init()
	_comic_index = 1
	_floating_image = nil
	_can_open_with_crank = playdate.isCrankDocked()
end

function comic_menu.resume()
	_can_open_with_crank = playdate.isCrankDocked()
end

function comic_menu.update( dt )
	if input.on(buttonRight) and _comic_index<#_comic_list then
		_floating_image = comic_menu.get_current_preview()
		_floating_anim_x:from(0):to(-400, _floating_anim_duration):start()
		_floating_anim_y:restart()

		_comic_index = _comic_index + 1
		sfx.play("page_turn_next")
	end

	if input.on(buttonLeft) and _comic_index>1 then
		_floating_image = comic_menu.get_current_preview()
		_floating_anim_x:from(0):to(400, _floating_anim_duration):start()
		_floating_anim_y:restart()

		_comic_index = _comic_index - 1
		sfx.play("page_turn_prev")
	end

	if _can_open_with_crank==false then
		_can_open_with_crank = playdate.isCrankDocked()
	end

	local open_with_crank = _can_open_with_crank and playdate.isCrankDocked()==false

	if (input.on(buttonA) or open_with_crank) and _comic_list[_comic_index].locked==false then
		comic_reader.view_comic( _comic_list[_comic_index].name )
	elseif input.on(buttonB) then
		mode.back()
	end
end

function comic_menu.draw()
	local comic_entry = _comic_list[_comic_index]

	comic_menu.get_current_preview():draw(0,0)

	if _floating_image and _floating_anim_x:isDone()==false then
		playdate.graphics.setColor(black)
		playdate.graphics.setDitherPattern(0.25)

		playdate.graphics.fillRect(_floating_anim_x:get() - 20, _floating_anim_y:get(), 20, 240)
		playdate.graphics.fillRect(_floating_anim_x:get() + 400, _floating_anim_y:get(), 20, 240)

		_floating_image:draw(_floating_anim_x:get(), _floating_anim_y:get())

		playdate.graphics.setDitherPattern(0)
		playdate.graphics.drawRect(_floating_anim_x:get(), _floating_anim_y:get(), 400, 240)
	end

	-- bar
	local iw, ih = images.dot_off:getSize()
	local margin = 5
	local bar_height = ih + margin*2

	local spacing = 10
	local content_width = #_comic_list * (iw + spacing) - spacing
	local x, y = 200 - content_width/2, 240 - margin - ih

	playdate.graphics.setColor(black)
	playdate.graphics.fillRect(0,240-bar_height,400,bar_height)
	playdate.graphics.setColor(white)
	playdate.graphics.drawLine(0, 240-bar_height-1, 400, 240-bar_height-1)

	for index, comic in pairs(_comic_list) do
		if index == _comic_index then
			images.dot_on:draw(x,y)
		else
			images.dot_off:draw(x,y)
		end

		x = x + iw + spacing
	end
end

function comic_menu.get_current_preview()
	local comic_entry = _comic_list[_comic_index]

	if comic_entry.locked then
		return _comic_locked
	end
	
	return comic_entry.preview
end

function comic_menu.reset_unlock_list( )
	for index, comic in pairs(_comic_list) do
		comic.locked = true
	end
end

function comic_menu.save_unlock_list( save_array )
	table.reset(save_array)
	for index, comic in pairs(_comic_list) do
		if comic.locked==false then
			table.insert(save_array, comic.name)
		end
	end
end

function comic_menu.load_unlock_list( save_array )
	if not save_array then
		return
	end

	for index, comic_name in pairs(save_array) do
		comic_menu.unlock( comic_name )
	end
end

function comic_menu.print_unlock_list( )
	printT(_comic_list)
end


function comic_menu.unlock( name )
	for index, comic in pairs(_comic_list) do
		if comic.name==name then
			comic.locked = false
			return
		end
	end
end

function comic_menu.unlock_all()
	for index, comic in pairs(_comic_list) do
		comic.locked = false
	end
end

function comic_menu.print()
	printT(_comic_list)
end