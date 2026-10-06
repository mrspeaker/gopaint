@tool
extends VBoxContainer

## GoPaint main screen: toolbar at the top, tool panel on the left, canvas on the right.

signal saved(path: String)

const CanvasView := preload("res://addons/gopaint/ui/canvas_view.gd")
const ToolPanel := preload("res://addons/gopaint/ui/tool_panel.gd")
const NewImageDialog := preload("res://addons/gopaint/ui/new_image_dialog.gd")

var _image: Image
var _path := ""
var _dirty := false
var _canvas: CanvasView
var _tools: ToolPanel
var _new_dialog: NewImageDialog
var _file_label: Label
var _zoom_label: Label
var _save_button: Button
var _undo_button: Button
var _redo_button: Button
var _icon_buttons := {}


func _init() -> void:
	name = "GoPaintMainScreen"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_canvas = CanvasView.new()
	_tools = ToolPanel.new()
	_new_dialog = NewImageDialog.new()
	_new_dialog.image_requested.connect(create_image)
	add_child(_new_dialog)

	add_child(_make_toolbar())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tools)
	body.add_child(_canvas)
	add_child(body)

	_tools.tool_selected.connect(func(tool: int) -> void: _canvas.tool = tool)
	_tools.brush_size_changed.connect(func(value: int) -> void: _canvas.brush_size = value)
	_tools.fill_shapes_toggled.connect(func(filled: bool) -> void: _canvas.fill_shapes = filled)
	_tools.color_changed.connect(func(button: MouseButton, color: Color) -> void:
		_canvas.colors[button] = color)
	_canvas.color_picked.connect(_tools.set_color)
	_canvas.image_changed.connect(_on_image_changed)
	_canvas.zoom_changed.connect(func(zoom: float) -> void:
		_zoom_label.text = "%d%%" % roundi(zoom * 100))
	_update_buttons()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		for button: Button in _icon_buttons:
			var icon_name: String = _icon_buttons[button]
			if has_theme_icon(icon_name, "EditorIcons"):
				button.icon = get_theme_icon(icon_name, "EditorIcons")
				button.text = ""
			else:
				button.icon = null
				button.text = button.tooltip_text


func open_texture(texture: Texture2D) -> void:
	# Keep unsaved edits when the same file is selected again.
	if texture.resource_path == _path and _image != null:
		return
	var image := texture.get_image()
	if image == null:
		_file_label.text = "Could not read image data from %s." % texture.resource_path
		return
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	_set_image(image, texture.resource_path)


## Saves a blank transparent PNG at path and opens it.
func create_image(path: String, image_size: Vector2i) -> void:
	var image := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	var err := image.save_png(path)
	if err != OK:
		push_error("GoPaint: could not create %s: %s" % [path, error_string(err)])
		return
	_set_image(image, path)
	saved.emit(path)


func save() -> void:
	if not _can_save():
		return
	var err := _image.save_png(_path)
	if err != OK:
		push_error("GoPaint: could not save %s: %s" % [_path, error_string(err)])
		return
	_dirty = false
	_update_buttons()
	saved.emit(_path)


func _set_image(image: Image, path: String) -> void:
	_image = image
	_path = path
	_dirty = false
	_canvas.set_image(_image)
	_update_buttons()


func _can_save() -> bool:
	return _image != null and _path.get_extension().to_lower() == "png"


func _on_image_changed() -> void:
	_dirty = true
	_update_buttons()


func _update_buttons() -> void:
	_save_button.disabled = not (_can_save() and _dirty)
	_undo_button.disabled = not _canvas.history.can_undo()
	_redo_button.disabled = not _canvas.history.can_redo()
	if _image == null:
		_file_label.text = "Select a texture in the FileSystem dock to edit it."
	else:
		_file_label.text = "%s%s  (%d x %d)" % [
			_path.get_file(), " *" if _dirty else "", _image.get_width(), _image.get_height()]
		_file_label.tooltip_text = _path


func _make_toolbar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	_add_button(bar, "New", "New image", func() -> void:
		_new_dialog.open(_path.get_base_dir() if _path != "" else "res://"))
	_save_button = _add_button(bar, "Save", "Save", save)
	bar.add_child(VSeparator.new())
	_undo_button = _add_button(bar, "Undo", "Undo", func() -> void:
		_canvas.undo())
	_redo_button = _add_button(bar, "Redo", "Redo", func() -> void:
		_canvas.redo())
	bar.add_child(VSeparator.new())
	_add_button(bar, "", "-", _canvas.zoom_out).tooltip_text = "Zoom out"
	_zoom_label = Label.new()
	_zoom_label.custom_minimum_size.x = 48
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_label.text = "100%"
	bar.add_child(_zoom_label)
	_add_button(bar, "", "+", _canvas.zoom_in).tooltip_text = "Zoom in"
	_add_button(bar, "", "1:1", func() -> void:
		_canvas.zoom_at(_canvas.size / 2.0, 1.0)).tooltip_text = "Actual size"
	_add_button(bar, "", "Fit", _canvas.zoom_to_fit).tooltip_text = "Fit to view"
	var grid := _add_button(bar, "Grid", "Grid", Callable())
	grid.toggle_mode = true
	grid.button_pressed = true
	grid.toggled.connect(func(on: bool) -> void: _canvas.show_grid = on)
	bar.add_child(VSeparator.new())
	_file_label = Label.new()
	_file_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_file_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_file_label.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.add_child(_file_label)
	return bar


# Adds a flat button. Uses the editor icon when icon_name is set and available.
func _add_button(bar: HBoxContainer, icon_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.flat = true
	button.text = text
	button.tooltip_text = text
	if action.is_valid():
		button.pressed.connect(action)
	if icon_name != "":
		_icon_buttons[button] = icon_name
	bar.add_child(button)
	return button
