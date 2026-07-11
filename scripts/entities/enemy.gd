extends CharacterBody2D

const LOOT_DROP_SCENE := preload("res://scenes/loot_drop.tscn")
const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var move_speed: float = 120.0
@export var max_health: int = 20
@export var touch_damage: int = 10
@export var loot_chance: float = 0.45
@export var experience_reward: int = 1
@export var attack_interval: float = 0.8

var health: int
var target: Node2D
var attack_cooldown: float = 0.0
@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_upgrade_pending:
		return
	attack_cooldown -= delta
	if target == null or not is_instance_valid(target):
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()
	if global_position.distance_to(target.global_position) <= 24.0:
		_try_touch_damage()

func take_damage(amount: int) -> void:
	if GameManager.is_run_over:
		return
	health -= amount
	_flash_on_hit()
	CombatFeedback.show_damage(get_tree().current_scene, global_position, amount, Color(1, 0.95, 0.45, 1))
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.8, 0.15, 0.85), 0.8)
	if health <= 0:
		_die()

func _die() -> void:
	GameManager.register_kill()
	GameManager.add_experience(experience_reward)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.35, 0.25, 0.95), 1.6)
	if randf() <= loot_chance:
		var loot := LOOT_DROP_SCENE.instantiate()
		loot.global_position = global_position
		loot.source_level = GameManager.level
		get_tree().current_scene.add_child(loot)
	queue_free()

func _try_touch_damage() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = attack_interval
	if target.has_method("take_damage"):
		target.take_damage(touch_damage)

func _flash_on_hit() -> void:
	visual.modulate = Color(1.6, 1.6, 1.6, 1)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.08)
