@tool
extends FileDialog

## Asks for a PNG path in the project and an image size.

signal image_requested(path: String, size: Vector2i)

const DEFAULT_SIZE := Vector2i(64, 64)
const MAX_SIDE := 4096
const DEFAULT_NAME := "new_image.png"

var _width: SpinBox
var _height: SpinBox


func _init() -> void:
	title = "New Image"
	file_mode = FileDialog.FILE_MODE_SAVE_FILE
	access = FileDialog.ACCESS_RESOURCES
	filters = PackedStringArray(["*.png ; PNG Images"])
	ok_button_text = "Create"

	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "Size:"
	row.add_child(label)
	_width = _make_side(DEFAULT_SIZE.x, "Width in pixels")
	row.add_child(_width)
	var times := Label.new()
	times.text = "x"
	row.add_child(times)
	_height = _make_side(DEFAULT_SIZE.y, "Height in pixels")
	row.add_child(_height)
	get_vbox().add_child(row)

	file_selected.connect(_on_file_selected)


## Opens the dialog in folder dir.
func open(dir: String) -> void:
	current_path = dir.path_join(DEFAULT_NAME)
	popup_centered_ratio(0.5)


func get_image_size() -> Vector2i:
	return Vector2i(int(_width.value), int(_height.value))


func _on_file_selected(path: String) -> void:
	if path.get_extension().to_lower() != "png":
		path += ".png"
	image_requested.emit(path, get_image_size())


func _make_side(value: int, tooltip: String) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = MAX_SIDE
	spin.value = value
	spin.suffix = "px"
	spin.tooltip_text = tooltip
	return spin
