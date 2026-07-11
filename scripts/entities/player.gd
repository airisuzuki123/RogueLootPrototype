extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

@export var move_speed: float = 260.0
@export var max_health: int = 100
@export var fire_interval: float = 0.45
@export var projectile_damage: int = 10
@export var projectile_count: int = 1
@export var screen_margin: float = 16.0

var health: int
var fire_cooldown: float = 0.0
var base_fire_interval: float
var equipment_damage_bonus: int = 0
var equipment_attack_speed_bonus: int = 0
var equipment_health_bonus: int = 0

func _ready() -> void:
	health = max_health
	base_fire_interval = fire_interval
	sync_health_state()

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_upgrade_pending:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	_clamp_to_screen()
	_update_auto_attack(delta)

func take_damage(amount: int) -> void:
	if GameManager.is_run_over or GameManager.is_upgrade_pending:
		return
	health -= amount
	GameManager.update_player_health(max(health, 0), max_health)
	if health <= 0:
		GameManager.end_run()
		queue_free()

func sync_health_state() -> void:
	GameManager.update_player_health(health, max_health)

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"damage":
			projectile_damage += 5
		"attack_speed":
			base_fire_interval = max(0.18, base_fire_interval * 0.82)
			fire_interval = _calculate_fire_interval()
		"move_speed":
			move_speed += 35.0
		"max_health":
			max_health += 25
			health = min(max_health, health + 25)
			GameManager.update_player_health(health, max_health)
		"heal":
			health = min(max_health, health + 40)
			GameManager.update_player_health(health, max_health)
		"multishot":
			projectile_count += 1

func equip_weapon(new_weapon: Dictionary, old_weapon: Dictionary = {}) -> void:
	_remove_equipment_stats(old_weapon)
	_apply_equipment_stats(new_weapon)
	GameManager.update_player_health(health, max_health)

func _update_auto_attack(delta: float) -> void:
	fire_cooldown -= delta
	if fire_cooldown > 0.0:
		return
	var target := _find_nearest_enemy()
	if target == null:
		return
	fire_cooldown = fire_interval
	var base_direction := global_position.direction_to(target.global_position)
	for index in range(projectile_count):
		var projectile := PROJECTILE_SCENE.instantiate()
		var spread := deg_to_rad(8.0 * (index - (projectile_count - 1) / 2.0))
		projectile.global_position = global_position
		projectile.direction = base_direction.rotated(spread)
		projectile.damage = projectile_damage + equipment_damage_bonus
		get_tree().current_scene.add_child(projectile)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func _clamp_to_screen() -> void:
	var viewport_rect := get_viewport_rect()
	global_position.x = clampf(global_position.x, screen_margin, viewport_rect.size.x - screen_margin)
	global_position.y = clampf(global_position.y, screen_margin, viewport_rect.size.y - screen_margin)

func _apply_equipment_stats(equipment: Dictionary) -> void:
	for affix in equipment.get("affixes", []):
		match affix["id"]:
			"damage":
				equipment_damage_bonus += affix["value"]
			"attack_speed":
				equipment_attack_speed_bonus += affix["value"]
			"max_health":
				equipment_health_bonus += affix["value"]
				max_health += affix["value"]
				health += affix["value"]
	fire_interval = _calculate_fire_interval()

func _remove_equipment_stats(equipment: Dictionary) -> void:
	for affix in equipment.get("affixes", []):
		match affix["id"]:
			"damage":
				equipment_damage_bonus -= affix["value"]
			"attack_speed":
				equipment_attack_speed_bonus -= affix["value"]
			"max_health":
				equipment_health_bonus -= affix["value"]
				max_health -= affix["value"]
				health = min(health, max_health)
	fire_interval = _calculate_fire_interval()

func _calculate_fire_interval() -> float:
	var speed_multiplier := 1.0 + float(equipment_attack_speed_bonus) / 100.0
	return max(0.14, base_fire_interval / max(speed_multiplier, 0.1))
