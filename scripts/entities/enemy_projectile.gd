extends Area2D

const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var speed: float = 260.0
@export var lifetime: float = 3.0
@export var damage: int = 8
@export var knockback_force: float = 190.0

var direction: Vector2 = Vector2.RIGHT
@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual_rotation()

func configure(new_direction: Vector2, new_damage: int, new_speed: float, color: Color, scale_multiplier: float = 1.0) -> void:
	direction = Vector2.RIGHT if new_direction.is_zero_approx() else new_direction.normalized()
	damage = new_damage
	speed = new_speed
	if visual == null:
		visual = get_node_or_null("Visual") as Polygon2D
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if visual == null:
		return
	visual.color = color
	visual.scale = Vector2.ONE * scale_multiplier
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		collision_shape.shape = collision_shape.shape.duplicate()
		var shape := collision_shape.shape as CircleShape2D
		shape.radius = 5.0 * scale_multiplier
	_update_visual_rotation()

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	global_position += direction.normalized() * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _update_visual_rotation() -> void:
	if visual == null:
		return
	visual.rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, direction.normalized() * knockback_force)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.45, 0.2, 0.85), 0.8)
	queue_free()
