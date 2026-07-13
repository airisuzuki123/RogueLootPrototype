extends Node2D

@export var arena_position: Vector2 = Vector2(80.0, 70.0)
@export var arena_size: Vector2 = Vector2(1120.0, 580.0)
@export var grid_spacing: float = 80.0
@export var grid_color: Color = Color(0.18, 0.42, 0.58, 0.18)
@export var fill_color: Color = Color(0.02, 0.035, 0.06, 0.72)
@export var border_color: Color = Color(0.15, 0.95, 1.0, 0.95)
@export var inner_border_color: Color = Color(1.0, 0.35, 0.95, 0.55)

func get_arena_rect() -> Rect2:
	return Rect2(arena_position, arena_size)

func get_spawn_rect(margin: float = 24.0) -> Rect2:
	var rect := get_arena_rect()
	var clamped_margin := minf(margin, minf(rect.size.x, rect.size.y) * 0.45)
	return Rect2(rect.position + Vector2.ONE * clamped_margin, rect.size - Vector2.ONE * clamped_margin * 2.0)

func _draw() -> void:
	var rect := get_arena_rect()
	draw_rect(rect, fill_color, true)
	_draw_grid(rect)
	_draw_corner_marks(rect)
	draw_rect(rect, border_color, false, 3.0)
	draw_rect(rect.grow(-8.0), inner_border_color, false, 1.0)

func _draw_grid(rect: Rect2) -> void:
	if grid_spacing <= 0.0:
		return
	var x := rect.position.x + grid_spacing
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), grid_color, 1.0)
		x += grid_spacing
	var y := rect.position.y + grid_spacing
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), grid_color, 1.0)
		y += grid_spacing

func _draw_corner_marks(rect: Rect2) -> void:
	var mark_length := 42.0
	var mark_width := 4.0
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	var directions := [
		[Vector2.RIGHT, Vector2.DOWN],
		[Vector2.LEFT, Vector2.DOWN],
		[Vector2.LEFT, Vector2.UP],
		[Vector2.RIGHT, Vector2.UP]
	]
	for index in range(corners.size()):
		var corner: Vector2 = corners[index]
		var first_direction: Vector2 = directions[index][0]
		var second_direction: Vector2 = directions[index][1]
		draw_line(corner, corner + first_direction * mark_length, Color(1.0, 1.0, 1.0, 0.82), mark_width)
		draw_line(corner, corner + second_direction * mark_length, Color(1.0, 1.0, 1.0, 0.82), mark_width)
