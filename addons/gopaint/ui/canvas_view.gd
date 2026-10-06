@tool
extends Control

## Shows the image and turns mouse input into drawing. Wheel zooms, middle button pans.

signal color_picked(button: MouseButton, color: Color)
signal image_changed
signal zoom_changed(zoom: float)

enum Tool { PENCIL, ERASER, FILL, PICKER, LINE, RECT }

const ImageOps := preload("res://addons/gopaint/core/image_ops.gd")
const History := preload("res://addons/gopaint/core/history.gd")

const MIN_ZOOM := 0.125
const MAX_ZOOM := 64.0
const GRID_MIN_ZOOM := 6.0
const BACKGROUND := Color(0.15, 0.15, 0.17)
const GRID_COLOR := Color(0.5, 0.5, 0.5, 0.35)
const CHECKER_CELL := 8

var tool := Tool.PENCIL
var brush_size := 1
var fill_shapes := false
var colors := {MOUSE_BUTTON_LEFT: Color.BLACK, MOUSE_BUTTON_RIGHT: Color.WHITE}
var history := History.new()
var zoom := 1.0
var show_grid := true:
	set(value):
		show_grid = value
		queue_redraw()

var _image: Image
var _texture: ImageTexture
var _checker: ImageTexture
var _offset := Vector2.ZERO
var _needs_fit := false
var _panning := false
var _stroke_button := MOUSE_BUTTON_NONE
var _stroke_start: Vector2i
var _stroke_last: Vector2i
var _stroke_base: Image


func _init() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(_on_resized)
	_checker = _make_checker()


## Shows image and edits it in place. Clears the undo history.
func set_image(image: Image) -> void:
	_image = image
	_texture = null
	history.clear()
	_end_stroke()
	_update_texture()
	zoom_to_fit()


func zoom_to_fit() -> void:
	if _image == null:
		return
	if size.x <= 0 or size.y <= 0:
		_needs_fit = true
		return
	_needs_fit = false
	var image_size := Vector2(_image.get_size())
	var fit := minf(size.x / image_size.x, size.y / image_size.y) * 0.9
	_set_zoom(floorf(fit) if fit >= 1.0 else fit)
	_offset = ((size - image_size * zoom) / 2.0).floor()
	queue_redraw()


## Changes zoom and keeps the image point under pos in place.
func zoom_at(pos: Vector2, new_zoom: float) -> void:
	if _image == null:
		return
	var image_pos := (pos - _offset) / zoom
	_set_zoom(new_zoom)
	_offset = (pos - image_pos * zoom).floor()
	queue_redraw()


func zoom_in() -> void:
	zoom_at(size / 2.0, zoom * 2.0)


func zoom_out() -> void:
	zoom_at(size / 2.0, zoom / 2.0)


func undo() -> void:
	if _image and history.undo(_image):
		_update_texture()
		image_changed.emit()


func redo() -> void:
	if _image and history.redo(_image):
		_update_texture()
		image_changed.emit()


func _set_zoom(value: float) -> void:
	zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	zoom_changed.emit(zoom)


func _on_resized() -> void:
	if _needs_fit:
		zoom_to_fit()


func _update_texture() -> void:
	if _image == null:
		_texture = null
	elif _texture and Vector2i(_texture.get_size()) == _image.get_size():
		_texture.update(_image)
	else:
		_texture = ImageTexture.create_from_image(_image)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	if _texture == null:
		return
	var image_rect := Rect2(_offset, Vector2(_image.get_size()) * zoom)
	var visible_rect := image_rect.intersection(Rect2(Vector2.ZERO, size))
	if visible_rect.has_area():
		draw_texture_rect(_checker, visible_rect, true)
	draw_texture_rect(_texture, image_rect, false)
	if show_grid and zoom >= GRID_MIN_ZOOM:
		_draw_grid(visible_rect)
	draw_rect(image_rect, GRID_COLOR, false)


func _draw_grid(area: Rect2) -> void:
	if not area.has_area():
		return
	var lines := PackedVector2Array()
	var first := ((area.position - _offset) / zoom).ceil()
	var last := ((area.end - _offset) / zoom).floor()
	for x in range(int(first.x), int(last.x) + 1):
		var sx := _offset.x + x * zoom
		lines.append_array([Vector2(sx, area.position.y), Vector2(sx, area.end.y)])
	for y in range(int(first.y), int(last.y) + 1):
		var sy := _offset.y + y * zoom
		lines.append_array([Vector2(area.position.x, sy), Vector2(area.end.x, sy)])
	draw_multiline(lines, GRID_COLOR)


func _gui_input(event: InputEvent) -> void:
	if _image == null:
		return
	var button := event as InputEventMouseButton
	if button:
		_on_mouse_button(button)
		accept_event()
	var motion := event as InputEventMouseMotion
	if motion:
		if _panning:
			_offset += motion.relative
			queue_redraw()
		elif _stroke_button != MOUSE_BUTTON_NONE:
			_continue_stroke(_to_pixel(motion.position))
		accept_event()


func _on_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				zoom_at(event.position, zoom * 1.25)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				zoom_at(event.position, zoom / 1.25)
		MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
			if event.pressed and _stroke_button == MOUSE_BUTTON_NONE:
				_start_stroke(event.button_index, _to_pixel(event.position))
			elif not event.pressed and event.button_index == _stroke_button:
				_end_stroke()
				image_changed.emit()


func _to_pixel(pos: Vector2) -> Vector2i:
	return Vector2i(((pos - _offset) / zoom).floor())


func _in_image(pixel: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, _image.get_size()).has_point(pixel)


func _start_stroke(button: MouseButton, pixel: Vector2i) -> void:
	match tool:
		Tool.PICKER:
			if _in_image(pixel):
				colors[button] = _image.get_pixelv(pixel)
				color_picked.emit(button, colors[button])
			return
		Tool.FILL:
			if _in_image(pixel):
				history.record(_image)
				ImageOps.flood_fill(_image, pixel, colors[button])
				_update_texture()
				image_changed.emit()
			return
	history.record(_image)
	_stroke_button = button
	_stroke_start = pixel
	_stroke_last = pixel
	if tool == Tool.LINE or tool == Tool.RECT:
		_stroke_base = History.copy_image(_image)
	_continue_stroke(pixel)


func _continue_stroke(pixel: Vector2i) -> void:
	var color: Color = colors[_stroke_button]
	match tool:
		Tool.PENCIL:
			ImageOps.draw_line(_image, _stroke_last, pixel, brush_size, color)
		Tool.ERASER:
			ImageOps.draw_line(_image, _stroke_last, pixel, brush_size, Color.TRANSPARENT)
		Tool.LINE:
			_image.copy_from(_stroke_base)
			ImageOps.draw_line(_image, _stroke_start, pixel, brush_size, color)
		Tool.RECT:
			_image.copy_from(_stroke_base)
			ImageOps.draw_rect(_image, _stroke_start, pixel, brush_size, color, fill_shapes)
	_stroke_last = pixel
	_update_texture()


func _end_stroke() -> void:
	_stroke_button = MOUSE_BUTTON_NONE
	_stroke_base = null


static func _make_checker() -> ImageTexture:
	var image := Image.create(CHECKER_CELL * 2, CHECKER_CELL * 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.8, 0.8))
	image.fill_rect(Rect2i(0, 0, CHECKER_CELL, CHECKER_CELL), Color(0.6, 0.6, 0.6))
	image.fill_rect(Rect2i(CHECKER_CELL, CHECKER_CELL, CHECKER_CELL, CHECKER_CELL), Color(0.6, 0.6, 0.6))
	return ImageTexture.create_from_image(image)
