@tool
extends RefCounted

## Undo and redo for one image, stored as full copies of the image.

const LIMIT := 100

var _undo: Array[Image] = []
var _redo: Array[Image] = []


## Saves the image as it is before a change.
func record(image: Image) -> void:
	_undo.push_back(copy_image(image))
	if _undo.size() > LIMIT:
		_undo.pop_front()
	_redo.clear()


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


## Restores the previous state into image. Returns false if there is none.
func undo(image: Image) -> bool:
	return _move(_undo, _redo, image)


## Restores the next state into image. Returns false if there is none.
func redo(image: Image) -> bool:
	return _move(_redo, _undo, image)


func clear() -> void:
	_undo.clear()
	_redo.clear()


func _move(from: Array[Image], to: Array[Image], image: Image) -> bool:
	if from.is_empty():
		return false
	to.push_back(copy_image(image))
	image.copy_from(from.pop_back())
	return true


static func copy_image(image: Image) -> Image:
	var copy := Image.new()
	copy.copy_from(image)
	return copy
