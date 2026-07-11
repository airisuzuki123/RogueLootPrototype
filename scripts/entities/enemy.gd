extends CharacterBody2D

const LOOT_DROP_SCENE := preload("res://scenes/loot_drop.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemy_projectile.tscn")
const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var move_speed: float = 120.0
@export var max_health: int = 20
@export var touch_damage: int = 10
@export var loot_chance: float = 0.45
@export var experience_reward: int = 1
@export var attack_interval: float = 0.8
@export var knockback_recovery: float = 9.0
@export var enemy_type: String = "grunt"
@export var ranged_attack_range: float = 260.0
@export var ranged_keep_distance: float = 170.0

var health: int
var target: Node2D
var attack_cooldown: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
@onready var visual: Polygon2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	_apply_enemy_type(enemy_type)
	health = max_health
	_update_health_bar(false)
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_upgrade_pending:
		return
	attack_cooldown -= delta
	if target == null or not is_instance_valid(target):
		return
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var direction := to_target.normalized()
	velocity = _get_desired_velocity(direction, distance) + knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_recovery * knockback_velocity.length() * delta)
	if enemy_type == "ranged" and distance <= ranged_attack_range:
		_try_ranged_attack(direction)
	elif distance <= 24.0:
		_try_touch_damage()

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if GameManager.is_run_over:
		return
	health -= amount
	knockback_velocity += knockback
	_update_health_bar(true)
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
		var knockback := global_position.direction_to(target.global_position) * 220.0
		target.take_damage(touch_damage, knockback)

func _try_ranged_attack(direction: Vector2) -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = attack_interval
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.damage = touch_damage
	get_tree().current_scene.add_child(projectile)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.55, 0.25, 0.75), 0.7)

func _flash_on_hit() -> void:
	visual.modulate = Color(1.6, 1.6, 1.6, 1)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.08)

func _update_health_bar(show_when_damaged: bool) -> void:
	health_bar.max_value = max_health
	health_bar.value = clampi(health, 0, max_health)
	health_bar.visible = show_when_damaged and health > 0 and health < max_health

func configure(type_id: String) -> void:
	enemy_type = type_id

func _apply_enemy_type(type_id: String) -> void:
	match type_id:
		"runner":
			max_health = 12
			move_speed = 175.0
			touch_damage = 7
			experience_reward = 1
			visual.color = Color(1, 0.55, 0.2, 1)
			visual.scale = Vector2(0.85, 0.85)
		"tank":
			max_health = 55
			move_speed = 75.0
			touch_damage = 16
			experience_reward = 3
			loot_chance = 0.65
			visual.color = Color(0.75, 0.15, 1, 1)
			visual.scale = Vector2(1.35, 1.35)
		"ranged":
			max_health = 18
			move_speed = 95.0
			touch_damage = 8
			attack_interval = 1.35
			experience_reward = 2
			visual.color = Color(0.25, 1, 0.65, 1)
			visual.scale = Vector2(1.0, 1.0)
		_:
			enemy_type = "grunt"
			max_health = 20
			move_speed = 120.0
			touch_damage = 10
			experience_reward = 1
			visual.color = Color(1, 0.25, 0.25, 1)
			visual.scale = Vector2.ONE

func _get_desired_velocity(direction: Vector2, distance: float) -> Vector2:
	if enemy_type != "ranged":
		return direction * move_speed
	if distance < ranged_keep_distance:
		return -direction * move_speed
	if distance > ranged_attack_range:
		return direction * move_speed
	return Vector2.ZERO
