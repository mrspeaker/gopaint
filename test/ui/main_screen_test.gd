extends GdUnitTestSuite

const MainScreen := preload("res://addons/gopaint/ui/main_screen.gd")
const PATH := "user://gopaint_test/new_image.png"
const COPY_PATH := "user://gopaint_test/copy.png"


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())


func after_test() -> void:
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(COPY_PATH)


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


func test_save_as_writes_new_file_and_makes_it_current() -> void:
	var screen: MainScreen = auto_free(MainScreen.new())
	screen.create_image(PATH, Vector2i(4, 4))
	screen._image.set_pixel(1, 1, Color.RED)
	screen._on_image_changed()
	var saved := []
	screen.saved.connect(saved.append)
	screen.save_as(COPY_PATH.get_basename())

	assert_that(Image.load_from_file(COPY_PATH).get_pixel(1, 1)).is_equal(Color.RED)
	assert_float(Image.load_from_file(PATH).get_pixel(1, 1).a).is_equal(0.0)
	assert_array(saved).is_equal([COPY_PATH])
	assert_that(screen._path).is_equal(COPY_PATH)
	assert_bool(screen._dirty).is_false()


func test_save_as_is_disabled_without_image() -> void:
	var screen: MainScreen = auto_free(MainScreen.new())
	assert_bool(screen._save_as_button.disabled).is_true()
	screen.create_image(PATH, Vector2i(4, 4))
	assert_bool(screen._save_as_button.disabled).is_false()
