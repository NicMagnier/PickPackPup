local _variantNormal = playdate.graphics.font.kVariantNormal
local _variantBold = playdate.graphics.font.kVariantBold
local _variantItalic = playdate.graphics.font.kVariantItalic

-- load fonts
local _pedallica = playdate.graphics.font.new("fonts/font-pedallica-fun-14")
local _bitmore = playdate.graphics.font.new("fonts/font-Bitmore")
local _asheville_large = playdate.graphics.font.new("fonts/Asheville-Rounded-24-px")
local _fishy = playdate.graphics.font.new("fonts/Fishy")
local _fishy_bold = playdate.graphics.font.new("fonts/Fishy-Bold")
local _fishy_score = playdate.graphics.font.new("fonts/FishyScoreHack")
local _cuberick = playdate.graphics.font.new("fonts/font-Cuberick-Bold")

_asheville_large:setTracking(2)
_bitmore:setTracking(1)

-- { [_variantNormal] = _font , [_variantBold] = _pedallica, [_variantItalic] = _pedallica }

fonts = {
	default = { [_variantNormal] = playdate.graphics.getSystemFont(_variantNormal) , [_variantBold] = playdate.graphics.getSystemFont(_variantBold), [_variantItalic] = playdate.graphics.getSystemFont(_variantItalic) },
	large = _asheville_large,
	small = _bitmore,
	speech = _pedallica,
	clock = _pedallica,
	score = { [_variantNormal] = playdate.graphics.getSystemFont(_variantBold) , [_variantItalic] = _bitmore },--{ [_variantNormal] = _fishy_score , [_variantItalic] = _fishy },
	memo = _cuberick,--{ [_variantNormal] = _fishy , [_variantBold] = _fishy_bold },
	label = _cuberick,
	space = _cuberick,
}

function set_font( name, variant )
	name = name or "default"

	local font_definition = fonts[name]
	if not font_definition then return end

	if type(font_definition)=="table" then
		if variant~=nil then
			playdate.graphics.setFont(font_definition[variant])
		else
			playdate.graphics.setFontFamily(font_definition)
		end
	else
		playdate.graphics.setFont(font_definition, variant)
	end
end

-- alias to make code more readable -- defaultFont()
default_font = set_font