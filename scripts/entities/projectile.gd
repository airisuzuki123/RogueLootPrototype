extends Area2D

const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var speed: float = 520.0
@export var lifetime: float = 1.4
@export var knockback_force: float = 170.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var is_critical: bool = false
var pierce_remaining: int = 0
var explosion_radius: float = 0.0
var explosion_damage: int = 0
var source_player: Node = null
var life_steal_percent: int = 0
var glow_base_scale: Vector2 = Vector2.ONE
@onready var visual: Polygon2D = $Visual
@onready var glow: Polygon2D = $Glow
@onready var trail: Line2D = $Trail
@onready var trail_core: Line2D = $TrailCore

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_configure_visuals()
	_update_visual_rotation()

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	global_position += direction.normalized() * speed * delta
	_update_pulse()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _configure_visuals() -> void:
	var projectile_color := Color(0.82, 0.97, 1.0, 1.0)
	var glow_color := Color(0.35, 0.9, 1.0, 0.22)
	var trail_color := Color(0.45, 0.92, 1.0, 0.36)
	var core_color := Color(1.0, 1.0, 1.0, 0.42)
	if explosion_radius > 0.0:
		projectile_color = Color(1.0, 0.78, 0.38, 1.0)
		glow_color = Color(1.0, 0.48, 0.18, 0.24)
		trail_color = Color(1.0, 0.62, 0.22, 0.38)
	elif is_critical:
		projectile_color = Color(1.0, 0.94, 0.45, 1.0)
		glow_color = Color(1.0, 0.82, 0.2, 0.24)
		trail_color = Color(1.0, 0.86, 0.28, 0.38)
	if visual != null:
		visual.color = projectile_color
	if glow != null:
		glow.color = glow_color
	if trail != null:
		trail.default_color = trail_color
		if trail.gradient != null:
			trail.gradient = trail.gradient.duplicate()
			trail.gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
			trail.gradient.set_color(1, trail_color)
	if trail_core != null:
		trail_core.default_color = core_color
		if trail_core.gradient != null:
			trail_core.gradient = trail_core.gradient.duplicate()
			trail_core.gradient.set_color(0, Color(core_color.r, core_color.g, core_color.b, 0.0))
			trail_core.gradient.set_color(1, core_color)

func _update_visual_rotation() -> void:
	var angle := direction.angle()
	if visual != null:
		visual.rotation = angle
	if glow != null:
		glow.rotation = angle
	if trail != null:
		trail.rotation = angle
	if trail_core != null:
		trail_core.rotation = angle

func _update_pulse() -> void:
	if glow == null:
		return
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.018) * 0.08
	glow.scale = glow_base_scale * pulse

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, direction.normalized() * knockback_force, is_critical)
		_apply_life_steal(damage)
	if explosion_radius > 0.0 and explosion_damage > 0:
		_deal_explosion_damage(body)
	var burst_color := Color(1.0, 0.75, 0.2, 0.95) if is_critical else Color(0.8, 0.95, 1.0, 0.8)
	var burst_size := 0.7
	if explosion_radius > 0.0:
		burst_size = 1.4
	elif is_critical:
		burst_size = 1.15
	CombatFeedback.show_burst(get_tree().current_scene, global_position, burst_color, burst_size)
	if pierce_remaining > 0:
		pierce_remaining -= 1
		return
	queue_free()

func _deal_explosion_damage(primary_body: Node) -> void:
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node == primary_body:
			continue
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > explosion_radius:
			continue
		if enemy.has_method("take_damage"):
			var knockback := global_position.direction_to(enemy.global_position) * knockback_force * 0.55
			enemy.take_damage(explosion_damage, knockback)
			_apply_life_steal(explosion_damage)

func _apply_life_steal(hit_damage: int) -> void:
	if life_steal_percent <= 0 or source_player == null or not is_instance_valid(source_player):
		return
	if source_player.has_method("heal_from_life_steal"):
		source_player.heal_from_life_steal(hit_damage)
