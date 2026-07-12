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
