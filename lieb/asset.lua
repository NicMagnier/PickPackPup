asset = {}
images = {}

function asset.load_image(image, folder)
	folder = folder or "images/"
	image_path = folder..image

	if not images[image] then
		images[image] = playdate.graphics.image.new( image_path ) --playdate.datastore.readImage(image, folder)
	end
end