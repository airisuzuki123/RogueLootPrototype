extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

@export var move_speed: float = 260.0
@export var max_health: int = 100
@export var fire_interval: float = 0.45
@export var projectile_damage: int = 10
@export var projectile_count: int = 1
@export var screen_margin: float = 10.0
@export var invulnerability_duration: float = 0.55
@export var knockback_recovery: float = 11.0

var health: int
var graze_shield: int = 0
var graze_shield_timer: float = 0.0
var movement_bounds: Rect2 = Rect2()
var fire_cooldown: float = 0.0
var invulnerability_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var base_fire_interval: float
var equipment_damage_bonus: int = 0
var equipment_attack_speed_bonus: int = 0
var equipment_health_bonus: int = 0
var equipment_move_speed_bonus: int = 0
var equipment_critical_chance_bonus: int = 0
var equipment_life_steal_bonus: int = 0
var equipment_gold_bonus: int = 0
var equipment_projectile_count_bonus: int = 0
var equipment_pierce_bonus: int = 0
var equipment_damage_multiplier: float = 1.0
var equipment_spread_degrees: float = 8.0
var equipment_explosion_radius: float = 0.0
var equipment_explosion_damage_ratio: float = 0.0
var affix_projectile_count_bonus: int = 0
var affix_pierce_bonus: int = 0
var affix_explosion_radius_bonus: float = 0.0
var upgrade_pierce_bonus: int = 0
var upgrade_explosion_radius_bonus: float = 0.0
@onready var visual: Polygon2D = $Visual
@onready var hit_core: Polygon2D = $HitCore

func _ready() -> void:
	health = max_health
	base_fire_interval = fire_interval
	sync_health_state()

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	_update_invulnerability(delta)
	_update_graze_shield(delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed + knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_recovery * knockback_velocity.length() * delta)
	_clamp_to_movement_bounds()
	_update_auto_attack(delta)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused() or invulnerability_timer > 0.0:
		return
	invulnerability_timer = invulnerability_duration
	knockback_velocity += knockback
	var remaining_damage := _absorb_damage_with_graze_shield(maxi(0, amount))
	if remaining_damage <= 0:
		return
	health -= remaining_damage
	GameManager.update_player_health(max(health, 0), max_health)
	CombatFeedback.show_damage(get_tree().current_scene, global_position, remaining_damage, Color(1, 0.25, 0.25, 1))
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.2, 0.2, 0.9), 1.3)
	if health <= 0:
		GameManager.end_run()
		queue_free()

func sync_health_state() -> void:
	GameManager.update_player_health(health, max_health)
	GameManager.update_player_graze_shield(graze_shield, graze_shield_timer)

func set_movement_bounds(bounds: Rect2) -> void:
	movement_bounds = bounds
	_clamp_to_movement_bounds()

func heal_fixed_amount(amount: int) -> int:
	if amount <= 0 or health <= 0 or health >= max_health:
		return 0
	var old_health := health
	health = min(max_health, health + amount)
	GameManager.update_player_health(health, max_health)
	return health - old_health

func apply_graze_shield(amount: int, duration: float) -> void:
	if amount <= 0 or duration <= 0.0 or health <= 0:
		return
	graze_shield = maxi(graze_shield, amount)
	graze_shield_timer = maxf(graze_shield_timer, duration)
	_sync_graze_shield_state()

func take_event_damage(amount: int) -> int:
	if GameManager.is_run_over or amount <= 0 or health <= 0:
		return 0
	var old_health := health
	health = max(0, health - amount)
	GameManager.update_player_health(health, max_health)
	CombatFeedback.show_damage(get_tree().current_scene, global_position, old_health - health, Color(1, 0.25, 0.25, 1))
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.2, 0.2, 0.9), 1.2)
	if health <= 0:
		GameManager.end_run()
		queue_free()
	return old_health - health

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
		"strong_heal":
			health = min(max_health, health + 70)
			GameManager.update_player_health(health, max_health)
		"recovery_training":
			max_health += 12
			health = min(max_health, health + 45)
			GameManager.update_player_health(health, max_health)
		"multishot":
			projectile_count += 1
		"form_focused":
			projectile_damage += 8
		"form_scatter":
			projectile_count += 1
		"form_piercing":
			upgrade_pierce_bonus += 1
		"form_burst":
			upgrade_explosion_radius_bonus += 28.0

func equip_weapon(new_weapon: Dictionary, old_weapon: Dictionary = {}) -> void:
	equip_item(new_weapon, old_weapon)

func equip_item(new_item: Dictionary, old_item: Dictionary = {}) -> void:
	if not old_item.is_empty():
		_remove_equipment_stats(old_item)
	if not new_item.is_empty():
		_apply_equipment_stats(new_item)
	GameManager.update_player_health(health, max_health)

func heal_from_life_steal(hit_damage: int) -> void:
	if equipment_life_steal_bonus <= 0 or health <= 0 or health >= max_health:
		return
	var heal_amount: int = max(1, int(round(float(hit_damage) * float(equipment_life_steal_bonus) / 100.0)))
	health = min(max_health, health + heal_amount)
	GameManager.update_player_health(health, max_health)

func get_gold_bonus_percent() -> int:
	return equipment_gold_bonus

func _update_auto_attack(delta: float) -> void:
	fire_cooldown -= delta
	if fire_cooldown > 0.0:
		return
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return
	fire_cooldown = fire_interval
	var base_direction: Vector2 = global_position.direction_to(target.global_position)
	var total_projectiles: int = maxi(1, projectile_count + equipment_projectile_count_bonus + affix_projectile_count_bonus)
	for index in range(total_projectiles):
		var projectile := PROJECTILE_SCENE.instantiate()
		var spread: float = deg_to_rad(equipment_spread_degrees * (index - (total_projectiles - 1) / 2.0))
		projectile.global_position = global_position
		projectile.direction = base_direction.rotated(spread)
		projectile.damage = _roll_projectile_damage()
		projectile.is_critical = projectile.damage > _get_base_projectile_damage()
		projectile.pierce_remaining = equipment_pierce_bonus + affix_pierce_bonus + upgrade_pierce_bonus
		projectile.explosion_radius = _get_total_explosion_radius()
		projectile.explosion_damage = int(round(float(projectile.damage) * _get_total_explosion_damage_ratio()))
		projectile.source_player = self
		projectile.life_steal_percent = equipment_life_steal_bonus
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

func _clamp_to_movement_bounds() -> void:
	var bounds := movement_bounds
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		var viewport_rect := get_viewport_rect()
		bounds = Rect2(Vector2.ZERO, viewport_rect.size)
	global_position.x = clampf(global_position.x, bounds.position.x + screen_margin, bounds.end.x - screen_margin)
	global_position.y = clampf(global_position.y, bounds.position.y + screen_margin, bounds.end.y - screen_margin)

func _apply_equipment_stats(equipment: Dictionary) -> void:
	if str(equipment.get("slot", "weapon")) == "weapon":
		_apply_weapon_form(equipment.get("form", {}))
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
			"move_speed":
				equipment_move_speed_bonus += affix["value"]
				move_speed += affix["value"]
			"critical_chance":
				equipment_critical_chance_bonus += affix["value"]
			"life_steal":
				equipment_life_steal_bonus += affix["value"]
			"gold_bonus":
				equipment_gold_bonus += affix["value"]
			"projectile_count":
				affix_projectile_count_bonus += affix["value"]
			"pierce":
				affix_pierce_bonus += affix["value"]
			"explosion_radius":
				affix_explosion_radius_bonus += affix["value"]
	fire_interval = _calculate_fire_interval()

func _remove_equipment_stats(equipment: Dictionary) -> void:
	if str(equipment.get("slot", "weapon")) == "weapon":
		_reset_weapon_form()
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
			"move_speed":
				equipment_move_speed_bonus -= affix["value"]
				move_speed -= affix["value"]
			"critical_chance":
				equipment_critical_chance_bonus -= affix["value"]
			"life_steal":
				equipment_life_steal_bonus -= affix["value"]
			"gold_bonus":
				equipment_gold_bonus -= affix["value"]
			"projectile_count":
				affix_projectile_count_bonus -= affix["value"]
			"pierce":
				affix_pierce_bonus -= affix["value"]
			"explosion_radius":
				affix_explosion_radius_bonus -= affix["value"]
	fire_interval = _calculate_fire_interval()

func _calculate_fire_interval() -> float:
	var speed_multiplier := 1.0 + float(equipment_attack_speed_bonus) / 100.0
	return max(0.14, base_fire_interval / max(speed_multiplier, 0.1))

func _get_base_projectile_damage() -> int:
	return max(1, int(round(float(projectile_damage + equipment_damage_bonus) * equipment_damage_multiplier)))

func _roll_projectile_damage() -> int:
	var damage := _get_base_projectile_damage()
	var critical_chance := clampf(float(equipment_critical_chance_bonus) / 100.0, 0.0, 0.75)
	if randf() < critical_chance:
		return damage * 2
	return damage

func _get_total_explosion_radius() -> float:
	return equipment_explosion_radius + affix_explosion_radius_bonus + upgrade_explosion_radius_bonus

func _get_total_explosion_damage_ratio() -> float:
	var total_radius := _get_total_explosion_radius()
	if total_radius <= 0.0:
		return 0.0
	var ratio := equipment_explosion_damage_ratio
	if affix_explosion_radius_bonus > 0.0 or upgrade_explosion_radius_bonus > 0.0:
		ratio = maxf(ratio, 0.25)
		if equipment_explosion_damage_ratio > 0.0:
			ratio += 0.08
	return minf(ratio, 0.65)

func _apply_weapon_form(form: Dictionary) -> void:
	if form.is_empty():
		_reset_weapon_form()
		return
	equipment_projectile_count_bonus = int(form.get("projectile_bonus", 0))
	equipment_pierce_bonus = int(form.get("pierce", 0))
	equipment_damage_multiplier = float(form.get("damage_multiplier", 1.0))
	equipment_spread_degrees = float(form.get("spread_degrees", 8.0))
	equipment_explosion_radius = float(form.get("explosion_radius", 0.0))
	equipment_explosion_damage_ratio = float(form.get("explosion_damage_ratio", 0.0))

func _reset_weapon_form() -> void:
	equipment_projectile_count_bonus = 0
	equipment_pierce_bonus = 0
	equipment_damage_multiplier = 1.0
	equipment_spread_degrees = 8.0
	equipment_explosion_radius = 0.0
	equipment_explosion_damage_ratio = 0.0

func _update_invulnerability(delta: float) -> void:
	if invulnerability_timer <= 0.0:
		visual.modulate.a = 1.0
		hit_core.modulate = Color.WHITE
		return
	invulnerability_timer -= delta
	visual.modulate.a = 0.35 if int(invulnerability_timer * 20.0) % 2 == 0 else 1.0
	hit_core.modulate = Color(1.0, 0.95, 0.35, 1.0)

func _update_graze_shield(delta: float) -> void:
	if graze_shield <= 0:
		return
	graze_shield_timer -= delta
	if graze_shield_timer > 0.0:
		GameManager.update_player_graze_shield(graze_shield, graze_shield_timer, false)
		return
	graze_shield = 0
	graze_shield_timer = 0.0
	_sync_graze_shield_state()

func _absorb_damage_with_graze_shield(incoming_damage: int) -> int:
	if incoming_damage <= 0 or graze_shield <= 0:
		return incoming_damage
	var absorbed := mini(graze_shield, incoming_damage)
	graze_shield -= absorbed
	var remaining_damage := incoming_damage - absorbed
	if graze_shield <= 0:
		graze_shield = 0
		graze_shield_timer = 0.0
	_sync_graze_shield_state()
	CombatFeedback.show_damage(get_tree().current_scene, global_position, absorbed, Color(0.45, 0.9, 1.0, 1.0))
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.35, 0.85, 1.0, 0.75), 1.0)
	return remaining_damage

func _sync_graze_shield_state() -> void:
	GameManager.update_player_graze_shield(graze_shield, graze_shield_timer)
