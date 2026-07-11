extends Area2D

const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var speed: float = 520.0
@export var lifetime: float = 1.4
@export var knockback_force: float = 170.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var is_critical: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if GameManager.is_gameplay_paused():
		return
	global_position += direction.normalized() * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, direction.normalized() * knockback_force, is_critical)
	var burst_color := Color(1.0, 0.75, 0.2, 0.95) if is_critical else Color(0.8, 0.95, 1.0, 0.8)
	var burst_size := 1.15 if is_critical else 0.7
	CombatFeedback.show_burst(get_tree().current_scene, global_position, burst_color, burst_size)
	queue_free()
