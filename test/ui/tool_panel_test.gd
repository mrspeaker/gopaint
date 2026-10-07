extends GdUnitTestSuite

const ToolPanel := preload("res://addons/gopaint/ui/tool_panel.gd")
const CanvasView := preload("res://addons/gopaint/ui/canvas_view.gd")


func test_show_tool_selects_one_button_without_signal() -> void:
	var panel: ToolPanel = auto_free(ToolPanel.new())
	var selected := []
	panel.tool_selected.connect(selected.append)
	panel.show_tool(CanvasView.Tool.PICKER)

	var pressed := panel._tool_buttons.filter(func(b: Button) -> bool: return b.button_pressed)
	assert_array(pressed).is_equal([panel._tool_buttons[3]])
	assert_array(selected).is_empty()
