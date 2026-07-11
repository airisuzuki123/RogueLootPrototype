extends Area2D

const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var speed: float = 260.0
@export var lifetime: float = 3.0
@export var damage: int = 8
@export var knockback_force: float = 190.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	global_position += direction.normalized() * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, direction.normalized() * knockback_force)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.45, 0.2, 0.85), 0.8)
	queue_free()
