extends GdUnitTestSuite

const CanvasView := preload("res://addons/gopaint/ui/canvas_view.gd")

var _canvas: CanvasView
var _image: Image


func before_test() -> void:
	_image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	_image.fill(Color.WHITE)
	_canvas = auto_free(CanvasView.new())
	_canvas.size = Vector2(80, 80)
	_canvas.set_image(_image)
	_canvas.zoom_at(Vector2.ZERO, 10.0)
	_canvas._offset = Vector2.ZERO


func _drag(button: MouseButton, from: Vector2i, to: Vector2i, command := false) -> void:
	var press := InputEventMouseButton.new()
	_set_command(press, command)
	press.button_index = button
	press.pressed = true
	press.position = Vector2(from) * 10.0 + Vector2(5, 5)
	_canvas._gui_input(press)
	var motion := InputEventMouseMotion.new()
	_set_command(motion, command)
	motion.position = Vector2(to) * 10.0 + Vector2(5, 5)
	_canvas._gui_input(motion)
	var release := press.duplicate()
	release.pressed = false
	_canvas._gui_input(release)


func test_pencil_draws_line_with_left_color() -> void:
	_drag(MOUSE_BUTTON_LEFT, Vector2i(0, 0), Vector2i(3, 0))
	assert_that(_image.get_pixel(3, 0)).is_equal(Color.BLACK)
	assert_that(_image.get_pixel(4, 0)).is_equal(Color.WHITE)


func test_right_button_uses_right_color() -> void:
	_canvas.colors[MOUSE_BUTTON_RIGHT] = Color.RED
	_drag(MOUSE_BUTTON_RIGHT, Vector2i(1, 1), Vector2i(1, 1))
	assert_that(_image.get_pixel(1, 1)).is_equal(Color.RED)


func test_line_tool_replaces_preview_while_dragging() -> void:
	_canvas.tool = CanvasView.Tool.LINE
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(5, 5)
	_canvas._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(75, 5)
	_canvas._gui_input(motion)
	motion.position = Vector2(5, 75)
	_canvas._gui_input(motion)
	assert_that(_image.get_pixel(7, 0)).is_equal(Color.WHITE)
	assert_that(_image.get_pixel(0, 7)).is_equal(Color.BLACK)


func test_picker_sets_button_color() -> void:
	_image.set_pixel(2, 2, Color.BLUE)
	_canvas.tool = CanvasView.Tool.PICKER
	_drag(MOUSE_BUTTON_RIGHT, Vector2i(2, 2), Vector2i(2, 2))
	assert_that(_canvas.colors[MOUSE_BUTTON_RIGHT]).is_equal(Color.BLUE)


func test_undo_reverts_stroke() -> void:
	_drag(MOUSE_BUTTON_LEFT, Vector2i(0, 0), Vector2i(3, 0))
	_canvas.undo()
	assert_that(_image.get_pixel(0, 0)).is_equal(Color.WHITE)
	_canvas.redo()
	assert_that(_image.get_pixel(0, 0)).is_equal(Color.BLACK)


func _set_command(event: InputEventWithModifiers, pressed: bool) -> void:
	if CanvasView._command_key() == KEY_META:
		event.meta_pressed = pressed
	else:
		event.ctrl_pressed = pressed


func _command_key(pressed: bool) -> void:
	var key := InputEventKey.new()
	key.keycode = CanvasView._command_key()
	key.pressed = pressed
	_set_command(key, pressed)
	_canvas._input(key)


func test_holding_command_key_picks_color_then_restores_tool() -> void:
	add_child(_canvas)
	_image.set_pixel(2, 2, Color.RED)
	var changes := []
	_canvas.active_tool_changed.connect(changes.append)
	_command_key(true)
	assert_int(_canvas.get_active_tool()).is_equal(CanvasView.Tool.PICKER)
	_drag(MOUSE_BUTTON_LEFT, Vector2i(2, 2), Vector2i(2, 2), true)
	assert_that(_canvas.colors[MOUSE_BUTTON_LEFT]).is_equal(Color.RED)
	assert_that(_image.get_pixel(2, 2)).is_equal(Color.RED)

	_command_key(false)
	assert_int(_canvas.get_active_tool()).is_equal(CanvasView.Tool.PENCIL)
	assert_array(changes).is_equal([CanvasView.Tool.PICKER, CanvasView.Tool.PENCIL])
	_drag(MOUSE_BUTTON_LEFT, Vector2i(0, 0), Vector2i(0, 0))
	assert_that(_image.get_pixel(0, 0)).is_equal(Color.RED)


func test_mouse_event_without_modifier_releases_picker() -> void:
	add_child(_canvas)
	_command_key(true)
	_canvas._gui_input(InputEventMouseMotion.new())
	assert_int(_canvas.get_active_tool()).is_equal(CanvasView.Tool.PENCIL)
