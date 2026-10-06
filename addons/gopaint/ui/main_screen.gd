@tool
extends Control

const ImageOps := preload("res://addons/gopaint/core/image_ops.gd")

var _image: Image
var _canvas: TextureRect
var _status: Label


func _init() -> void:
	name = "GoPaintMainScreen"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	_status = Label.new()
	_status.text = "Select a texture in the FileSystem dock to edit it."
	layout.add_child(_status)

	_canvas = TextureRect.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.gui_input.connect(_on_canvas_input)
	layout.add_child(_canvas)


func open_texture(texture: Texture2D) -> void:
	_image = texture.get_image()
	if _image == null:
		_status.text = "Could not read image data from %s." % texture.resource_path
		return
	_image.decompress()
	_image.convert(Image.FORMAT_RGBA8)
	_status.text = "%s (%d x %d). Click to flood fill." % [
		texture.resource_path, _image.get_width(), _image.get_height()]
	_refresh_canvas()


func _on_canvas_input(event: InputEvent) -> void:
	if _image == null:
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var pixel := _canvas_to_pixel(click.position)
	if pixel.x < 0:
		return
	ImageOps.flood_fill(_image, pixel, Color.RED)
	_refresh_canvas()


# Maps a canvas position to an image pixel. Returns (-1, -1) if outside.
func _canvas_to_pixel(pos: Vector2) -> Vector2i:
	var image_size := Vector2(_image.get_size())
	var scale := minf(_canvas.size.x / image_size.x, _canvas.size.y / image_size.y)
	var offset := (_canvas.size - image_size * scale) / 2.0
	var pixel := Vector2i(((pos - offset) / scale).floor())
	if not Rect2i(Vector2i.ZERO, _image.get_size()).has_point(pixel):
		return Vector2i(-1, -1)
	return pixel


func _refresh_canvas() -> void:
	_canvas.texture = ImageTexture.create_from_image(_image)
