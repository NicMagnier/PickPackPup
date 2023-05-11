background = {}

local _sprite = playdate.graphics.sprite.new()
_sprite:add()
_sprite:setZIndex(layer.background)
_sprite:setOpaque(true)
_sprite:setCenter(0, 0)

function background.set( image )
	_sprite:setImage(image)
end

function background.force_redraw()
	_sprite:markDirty()
end