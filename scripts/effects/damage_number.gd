extends Label

@export var float_distance: float = 34.0
@export var lifetime: float = 0.65

var velocity: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var start_position: Vector2

func setup(amount: int, tint: Color = Color.WHITE) -> void:
	text = str(amount)
	modulate = tint

func setup_text(content: String, tint: Color = Color.WHITE) -> void:
	text = content
	modulate = tint

func _ready() -> void:
	start_position = global_position
	velocity = Vector2(randf_range(-18.0, 18.0), -float_distance)

func _process(delta: float) -> void:
	elapsed += delta
	global_position += velocity * delta
	var progress := clampf(elapsed / lifetime, 0.0, 1.0)
	modulate.a = 1.0 - progress
	scale = Vector2.ONE * lerpf(1.25, 0.85, progress)
	if elapsed >= lifetime:
		queue_free()
