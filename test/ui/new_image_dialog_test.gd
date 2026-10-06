extends GdUnitTestSuite

const NewImageDialog := preload("res://addons/gopaint/ui/new_image_dialog.gd")


func test_default_size_is_64() -> void:
	var dialog: NewImageDialog = auto_free(NewImageDialog.new())
	assert_that(dialog.get_image_size()).is_equal(Vector2i(64, 64))


func test_file_selected_requests_png_with_size() -> void:
	var dialog: NewImageDialog = auto_free(NewImageDialog.new())
	dialog._width.value = 32
	dialog._height.value = 16
	var requests := []
	dialog.image_requested.connect(func(path: String, size: Vector2i) -> void:
		requests.append([path, size]))
	dialog.file_selected.emit("res://art/hero")
	assert_array(requests).is_equal([["res://art/hero.png", Vector2i(32, 16)]])
