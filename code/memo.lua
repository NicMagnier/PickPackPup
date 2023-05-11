memo = {}

-- private members
local _background_image = playdate.graphics.image.new( "images/memo_background" )
local _page_image = playdate.graphics.image.new( "images/memo_page" )
local _first_image = playdate.graphics.image.new( "images/memo_page_first" )
local _last_image = playdate.graphics.image.new( "images/memo_page_last" )
local _max_page = 10
local _pages = table.create(_max_page,0)
local _page_count = 0
local _page_current = 1
local _page_turn_direction = nil

-- preallocate page render targets
for i=1, _max_page do
	_pages[i] = {
		render = playdate.graphics.image.new( 200, 240 ),
		anim = sequence.new()
	}
end

function memo.debug()
	print("_page_count", _page_count)
	print("_page_current", _page_current)
end

function memo.update( dt )
end


function memo.drawBackground( x, y)
	_background_image:draw(x,y)
end

function memo.drawPage( page_index, x, y)
	page_index = page_index or 1

	if _page_count<page_index then
		return
	end

	x = x or 0
	y = y or 0

	_pages[page_index].render:draw(x, y)
end

function memo.create( locakey_table )
	local gfx = playdate.graphics

	if #locakey_table > _max_page then
		print("Warning, too many pages sent to memo.create()")
		print(where())
	end

	-- empty page
	if locakey_table==nil then
		print("Warning, no page content sent to memo.create()")
		print(where())

		_page_count = 1
		local page = _pages[index]

		gfx.lockFocus( page.render )
		_page_image:draw( 0, 0)
		gfx.drawTextInRect( "Empty page", x, y, w, h )
		gfx.unlockFocus()
		default_font()

		return
	end

	set_font( "memo" )
	_page_count = 0

	for index, locakey in pairs(locakey_table) do
		local page = _pages[index]
		page.anim:from(200)

		gfx.lockFocus( page.render )

		local x, y, w, h = 25, 30, 152, 200

		if index==1 then
			_first_image:draw( 0, 0)
			y = 46
			h = 180
		elseif index==#locakey_table then
			_last_image:draw( 0, 0)
		else
			_page_image:draw( 0, 0)
		end

		gfx.drawTextInRect( loc(locakey), x, y, w, h )

		_page_count = _page_count + 1
	end

	gfx.unlockFocus()
	default_font()

	_page_current = 1
end

function memo.next_page()
	if _page_current>=_page_count+1 then
		return
	end

	local page = _pages[_page_current]
	page.anim:from(200):to(0, 0.3, "outCirc"):start()

	_page_current = min( _max_page, _page_current + 1)

	sfx.play("page_turn_next")
	_page_turn_direction = "next"
end

function memo.previous_page()
	if _page_current<=1 then
		return
	end

	_page_current = _page_current - 1

	local page = _pages[_page_current]
	page.anim:from(0):to(200, 0.3, "outCirc"):start()

	sfx.play("page_turn_prev")
	_page_turn_direction = "prev"
end

function memo.draw_interactive()
	x1 = 0
	x2 = 200

	-- check which page is on top of the left stack
	local page_stack_left = nil
	for i=1, _page_current-1 do
		local page = _pages[i]
		if page.anim:isDone() then
			page_stack_left = i
		else
			break
		end
	end

	-- check which page is on top of the right stack
	local page_stack_right = nil
	for i=_page_current, _page_count do
		local page = _pages[i]
		if page.anim:isDone() then
			page_stack_right = i
			break
		end
	end

	-- draw left stack
	if page_stack_left~=nil then
		if page_stack_left>1 then
			memo.drawBackground( 0, 0)
		end
		memo.drawPage(page_stack_left, 0, 0)
	end

	-- draw right stack
	if page_stack_right~=nil then
		if page_stack_right<_page_count then
			memo.drawBackground( 200, 0)
		end
		memo.drawPage(page_stack_right, 200, 0)
	end

	-- draw moving pages

	local first_moving_page = 1
	if page_stack_left then
		first_moving_page = page_stack_left + 1
	end

	local last_moving_page = _page_count
	if page_stack_right then
		last_moving_page = page_stack_right - 1
	end

	if _page_turn_direction == "next" then
		for i=first_moving_page, last_moving_page do
			memo.drawPage(i, _pages[i].anim:get(), 0 )
		end
	else
		for i=last_moving_page, first_moving_page, -1 do
			memo.drawPage(i, _pages[i].anim:get(), 0 )
		end
	end
end

function memo.is_last_page()
	return _page_current>=_page_count
end
