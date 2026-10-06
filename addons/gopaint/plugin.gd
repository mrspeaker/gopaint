@tool
extends EditorPlugin

const MainScreen := preload("res://addons/gopaint/ui/main_screen.gd")

var _main_screen: MainScreen


func _enter_tree() -> void:
	_main_screen = MainScreen.new()
	_main_screen.saved.connect(_on_saved)
	EditorInterface.get_editor_main_screen().add_child(_main_screen)
	_make_visible(false)


func _exit_tree() -> void:
	if _main_screen:
		_main_screen.queue_free()
		_main_screen = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _main_screen:
		_main_screen.visible = visible


func _get_plugin_name() -> String:
	return "GoPaint"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons")


func _handles(object: Object) -> bool:
	return object is Texture2D


func _edit(object: Object) -> void:
	if object is Texture2D and _main_screen:
		_main_screen.open_texture(object)


# Tells Godot the file changed, so it imports the texture.
func _on_saved(path: String) -> void:
	var filesystem := EditorInterface.get_resource_filesystem()
	if filesystem.get_file_type(path) == "":
		# A scan finds and imports new files.
		filesystem.scan()
	else:
		filesystem.update_file(path)
		filesystem.reimport_files(PackedStringArray([path]))
