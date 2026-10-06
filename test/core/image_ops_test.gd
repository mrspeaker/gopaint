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


func _count(image: Image, color: Color) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y) == color:
				count += 1
	return count


func test_stamp_size_one_sets_one_pixel() -> void:
	var image := _blank_image(5)
	ImageOps.stamp(image, Vector2i(2, 2), 1, Color.RED)
	assert_int(_count(image, Color.RED)).is_equal(1)
	assert_that(image.get_pixel(2, 2)).is_equal(Color.RED)


func test_stamp_is_clipped_at_edge() -> void:
	var image := _blank_image(5)
	ImageOps.stamp(image, Vector2i(0, 0), 3, Color.RED)
	assert_int(_count(image, Color.RED)).is_equal(4)


func test_draw_line_diagonal_has_no_gaps() -> void:
	var image := _blank_image(5)
	ImageOps.draw_line(image, Vector2i(0, 0), Vector2i(4, 4), 1, Color.RED)
	assert_int(_count(image, Color.RED)).is_equal(5)
	assert_that(image.get_pixel(4, 4)).is_equal(Color.RED)


func test_draw_line_works_in_reverse() -> void:
	var image := _blank_image(5)
	ImageOps.draw_line(image, Vector2i(4, 1), Vector2i(0, 1), 1, Color.RED)
	assert_int(_count(image, Color.RED)).is_equal(5)


func test_draw_rect_outline() -> void:
	var image := _blank_image(5)
	ImageOps.draw_rect(image, Vector2i(4, 4), Vector2i(0, 0), 1, Color.RED, false)
	assert_int(_count(image, Color.RED)).is_equal(16)
	assert_that(image.get_pixel(2, 2)).is_equal(Color.WHITE)


func test_draw_rect_filled() -> void:
	var image := _blank_image(5)
	ImageOps.draw_rect(image, Vector2i(1, 1), Vector2i(3, 3), 1, Color.RED, true)
	assert_int(_count(image, Color.RED)).is_equal(9)
