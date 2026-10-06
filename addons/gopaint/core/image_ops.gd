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


## Draws a square brush of the given size centered on center.
static func stamp(image: Image, center: Vector2i, size: int, color: Color) -> void:
	var corner := center - Vector2i.ONE * floori((size - 1) / 2.0)
	image.fill_rect(Rect2i(corner, Vector2i.ONE * size), color)


## Draws a line of square brush stamps from start to end, including both ends.
static func draw_line(image: Image, start: Vector2i, end: Vector2i, size: int, color: Color) -> void:
	var delta := (end - start).abs()
	var step := Vector2i(signi(end.x - start.x), signi(end.y - start.y))
	var error := delta.x - delta.y
	var p := start
	while true:
		stamp(image, p, size, color)
		if p == end:
			return
		var error2 := error * 2
		if error2 > -delta.y:
			error -= delta.y
			p.x += step.x
		if error2 < delta.x:
			error += delta.x
			p.y += step.y


## Draws a rectangle between two corners. The outline is size pixels thick.
static func draw_rect(image: Image, a: Vector2i, b: Vector2i, size: int, color: Color, filled: bool) -> void:
	var rect := Rect2i(a.min(b), (a - b).abs() + Vector2i.ONE)
	if filled or size * 2 >= mini(rect.size.x, rect.size.y):
		image.fill_rect(rect, color)
		return
	var end := rect.end - Vector2i.ONE * size
	image.fill_rect(Rect2i(rect.position, Vector2i(rect.size.x, size)), color)
	image.fill_rect(Rect2i(rect.position.x, end.y, rect.size.x, size), color)
	image.fill_rect(Rect2i(rect.position, Vector2i(size, rect.size.y)), color)
	image.fill_rect(Rect2i(end.x, rect.position.y, size, rect.size.y), color)
