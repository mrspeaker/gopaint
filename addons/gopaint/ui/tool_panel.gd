@tool
extends VBoxContainer

## Left panel: tools, brush options, mouse button colors and palette.

signal tool_selected(tool: int)
signal brush_size_changed(size: int)
signal fill_shapes_toggled(filled: bool)
signal color_changed(button: MouseButton, color: Color)

const CanvasView := preload("res://addons/gopaint/ui/canvas_view.gd")

# Tool, editor icon name, tooltip.
const TOOLS := [
	[CanvasView.Tool.PENCIL, "Edit", "Pencil"],
	[CanvasView.Tool.ERASER, "Eraser", "Eraser"],
	[CanvasView.Tool.FILL, "Bucket", "Fill"],
	[CanvasView.Tool.PICKER, "ColorPick", "Color picker"],
	[CanvasView.Tool.LINE, "Line", "Line"],
	[CanvasView.Tool.RECT, "Rectangle", "Rectangle"],
]

# PICO-8 palette.
const PALETTE := [
	"000000", "1d2b53", "7e2553", "008751", "ab5236", "5f574f", "c2c3c7", "fff1e8",
	"ff004d", "ffa300", "ffec27", "00e436", "29adff", "83769c", "ff77a8", "ffccaa",
]

const SWATCH_SIZE := Vector2(22, 22)

var _tool_buttons: Array[Button] = []
var _color_buttons := {}


func _init() -> void:
	custom_minimum_size.x = 104
	add_theme_constant_override("separation", 8)

	var tools := GridContainer.new()
	tools.columns = 3
	var group := ButtonGroup.new()
	for entry in TOOLS:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = entry[2]
		button.set_meta("icon_name", entry[1])
		button.pressed.connect(tool_selected.emit.bind(entry[0]))
		tools.add_child(button)
		_tool_buttons.append(button)
	_tool_buttons[0].button_pressed = true
	add_child(tools)

	add_child(HSeparator.new())
	add_child(_make_label("Brush size"))
	var brush := SpinBox.new()
	brush.min_value = 1
	brush.max_value = 32
	brush.value = 1
	brush.value_changed.connect(func(value: float) -> void: brush_size_changed.emit(int(value)))
	add_child(brush)

	var filled := CheckBox.new()
	filled.text = "Fill shapes"
	filled.toggled.connect(fill_shapes_toggled.emit)
	add_child(filled)

	add_child(HSeparator.new())
	add_child(_make_label("Colors"))
	var pair := HBoxContainer.new()
	pair.add_child(_make_color_button(MOUSE_BUTTON_LEFT, Color.BLACK, "Left mouse button color"))
	pair.add_child(_make_color_button(MOUSE_BUTTON_RIGHT, Color.WHITE, "Right mouse button color"))
	add_child(pair)

	var palette := GridContainer.new()
	palette.columns = 4
	palette.add_theme_constant_override("h_separation", 2)
	palette.add_theme_constant_override("v_separation", 2)
	for hex in PALETTE:
		palette.add_child(_make_swatch(Color.html(hex)))
	add_child(palette)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_icons()


## Updates the color shown for a mouse button, for example after using the picker.
## Shows tool as selected without sending tool_selected.
func show_tool(tool: int) -> void:
	for i in TOOLS.size():
		_tool_buttons[i].set_pressed_no_signal(TOOLS[i][0] == tool)


func set_color(button: MouseButton, color: Color) -> void:
	_color_buttons[button].color = color


func _set_color(button: MouseButton, color: Color) -> void:
	set_color(button, color)
	color_changed.emit(button, color)


# Uses editor icons when available, otherwise short text labels.
func _update_icons() -> void:
	for button in _tool_buttons:
		var icon_name: String = button.get_meta("icon_name")
		if has_theme_icon(icon_name, "EditorIcons"):
			button.icon = get_theme_icon(icon_name, "EditorIcons")
			button.text = ""
		else:
			button.icon = null
			button.text = button.tooltip_text.left(2)


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _make_color_button(button: MouseButton, color: Color, tooltip: String) -> ColorPickerButton:
	var picker := ColorPickerButton.new()
	picker.color = color
	picker.tooltip_text = tooltip
	picker.custom_minimum_size = Vector2(40, 32)
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.color_changed.connect(func(c: Color) -> void: color_changed.emit(button, c))
	_color_buttons[button] = picker
	return picker


# Left click sets the left color. Right click sets the right color.
func _make_swatch(color: Color) -> ColorRect:
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = SWATCH_SIZE
	swatch.tooltip_text = "#" + color.to_html(false)
	swatch.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_set_color(click.button_index, color))
	return swatch
