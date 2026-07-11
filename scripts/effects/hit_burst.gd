extends Node2D

@export var lifetime: float = 0.18

var elapsed: float = 0.0
@onready var visual: Polygon2D = $Visual

func setup(tint: Color = Color(1, 0.9, 0.25, 0.85), start_scale: float = 1.0) -> void:
	if visual == null:
		await ready
	visual.color = tint
	scale = Vector2.ONE * start_scale

func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / lifetime, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.65, 1.65, progress)
	visual.color.a = 1.0 - progress
	if elapsed >= lifetime:
		queue_free()

