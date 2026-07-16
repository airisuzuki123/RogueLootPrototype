extends CharacterBody2D

const LOOT_DROP_SCENE := preload("res://scenes/loot_drop.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemy_projectile.tscn")
const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")
const LootDrop := preload("res://scripts/items/loot_drop.gd")

@export var move_speed: float = 120.0
@export var max_health: int = 20
@export var touch_damage: int = 10
@export var loot_chance: float = 0.26
@export var experience_reward: int = 1
@export var attack_interval: float = 0.8
@export var knockback_recovery: float = 9.0
@export var enemy_type: String = "grunt"
@export var arena_margin: float = 12.0
@export var ranged_attack_range: float = 260.0
@export var ranged_keep_distance: float = 170.0
@export var projectile_speed: float = 240.0

var health: int
var target: Node2D
var movement_bounds: Rect2 = Rect2()
var attack_cooldown: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var spiral_angle: float = 0.0
var sweep_angle: float = 0.0
var strafe_direction: float = 1.0
var strafe_timer: float = 0.0
var encounter_config: Dictionary = {}
var encounter_id: String = ""
var is_encounter_enemy: bool = false
var force_health_bar_visible: bool = false
var encounter_pattern_counter: int = 0
var encounter_base_attack_interval: float = 0.8
var encounter_base_projectile_speed: float = 240.0
var knockback_resistance: float = 1.0
var active_boss_phase_index: int = -1
var active_boss_phase: Dictionary = {}
@onready var visual: Polygon2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	_apply_enemy_type(enemy_type)
	_apply_encounter_config()
	health = max_health
	_update_health_bar(false)
	add_to_group("enemies")
	if is_encounter_enemy:
		add_to_group("encounter_enemies")

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	attack_cooldown -= delta
	_update_strafe(delta)
	if target == null or not is_instance_valid(target):
		return
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var direction := to_target.normalized()
	velocity = _get_desired_velocity(direction, distance) + knockback_velocity
	move_and_slide()
	_clamp_to_movement_bounds()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_recovery * knockback_velocity.length() * delta)
	if _is_bullet_enemy() and distance <= ranged_attack_range:
		_try_ranged_attack(direction)
	elif distance <= 24.0:
		_try_touch_damage()

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, is_critical: bool = false) -> void:
	if GameManager.is_run_over:
		return
	health -= amount
	knockback_velocity += knockback / maxf(0.1, knockback_resistance)
	_update_boss_phase()
	_update_health_bar(true)
	_flash_on_hit()
	var damage_color := Color(1, 0.45, 0.15, 1) if is_critical else Color(1, 0.95, 0.45, 1)
	var burst_size := 1.2 if is_critical else 0.8
	CombatFeedback.show_damage(get_tree().current_scene, global_position, amount, damage_color)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.8, 0.15, 0.85), burst_size)
	if health <= 0:
		_die()

func _die() -> void:
	GameManager.register_kill()
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.35, 0.25, 0.95), 1.6)
	GameManager.add_experience(experience_reward)
	if is_encounter_enemy:
		GameManager.complete_encounter(encounter_id)
		queue_free()
		return
	if randf() <= loot_chance:
		_drop_loot_or_gold()
	queue_free()

func _drop_loot_or_gold() -> void:
	var equipment_drop_chance := LootDrop.get_scaled_equipment_chance_for_level(GameManager.level)
	if randf() <= equipment_drop_chance:
		var loot := LOOT_DROP_SCENE.instantiate()
		loot.global_position = global_position + _get_random_drop_offset()
		loot.source_level = GameManager.level
		loot.equipment_only = true
		get_tree().current_scene.add_child(loot)
	else:
		GameManager.add_gold(_get_scaled_gold_amount())

func _get_scaled_gold_amount() -> int:
	return 1 + int(floor(float(maxi(0, GameManager.level - 1)) / 3.0))

func _get_random_drop_offset() -> Vector2:
	return Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, 16.0)

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
	match _select_bullet_pattern():
		"aimed_burst":
			_fire_aimed_burst_pattern(direction)
		"fan":
			_fire_fan_pattern(direction)
		"ring":
			_fire_ring_pattern()
		"cross":
			_fire_cross_pattern(direction)
		"spiral":
			_fire_spiral_pattern()
		"sweep":
			_fire_sweep_pattern(direction)
		"double_ring":
			_fire_double_ring_pattern()
		"pinwheel":
			_fire_pinwheel_pattern()
		"wall":
			_fire_wall_pattern(direction)
		"flower":
			_fire_flower_pattern()
		_:
			_fire_aimed_pattern(direction)

func _flash_on_hit() -> void:
	visual.modulate = Color(1.6, 1.6, 1.6, 1)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.08)

func _update_health_bar(show_when_damaged: bool) -> void:
	health_bar.max_value = max_health
	health_bar.value = clampi(health, 0, max_health)
	health_bar.visible = (force_health_bar_visible or show_when_damaged) and health > 0

func configure(type_id: String) -> void:
	enemy_type = type_id

func configure_encounter(encounter: Dictionary) -> void:
	encounter_config = encounter.duplicate(true)
	encounter_id = str(encounter_config.get("id", ""))
	is_encounter_enemy = not encounter_id.is_empty()
	force_health_bar_visible = is_encounter_enemy
	if is_inside_tree():
		_apply_enemy_type(enemy_type)
		_apply_encounter_config()
		health = max_health
		_update_boss_phase()
		_update_health_bar(false)

func set_movement_bounds(bounds: Rect2) -> void:
	movement_bounds = bounds
	_clamp_to_movement_bounds()

func _apply_enemy_type(type_id: String) -> void:
	knockback_resistance = 1.0
	match type_id:
		"runner":
			max_health = 12
			move_speed = 175.0
			touch_damage = 7
			experience_reward = 1
			visual.color = Color(1, 0.55, 0.2, 1)
			visual.scale = Vector2(0.85, 0.85)
			knockback_resistance = 0.75
		"tank":
			max_health = 55
			move_speed = 75.0
			touch_damage = 16
			experience_reward = 3
			loot_chance = 0.38
			visual.color = Color(0.75, 0.15, 1, 1)
			visual.scale = Vector2(1.35, 1.35)
			knockback_resistance = 1.75
		"ranged":
			max_health = 22
			move_speed = 95.0
			touch_damage = 7
			attack_interval = 1.45
			projectile_speed = 230.0
			experience_reward = 2
			loot_chance = 0.30
			visual.color = Color(0.15, 0.85, 1.0, 1)
			visual.scale = Vector2(1.0, 1.0)
			knockback_resistance = 1.0
		"weaver":
			max_health = 20
			move_speed = 128.0
			touch_damage = 6
			attack_interval = 1.25
			projectile_speed = 255.0
			ranged_attack_range = 330.0
			ranged_keep_distance = 210.0
			experience_reward = 2
			loot_chance = 0.28
			visual.color = Color(0.45, 0.45, 1.0, 1)
			visual.scale = Vector2(0.95, 0.95)
			knockback_resistance = 0.9
		"turret":
			max_health = 34
			move_speed = 38.0
			touch_damage = 9
			attack_interval = 1.75
			projectile_speed = 210.0
			ranged_attack_range = 430.0
			ranged_keep_distance = 280.0
			experience_reward = 3
			loot_chance = 0.34
			visual.color = Color(1.0, 0.30, 0.95, 1)
			visual.scale = Vector2(1.15, 1.15)
			knockback_resistance = 1.35
		_:
			enemy_type = "grunt"
			max_health = 20
			move_speed = 120.0
			touch_damage = 10
			experience_reward = 1
			visual.color = Color(1, 0.25, 0.25, 1)
			visual.scale = Vector2.ONE
			knockback_resistance = 1.0

func _apply_encounter_config() -> void:
	if encounter_config.is_empty():
		return
	encounter_id = str(encounter_config.get("id", ""))
	is_encounter_enemy = not encounter_id.is_empty()
	force_health_bar_visible = is_encounter_enemy
	max_health = maxi(1, int(round(float(max_health) * float(encounter_config.get("health_multiplier", 1.0)))) + int(encounter_config.get("health_bonus", 0)))
	touch_damage = maxi(1, int(round(float(touch_damage) * float(encounter_config.get("touch_damage_multiplier", 1.0)))) + int(encounter_config.get("touch_damage_bonus", 0)))
	move_speed *= float(encounter_config.get("move_speed_multiplier", 1.0))
	attack_interval = maxf(0.18, attack_interval * float(encounter_config.get("attack_interval_multiplier", 1.0)))
	projectile_speed *= float(encounter_config.get("projectile_speed_multiplier", 1.0))
	encounter_base_attack_interval = attack_interval
	encounter_base_projectile_speed = projectile_speed
	ranged_attack_range += float(encounter_config.get("ranged_attack_range_bonus", 0.0))
	ranged_keep_distance += float(encounter_config.get("ranged_keep_distance_bonus", 0.0))
	experience_reward += maxi(0, int(encounter_config.get("extra_experience_reward", 0)))
	loot_chance = 0.0
	visual.scale *= float(encounter_config.get("visual_scale", 1.0))
	knockback_resistance *= maxf(0.1, float(encounter_config.get("visual_scale", 1.0)))
	visual.color = encounter_config.get("color", visual.color)
	z_index = 2

func _update_boss_phase() -> void:
	if not is_encounter_enemy or health <= 0:
		return
	var phases: Array = encounter_config.get("boss_phases", [])
	if phases.is_empty():
		return
	var health_ratio := float(health) / float(maxi(1, max_health))
	var target_phase_index := -1
	for index in range(phases.size()):
		var phase: Dictionary = phases[index]
		if health_ratio <= float(phase.get("threshold", 0.0)):
			target_phase_index = index
			break
	if target_phase_index <= active_boss_phase_index:
		return
	active_boss_phase_index = target_phase_index
	active_boss_phase = phases[target_phase_index].duplicate(true)
	attack_interval = maxf(0.16, encounter_base_attack_interval * float(active_boss_phase.get("attack_interval_multiplier", 1.0)))
	projectile_speed = encounter_base_projectile_speed * float(active_boss_phase.get("projectile_speed_multiplier", 1.0))
	visual.color = active_boss_phase.get("color", visual.color)
	encounter_pattern_counter = 0
	var message := str(active_boss_phase.get("message", active_boss_phase.get("title", "Boss 阶段变化")))
	if not message.is_empty() and GameManager.has_method("show_milestone_message"):
		GameManager.show_milestone_message(message)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, visual.color, float(active_boss_phase.get("burst_scale", 1.6)))

func _get_desired_velocity(direction: Vector2, distance: float) -> Vector2:
	if not _is_bullet_enemy():
		return direction * move_speed
	if enemy_type == "turret":
		if distance < ranged_keep_distance:
			return -direction * move_speed
		if distance > ranged_attack_range * 0.72:
			return direction * move_speed * 0.55
		return Vector2.ZERO
	if enemy_type == "weaver" and distance <= ranged_attack_range:
		var side := direction.orthogonal().normalized() * strafe_direction * move_speed * 0.58
		if distance < ranged_keep_distance:
			return -direction * move_speed * 0.65 + side
		if distance > ranged_attack_range * 0.82:
			return direction * move_speed * 0.45 + side
		return side
	if distance < ranged_keep_distance:
		return -direction * move_speed
	if distance > ranged_attack_range:
		return direction * move_speed
	return Vector2.ZERO

func _clamp_to_movement_bounds() -> void:
	if movement_bounds.size.x <= 0.0 or movement_bounds.size.y <= 0.0:
		return
	global_position.x = clampf(global_position.x, movement_bounds.position.x + arena_margin, movement_bounds.end.x - arena_margin)
	global_position.y = clampf(global_position.y, movement_bounds.position.y + arena_margin, movement_bounds.end.y - arena_margin)

func _is_bullet_enemy() -> bool:
	return enemy_type == "ranged" or enemy_type == "weaver" or enemy_type == "turret"

func _update_strafe(delta: float) -> void:
	if enemy_type != "weaver":
		return
	strafe_timer -= delta
	if strafe_timer > 0.0:
		return
	strafe_timer = randf_range(1.1, 1.9)
	strafe_direction *= -1.0

func _select_bullet_pattern() -> String:
	var boss_phase_patterns: Array = active_boss_phase.get("bullet_patterns", [])
	if not boss_phase_patterns.is_empty():
		var phase_pattern := str(boss_phase_patterns[encounter_pattern_counter % boss_phase_patterns.size()])
		encounter_pattern_counter += 1
		return phase_pattern
	var encounter_patterns: Array = encounter_config.get("bullet_patterns", [])
	if not encounter_patterns.is_empty():
		var pattern := str(encounter_patterns[encounter_pattern_counter % encounter_patterns.size()])
		encounter_pattern_counter += 1
		return pattern
	return GameManager.get_current_phase_bullet_pattern_for_enemy(enemy_type)

func _fire_aimed_pattern(direction: Vector2) -> void:
	_spawn_enemy_projectile(direction, Vector2.ZERO, Color(1.0, 0.48, 0.22, 1.0), 1.0)
	_show_ranged_burst(Color(1.0, 0.55, 0.25, 0.75), 0.75)

func _fire_aimed_burst_pattern(direction: Vector2) -> void:
	var side := direction.orthogonal().normalized()
	for index in range(3):
		var offset := side * (float(index) - 1.0) * 12.0
		var angle := deg_to_rad((float(index) - 1.0) * 5.0)
		_spawn_enemy_projectile(direction.rotated(angle), offset, Color(1.0, 0.62, 0.28, 1.0), 0.92, 1.08)
	_show_ranged_burst(Color(1.0, 0.58, 0.2, 0.82), 0.9)

func _fire_fan_pattern(direction: Vector2) -> void:
	var bullet_count := 5
	var spread_degrees := 52.0
	for index in range(bullet_count):
		var t := 0.0 if bullet_count <= 1 else float(index) / float(bullet_count - 1)
		var angle := deg_to_rad(lerpf(-spread_degrees * 0.5, spread_degrees * 0.5, t))
		_spawn_enemy_projectile(direction.rotated(angle), Vector2.ZERO, Color(0.35, 0.95, 1.0, 1.0), 0.92)
	_show_ranged_burst(Color(0.25, 0.85, 1.0, 0.82), 0.95)

func _fire_ring_pattern() -> void:
	var bullet_count := 12
	var offset := randf() * TAU
	for index in range(bullet_count):
		var angle := offset + TAU * float(index) / float(bullet_count)
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, Color(1.0, 0.42, 0.95, 1.0), 0.86)
	_show_ranged_burst(Color(1.0, 0.35, 0.9, 0.85), 1.2)

func _fire_cross_pattern(direction: Vector2) -> void:
	var base_angle := direction.angle()
	for index in range(4):
		var angle := base_angle + TAU * float(index) / 4.0
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, Color(0.5, 1.0, 0.65, 1.0), 0.9, 1.0)
	for index in range(4):
		var angle := base_angle + deg_to_rad(45.0) + TAU * float(index) / 4.0
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, Color(0.28, 0.82, 1.0, 1.0), 0.78, 0.78)
	_show_ranged_burst(Color(0.35, 1.0, 0.75, 0.85), 1.05)

func _fire_spiral_pattern() -> void:
	var bullet_count := 7
	spiral_angle = wrapf(spiral_angle + deg_to_rad(34.0), 0.0, TAU)
	for index in range(bullet_count):
		var angle := spiral_angle + TAU * float(index) / float(bullet_count)
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, Color(1.0, 0.86, 0.28, 1.0), 0.84)
	_show_ranged_burst(Color(1.0, 0.75, 0.22, 0.86), 1.15)

func _fire_sweep_pattern(direction: Vector2) -> void:
	var bullet_count := 6
	var spread_degrees := 64.0
	sweep_angle = wrapf(sweep_angle + deg_to_rad(18.0), -PI, PI)
	var base_direction := direction.rotated(sin(sweep_angle) * deg_to_rad(22.0))
	for index in range(bullet_count):
		var t := 0.0 if bullet_count <= 1 else float(index) / float(bullet_count - 1)
		var angle := deg_to_rad(lerpf(-spread_degrees * 0.5, spread_degrees * 0.5, t))
		var color := Color(0.35, 1.0, 0.92, 1.0) if index % 2 == 0 else Color(0.78, 0.55, 1.0, 1.0)
		_spawn_enemy_projectile(base_direction.rotated(angle), Vector2.ZERO, color, 0.82, 0.95)
	_show_ranged_burst(Color(0.45, 0.9, 1.0, 0.86), 1.1)

func _fire_double_ring_pattern() -> void:
	var bullet_count := 10
	var offset := randf() * TAU
	for index in range(bullet_count):
		var angle := offset + TAU * float(index) / float(bullet_count)
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, Color(1.0, 0.34, 0.72, 1.0), 0.78, 0.82)
	for index in range(bullet_count):
		var angle := offset + PI / float(bullet_count) + TAU * float(index) / float(bullet_count)
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, Color(0.45, 0.88, 1.0, 1.0), 0.92, 1.12)
	_show_ranged_burst(Color(0.95, 0.45, 1.0, 0.88), 1.3)

func _fire_pinwheel_pattern() -> void:
	var bullet_count := 8
	spiral_angle = wrapf(spiral_angle + deg_to_rad(27.0), 0.0, TAU)
	for index in range(bullet_count):
		var angle := spiral_angle + TAU * float(index) / float(bullet_count)
		var is_primary := index % 2 == 0
		var color := Color(1.0, 0.38, 0.85, 1.0) if is_primary else Color(0.38, 0.92, 1.0, 1.0)
		var scale_multiplier := 0.9 if is_primary else 0.72
		var speed_scale := 1.05 if is_primary else 0.82
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, color, scale_multiplier, speed_scale)
	_show_ranged_burst(Color(0.9, 0.5, 1.0, 0.9), 1.25)

func _fire_wall_pattern(direction: Vector2) -> void:
	var bullet_count := 7
	var spacing := 22.0
	var side := direction.orthogonal().normalized()
	for index in range(bullet_count):
		var offset := side * (float(index) - float(bullet_count - 1) * 0.5) * spacing
		_spawn_enemy_projectile(direction, offset, Color(0.55, 0.72, 1.0, 1.0), 0.95)
	_show_ranged_burst(Color(0.4, 0.62, 1.0, 0.88), 1.25)

func _fire_flower_pattern() -> void:
	var bullet_count := 16
	var offset := randf() * TAU
	for index in range(bullet_count):
		var angle := offset + TAU * float(index) / float(bullet_count)
		var is_outer := index % 2 == 0
		var color := Color(1.0, 0.45, 0.95, 1.0) if is_outer else Color(1.0, 0.92, 0.35, 1.0)
		var scale_multiplier := 0.92 if is_outer else 0.72
		var speed_scale := 1.08 if is_outer else 0.72
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), Vector2.ZERO, color, scale_multiplier, speed_scale)
	_show_ranged_burst(Color(1.0, 0.55, 0.95, 0.9), 1.4)

func _spawn_enemy_projectile(direction: Vector2, offset: Vector2, color: Color, scale_multiplier: float, speed_scale: float = 1.0) -> void:
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position + offset
	var speed_multiplier := GameManager.get_current_phase_bullet_speed_multiplier()
	if projectile.has_method("configure"):
		projectile.configure(direction, touch_damage, projectile_speed * speed_multiplier * speed_scale, color, scale_multiplier)
	else:
		projectile.direction = direction
		projectile.damage = touch_damage
	get_tree().current_scene.add_child(projectile)

func _show_ranged_burst(color: Color, size: float) -> void:
	CombatFeedback.show_burst(get_tree().current_scene, global_position, color, size)
