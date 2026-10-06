extends GdUnitTestSuite

const MainScreen := preload("res://addons/gopaint/ui/main_screen.gd")
const PATH := "user://gopaint_test/new_image.png"


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())


func after_test() -> void:
	DirAccess.remove_absolute(PATH)


func test_create_image_saves_blank_png() -> void:
	var screen: MainScreen = auto_free(MainScreen.new())
	var saved := []
	screen.saved.connect(saved.append)
	screen.create_image(PATH, Vector2i(20, 10))

	var image := Image.load_from_file(PATH)
	assert_that(image.get_size()).is_equal(Vector2i(20, 10))
	assert_float(image.get_pixel(5, 5).a).is_equal(0.0)
	assert_array(saved).is_equal([PATH])
	assert_that(screen._path).is_equal(PATH)
