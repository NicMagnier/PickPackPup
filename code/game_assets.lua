local loading_tilesets = {
	"tutorial",
	"default",
	"fruit",
	"book",
	"rare",
	"playdate",
	"dogs",
	"pasta",
	"danger",
	"robot",
	"tetromino",
	"space",
	"geometric",
	"cosmetics",
	"holiday",
	"secret"
}

box_img = {
	{"box_0000"},
	{"box_0001"},
	{"box_0010"},
	{"box_0011"},
	{"box_0100"},
	{"box_0101"},
	{"box_0110"},
	{"box_0111"},
	{"box_1000"},
	{"box_1001"},
	{"box_1010"},
	{"box_1011"},
	{"box_1100"},
	{"box_1101"},
	{"box_1110"},
	{"box_1111"}
}

asset.load_image("game_background")
asset.load_image("menu_background")
asset.load_image("pause_background")
asset.load_image("comic_background")

asset.load_image("cursor_ship", "images/cursors/")
asset.load_image("cursor_on", "images/cursors/")
asset.load_image("cursor_off", "images/cursors/")

asset.load_image("gameover")

asset.load_image("challenge_checkmark")
asset.load_image("clock")

asset.load_image("dpad")
asset.load_image("dpad_left")
asset.load_image("dpad_right")
asset.load_image("buttonA")
asset.load_image("buttonB")

asset.load_image("dot_on")
asset.load_image("dot_off")

asset.load_image("earth")
asset.load_image("moon")
asset.load_image("mars")
asset.load_image("spacesuit")

asset.load_image("holiday_background_1")
asset.load_image("holiday_background_2")
asset.load_image("holiday_background_3")

layer = enum({
	"background",
	"game_ui",
	"tile",
	"boxtile",
	"tile_trashed",
	"boxtile_trashed",
	"boxtile_shipped",
	"clock",
	"point_notification",
	"character",
	"cursor",
	"combo_background",
	"combo",
	"character_talk",
	"rubbles"
})

-- load all the tileset
tilesets = table.create(16)
tilesets_images = table.create(16)
tile_images = table.create(100)
for set_index, set in pairs(loading_tilesets) do
 	tilesets_images[set] = playdate.graphics.imagetable.new("images/tiles/"..set)

 	if set~="rare" then
 		tilesets[set] = table.create(16)
 		for tile_index = 1, tilesets_images[set]:getSize() do
	 		local tile_type = set..tile_index
	 		table.insert(tilesets[set], tile_type)
		 	tile_images[tile_type] = tilesets_images[set]:getImage(tile_index)
		 end
	 end
end

-- tileset rare is a special case
tilesets["rare"] = table.create(1)
tilesets["rare"] = "rare1"

-- load all the box_img images
for _, box_type in ipairs(box_img) do
	for i, img_name in ipairs(box_type) do
		asset.load_image(img_name, "images/boxes/")
	end
end

