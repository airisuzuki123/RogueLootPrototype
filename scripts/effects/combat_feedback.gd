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
