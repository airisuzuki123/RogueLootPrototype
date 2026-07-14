extends Area2D

const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var speed: float = 260.0
@export var lifetime: float = 3.0
@export var damage: int = 8
@export var knockback_force: float = 190.0
@export var graze_radius: float = 30.0

var direction: Vector2 = Vector2.RIGHT
var glow_base_scale: Vector2 = Vector2.ONE
var has_grazed: bool = false
@onready var visual: Polygon2D = $Visual
@onready var glow: Polygon2D = $Glow
@onready var trail: Line2D = $Trail
@onready var trail_core: Line2D = $TrailCore
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemy_projectiles")
	body_entered.connect(_on_body_entered)
	_update_visual_rotation()

func configure(new_direction: Vector2, new_damage: int, new_speed: float, color: Color, scale_multiplier: float = 1.0) -> void:
	direction = Vector2.RIGHT if new_direction.is_zero_approx() else new_direction.normalized()
	damage = new_damage
	speed = new_speed
	if visual == null:
		visual = get_node_or_null("Visual") as Polygon2D
	if glow == null:
		glow = get_node_or_null("Glow") as Polygon2D
	if trail == null:
		trail = get_node_or_null("Trail") as Line2D
	if trail_core == null:
		trail_core = get_node_or_null("TrailCore") as Line2D
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if visual == null:
		return
	visual.color = color
	visual.scale = Vector2.ONE * scale_multiplier
	if glow != null:
		glow.color = Color(color.r, color.g, color.b, 0.28)
		glow_base_scale = Vector2.ONE * scale_multiplier
		glow.scale = glow_base_scale
	if trail != null:
		trail.default_color = Color(color.r, color.g, color.b, 0.5)
		trail.width = 7.0 * scale_multiplier
		if trail.gradient != null:
			trail.gradient = trail.gradient.duplicate()
			trail.gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
			trail.gradient.set_color(1, Color(color.r, color.g, color.b, 0.5))
	if trail_core != null:
		var core_color := color.lerp(Color.WHITE, 0.42)
		trail_core.default_color = Color(core_color.r, core_color.g, core_color.b, 0.34)
		trail_core.width = 2.0 * scale_multiplier
		if trail_core.gradient != null:
			trail_core.gradient = trail_core.gradient.duplicate()
			trail_core.gradient.set_color(0, Color(core_color.r, core_color.g, core_color.b, 0.0))
			trail_core.gradient.set_color(1, Color(core_color.r, core_color.g, core_color.b, 0.34))
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		collision_shape.shape = collision_shape.shape.duplicate()
		var shape := collision_shape.shape as CircleShape2D
		shape.radius = 5.0 * scale_multiplier
	_update_visual_rotation()

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	global_position += direction.normalized() * speed * delta
	_update_pulse()
	_try_graze_player()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _update_visual_rotation() -> void:
	if visual == null:
		return
	visual.rotation = direction.angle()
	if glow != null:
		glow.rotation = direction.angle()
	if trail != null:
		trail.rotation = direction.angle()
	if trail_core != null:
		trail_core.rotation = direction.angle()

func _update_pulse() -> void:
	if glow == null:
		return
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.014) * 0.12
	glow.scale = glow_base_scale * pulse

func _try_graze_player() -> void:
	if has_grazed or GameManager.player == null or not is_instance_valid(GameManager.player):
		return
	var player := GameManager.player as Node2D
	if player == null:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance > graze_radius or distance < 16.0:
		return
	has_grazed = true
	if GameManager.register_graze():
		CombatFeedback.show_text(get_tree().current_scene, player.global_position, "擦弹", Color(0.55, 0.95, 1.0, 1.0))
		CombatFeedback.show_burst(get_tree().current_scene, player.global_position, Color(0.45, 0.9, 1.0, 0.55), 0.55)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, direction.normalized() * knockback_force)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.45, 0.2, 0.85), 0.8)
	queue_free()
