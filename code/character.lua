character = {
	image = playdate.graphics.imagetable.new("images/characters/ingame"),
	animation = nil,

	current_animation = nil,
	animations = { "idle", "bark", "danger", "happy-wag", "goose", "goose_pull", "goose_honk" },
	images = table.create(0,8),

	player = anim_loop.new(),

	offset_x = 0,
	offset_y = 0
}

-- private members
local _enable = false

local _lock_animation = false
local _dog_sprite = playdate.graphics.sprite.new()
_dog_sprite:setCenter(1,1)
_dog_sprite:setZIndex(layer.character)

local _message = nil
local _message_anim = sequence.new():from(20):to(0, 0.5, "outBack")
local _message_timeout = -1
local _message_frame = playdate.graphics.nineSlice.new("images/frames/speech", 8, 4, 160-16, 24)

local _message_render = playdate.graphics.image.new(170, 200)
local _message_sprite = playdate.graphics.sprite.new()
_message_sprite:setZIndex(layer.character_talk)
_message_sprite:add()
_message_sprite:setCenter( 1, 0 )
function _message_sprite:draw(x,y,w,h)
	playdate.graphics.setClipRect(x, y, w, h)
	_message_render:draw(0, 0)
	playdate.graphics.clearClipRect()
end


-- load the animations
for _, anim in pairs(character.animations) do
	character.images[anim] = playdate.graphics.imagetable.new("images/characters/"..anim)
end

function character.print()
	print("_message", _message )
	print("_message_timeout", _message_timeout )
end

function character.reset()
	_lock_animation = false
	character.offset_x = 0
	character.offset_y = 0
	character.enable()
	_message_render:clear(playdate.graphics.kColorClear)
end

function character.enable()
	_enable = true
	_dog_sprite:add()
end

function character.disable()
	_enable = false
	_dog_sprite:remove()
end

function character.is_enabled()
	return _enable
end

function character.set_animation( name, delay, loop )
	if _lock_animation then
		return
	end

	delay = delay or 100
	if loop==nil then loop = true end

	local imageTable = character.images[name]
	if not imageTable then
		return
	end

	-- if we try to play the same animation, we do nothing
	if name==character.current_animation and delay==character.player.delay then
		return
	end

	character.current_animation = name
	character.player.imageTable = imageTable
	character.player.delay = delay
	character.player.loop = loop
	character.player.time = 0
end

function character.get_animation()

	return character.current_animation, character.player.delay
end

function character.lock_animation()
	_lock_animation = true
end

function character.unlock_animation()
	_lock_animation = false
end

function character.get_image()
	return character.player:image()
end

function character.update( dt )
	if not _enable then
		return
	end

	character.player:update( dt )
	if character.player:isValid()==false then
		_lock_animation = false
	end

	-- update dog
	_dog_sprite:setImage(character.player:image())
	_dog_sprite:moveTo(400+character.offset_x, 240+character.offset_y)


	-- update speech bubble
	if not _message then
		return
	end

	if _message_timeout > 0 then
		_message_timeout = max( 0, _message_timeout - dt)
	end

	if _message_timeout==0 then
		_message_timeout = -1
		_message = nil
		_message_sprite:setVisible(false)
	end

	local sw, sh = _message_sprite:getSize()
	local right = min( 395, 275+sw ) + character.offset_x
	local top = max(0, 120 + _message_anim:get() - sh) + character.offset_y
	_message_sprite:moveTo( right, top)
end

function character.draw(x,y)
	local image = character.player:image()
	local iw, ih = image:getSize()
	x = x or (400-iw)
	y = y or (240-ih)
	image:draw(x + character.offset_x, y + character.offset_y)
end

function character.is_playing()
	return character.player:isValid()
end

-- define what the character will say
function character.quicktalk( message )
	character.talk( message, 1.5 )
end

function character.talk( message, timeout )
	if message==nil then
		character.talk_string( nil, timeout )
	else
		character.talk_string( loc(message), timeout )
	end
end

function character.talk_string( message, timeout )
	if _message==message then return end

	-- set the message
	_message = message
	_message_timeout = timeout or -1
	_message_anim:restart()

	character.set_animation( "bark", 60, false )
	character.lock_animation()

	-- pre-render speech bubble
	local text_max_width = 150

	set_font("speech")

	-- text size
	local tw, th = playdate.graphics.getTextSizeForMaxWidth( _message, text_max_width )

	-- frame size
	local fw, fh = _message_frame:getMinSize()

	-- total size
	local width = tw + fw
	local height = th + fh

	-- anchor
	local right = min( 395, 275+width )
	local bottom = 120 + _message_anim:get()

	local left = right - width + character.offset_x
	local top = max(0, bottom - height) + character.offset_y
	
	playdate.graphics.lockFocus(_message_render)
		playdate.graphics.clear(playdate.graphics.kColorClear)
		_message_frame:drawInRect( 0, 0, width, height )
		playdate.graphics.drawTextInRect( _message, 5, 5, text_max_width, 240)
	playdate.graphics.unlockFocus()

	default_font()

	-- setup sprits
	_message_sprite:markDirty()
	_message_sprite:setSize( width, height )
	_message_sprite:setVisible(true)
end

function character.draw_speech()
	if not _message then return end

	local text_max_width = 150

	playdate.graphics.setFont(fonts.speech)

	-- text size
	local tw, th = playdate.graphics.getTextSizeForMaxWidth( _message, text_max_width )

	-- frame size
	local fw, fh = _message_frame:getMinSize()

	-- total size
	local width = tw + fw
	local height = th + fh

	-- anchor
	local default_left = 275
	local right = min( 395, 275+width )
	local bottom = 120 + _message_anim:get()

	local left = right - width + character.offset_x
	local top = max(0, bottom - height) + character.offset_y
	
	_message_frame:drawInRect( left, top, width, height )
	playdate.graphics.drawTextInRect( _message, left + 5, top + 5, text_max_width, 240)

	playdate.graphics.setFont(fonts.default)
end