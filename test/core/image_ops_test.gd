extends GdUnitTestSuite

const ImageOps := preload("res://addons/gopaint/core/image_ops.gd")


func _blank_image(size: int) -> Image:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return image


func test_flood_fill_fills_empty_image() -> void:
	var image := _blank_image(4)
	ImageOps.flood_fill(image, Vector2i(0, 0), Color.RED)
	assert_that(image.get_pixel(3, 3)).is_equal(Color.RED)


func test_flood_fill_stops_at_border() -> void:
	var image := _blank_image(5)
	for y in 5:
		image.set_pixel(2, y, Color.BLACK)
	ImageOps.flood_fill(image, Vector2i(0, 0), Color.RED)
	assert_that(image.get_pixel(1, 4)).is_equal(Color.RED)
	assert_that(image.get_pixel(2, 0)).is_equal(Color.BLACK)
	assert_that(image.get_pixel(4, 4)).is_equal(Color.WHITE)


func test_flood_fill_ignores_point_outside_image() -> void:
	var image := _blank_image(2)
	ImageOps.flood_fill(image, Vector2i(5, 5), Color.RED)
	assert_that(image.get_pixel(0, 0)).is_equal(Color.WHITE)
