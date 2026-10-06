extends GdUnitTestSuite

const History := preload("res://addons/gopaint/core/history.gd")


func _image(color: Color) -> Image:
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


func test_undo_restores_previous_image() -> void:
	var history := History.new()
	var image := _image(Color.WHITE)
	history.record(image)
	image.fill(Color.RED)
	assert_bool(history.undo(image)).is_true()
	assert_that(image.get_pixel(0, 0)).is_equal(Color.WHITE)


func test_redo_restores_undone_change() -> void:
	var history := History.new()
	var image := _image(Color.WHITE)
	history.record(image)
	image.fill(Color.RED)
	history.undo(image)
	assert_bool(history.redo(image)).is_true()
	assert_that(image.get_pixel(0, 0)).is_equal(Color.RED)


func test_record_clears_redo() -> void:
	var history := History.new()
	var image := _image(Color.WHITE)
	history.record(image)
	history.undo(image)
	history.record(image)
	assert_bool(history.can_redo()).is_false()


func test_undo_with_empty_history_does_nothing() -> void:
	var history := History.new()
	var image := _image(Color.WHITE)
	assert_bool(history.undo(image)).is_false()
	assert_that(image.get_pixel(0, 0)).is_equal(Color.WHITE)
