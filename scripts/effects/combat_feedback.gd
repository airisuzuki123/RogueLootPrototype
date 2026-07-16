class_name CombatFeedback
extends RefCounted

const DAMAGE_NUMBER_SCENE := preload("res://scenes/damage_number.tscn")
const HIT_BURST_SCENE := preload("res://scenes/hit_burst.tscn")

static func show_damage(world: Node, position: Vector2, amount: int, tint: Color = Color.WHITE) -> void:
	if world == null:
		return
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	number.global_position = position + Vector2(-10, -28)
	world.add_child(number)
	number.setup(amount, tint)

static func show_text(world: Node, position: Vector2, content: String, tint: Color = Color.WHITE) -> void:
	if world == null:
		return
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	number.global_position = position + Vector2(-18, -34)
	world.add_child(number)
	number.setup_text(content, tint)

static func show_burst(world: Node, position: Vector2, tint: Color = Color(1, 0.9, 0.25, 0.85), size: float = 1.0) -> void:
	if world == null:
		return
	var burst := HIT_BURST_SCENE.instantiate()
	burst.global_position = position
	world.add_child(burst)
	burst.setup(tint, size)

static func show_line(world: Node, start_position: Vector2, end_position: Vector2, tint: Color, width: float = 3.0, duration: float = 0.08) -> void:
	if world == null:
		return
	var line := Line2D.new()
	line.global_position = Vector2.ZERO
	line.points = PackedVector2Array([start_position, end_position])
	line.width = width
	line.default_color = tint
	line.z_index = 4
	world.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(line, "queue_free"))

static func show_ring(world: Node, position: Vector2, radius: float, tint: Color, width: float = 4.0, duration: float = 0.18) -> void:
	if world == null:
		return
	var ring := Line2D.new()
	ring.global_position = Vector2.ZERO
	ring.closed = true
	ring.width = width
	ring.default_color = tint
	ring.z_index = 5
	var points := PackedVector2Array()
	var segment_count := 48
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		points.append(position + Vector2.RIGHT.rotated(angle) * radius)
	ring.points = points
	world.add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "width", width * 0.35, duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(ring, "queue_free"))
