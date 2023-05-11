point_notification = {
	penalty_frame = playdate.graphics.nineSlice.new("images/frames/penalty", 10, 5, 64-20, 32-10),
}

function point_notification.new( point_value, x, y )
	local result

	if game.show_point_notification==false then
		return
	end

	-- look for a free tile
	for i, t in ipairs(game.point_notifications) do
		if t.is_free then
			result = t
			goto found_free
		end
	end

	if result==nil then
		print("Warning point_notification.new(): no point available anymore")
		return nil
	end

	::found_free::

	local iw, ih = result.image:getSize()

	result.is_free = false
	result.sprite:add()

	local ax = x
	local ay = y

	-- pre-render image
	local text = '*'..point_value..' $*'
	local tw, th = playdate.graphics.getTextSize(point_value)
	th = 16 -- force height because getTextSize has some space below number of letters like qp
	local tx = iw/2
	local ty = (ih - th) / 2
	local border_size = 2

	playdate.graphics.lockFocus(result.image)
	playdate.graphics.clear(playdate.graphics.kColorClear)

	if point_value>0 then
		local rw = tw + 20
		local rh = th + 6
		local rx = (iw - rw)/2
		local ry = (ih - rh)/2

		playdate.graphics.setColor(white)
		playdate.graphics.fillRoundRect(rx, ry, rw, rh, 5)

		playdate.graphics.setColor(black)
		playdate.graphics.setLineWidth( border_size )
		playdate.graphics.drawRoundRect(rx, ry, rw, rh, 5)

		playdate.graphics.drawTextAligned(text, tx, ty, kTextAlignment.center)

		result.x_anim:from(ax)
		result.y_anim:from(ay):to(ay-10, 0.7, 'outBack'):sleep(0.5):start()
	else
		local rw = tw + 40
		local rh = th + 6
		local rx = (iw - rw)/2
		local ry = (ih - rh)/2

		point_notification.penalty_frame:drawInRect(rx, ry, rw, rh)
		playdate.graphics.drawTextAligned(text, tx, ty, kTextAlignment.center)

		result.x_anim:from(ax-20):to(ax, 1.0, 'outElastic'):sleep(0.5):start()
		result.y_anim:from(ay):to(ay-10, 0.7, 'outBack'):sleep(0.5):start()
	end

	playdate.graphics.unlockFocus()
end

function point_notification.free( pn )
	pn.is_free = true
	pn.sprite:remove()
end

function point_notification.reset()
	for i, e in ipairs(game.point_notifications) do
		point_notification.free( e )
	end
end

function point_notification.update( dt )
	if game.show_point_notification==false then
		return
	end

	for i, e in ipairs(game.point_notifications) do
		if e.is_free==false then
			if e.y_anim:isDone() and e.x_anim:isDone() then
				point_notification.free(e)
			else
				e.sprite:moveTo(game.board_x + e.x_anim:get(), game.board_y + e.y_anim:get())
			end
		end
	end
end

function point_notification.draw()
	if game.show_point_notification==false then
		return
	end

	for i, e in ipairs(game.point_notifications) do
		if e.is_free==false then
			e.image:draw(game.board_x + e.x_anim:get(), game.board_y + e.y_anim:get())
		end
	end
end