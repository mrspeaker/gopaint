@tool
extends RefCounted

## Pixel operations on Image objects. No editor dependencies, so tests run headless.


## Fills the contiguous area of matching color that contains start.
static func flood_fill(image: Image, start: Vector2i, color: Color) -> void:
	var bounds := Rect2i(Vector2i.ZERO, image.get_size())
	if not bounds.has_point(start):
		return
	var target := image.get_pixelv(start)
	if target.is_equal_approx(color):
		return

	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if not bounds.has_point(p) or not image.get_pixelv(p).is_equal_approx(target):
			continue
		image.set_pixelv(p, color)
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN)
		stack.append(p + Vector2i.UP)
