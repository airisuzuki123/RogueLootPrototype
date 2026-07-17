extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")
const PLAYER_SIZE_BONUS_CAP := 2.40
const MIN_TRADEOFF_MOVE_SPEED := 80.0
const MULTISHOT_SIZE_BONUS := 0.20
const MULTISHOT_SPEED_MULTIPLIER := 0.82
const BLAST_CORE_SIZE_BONUS := 0.10
const HEAVY_SHOT_SIZE_BONUS := 0.06
const MASS_DAMAGE_PER_10_PERCENT := 0.06
const SLOW_DAMAGE_PER_10_PERCENT := 0.08
const STILL_FOCUS_INTERVAL := 0.70
const STILL_FOCUS_CRIT_PER_TIER := 8
const STILL_FOCUS_MAX_TIER := 12

@export var move_speed: float = 260.0
@export var max_health: int = 100
@export var fire_interval: float = 0.45
@export var projectile_damage: int = 10
@export var projectile_count: int = 1
@export var screen_margin: float = 10.0
@export var invulnerability_duration: float = 0.55
@export var knockback_recovery: float = 11.0

var health: int
var base_move_speed: float = 260.0
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
var upgrade_damage_bonus: int = 0
var upgrade_attack_speed_stacks: int = 0
var upgrade_projectile_count_bonus: int = 0
var upgrade_pierce_bonus: int = 0
var upgrade_explosion_radius_bonus: float = 0.0
var upgrade_player_size_bonus: float = 0.0
var mass_resonance_stacks: int = 0
var slow_resonance_stacks: int = 0
var still_focus_stacks: int = 0
var chain_spark_stacks: int = 0
var orbit_blade_stacks: int = 0
var overload_burst_stacks: int = 0
var homing_shard_stacks: int = 0
var heavy_shot_stacks: int = 0
var close_slash_stacks: int = 0
var pulse_field_stacks: int = 0
var channel_beam_stacks: int = 0
var shatter_blast_stacks: int = 0
var pierce_amp_stacks: int = 0
var conduit_coil_stacks: int = 0
var guard_blade_stacks: int = 0
var attack_sequence: int = 0
var close_slash_cooldown: float = 0.0
var pulse_field_cooldown: float = 0.0
var channel_beam_tick_timer: float = 0.0
var stationary_focus_time: float = 0.0
var last_stationary_focus_tier: int = 0
var upgrade_stacks := {}
@onready var visual: Polygon2D = $Visual
@onready var hit_core: Polygon2D = $HitCore

func _ready() -> void:
	health = max_health
	base_move_speed = move_speed
	base_fire_interval = fire_interval
	sync_health_state()

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	_update_invulnerability(delta)
	_update_graze_shield(delta)
	_update_close_range_skills(delta)
	_update_channel_skill(delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_update_motion_focus(delta, direction)
	_update_player_body_scale()
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
	_emit_build_summary()

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
	graze_shield += amount
	graze_shield_timer = maxf(graze_shield_timer, duration)
	_sync_graze_shield_state()
	_emit_build_summary()

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

func apply_upgrade(upgrade_id: String) -> Dictionary:
	_add_upgrade_stack(upgrade_id)
	var result: Dictionary = {}
	match upgrade_id:
		"damage":
			upgrade_damage_bonus += 5
			projectile_damage += 5
			result["damage_bonus"] = 5
		"attack_speed":
			upgrade_attack_speed_stacks += 1
			base_fire_interval = max(0.06, base_fire_interval * 0.82)
			fire_interval = _calculate_fire_interval()
			result["attack_speed_percent"] = 18
		"move_speed":
			move_speed += 35.0
			result["move_speed_bonus"] = 35
		"max_health":
			max_health += 25
			result["heal"] = _heal_after_upgrade(25)
			GameManager.update_player_health(health, max_health)
			result["max_health_bonus"] = 25
		"heal":
			result["heal"] = _heal_after_upgrade(40)
			GameManager.update_player_health(health, max_health)
		"strong_heal":
			result["heal"] = _heal_after_upgrade(70)
			GameManager.update_player_health(health, max_health)
		"recovery_training":
			max_health += 12
			result["heal"] = _heal_after_upgrade(45)
			GameManager.update_player_health(health, max_health)
			result["max_health_bonus"] = 12
		"multishot":
			upgrade_projectile_count_bonus += 1
			projectile_count += 1
			var multishot_old_size_bonus := upgrade_player_size_bonus
			var multishot_old_move_speed := move_speed
			upgrade_player_size_bonus = minf(PLAYER_SIZE_BONUS_CAP, upgrade_player_size_bonus + MULTISHOT_SIZE_BONUS)
			move_speed = maxf(MIN_TRADEOFF_MOVE_SPEED, move_speed * MULTISHOT_SPEED_MULTIPLIER)
			var multishot_applied_size_percent := int(round((upgrade_player_size_bonus - multishot_old_size_bonus) * 100.0))
			var multishot_applied_slow_percent := 0
			if multishot_old_move_speed > 0.0:
				multishot_applied_slow_percent = int(round((multishot_old_move_speed - move_speed) / multishot_old_move_speed * 100.0))
			result["skill_text"] = "投射物 +1，玩家体积 +%d%%（最高 +240%%），当前移速 -%d%%（最低 80）" % [multishot_applied_size_percent, multishot_applied_slow_percent]
		"mass_resonance":
			mass_resonance_stacks += 1
			result["skill_text"] = "玩家体积每 +10%%，投射物伤害 +6%%，无层数上限，当前 %d 层" % mass_resonance_stacks
		"slow_resonance":
			slow_resonance_stacks += 1
			result["skill_text"] = "移速每低于初始值 10%%，投射物伤害 +8%%，无层数上限，当前 %d 层" % slow_resonance_stacks
		"still_focus":
			still_focus_stacks += 1
			result["skill_text"] = "静止每 0.7 秒暴击率 +8%%，最多 12 层专注，当前技能 %d 层" % still_focus_stacks
		"piercing_rounds":
			upgrade_pierce_bonus += 1
			result["skill_text"] = "穿透 +1"
		"blast_core":
			upgrade_explosion_radius_bonus += 36.0
			var blast_old_size_bonus := upgrade_player_size_bonus
			upgrade_player_size_bonus = minf(PLAYER_SIZE_BONUS_CAP, upgrade_player_size_bonus + BLAST_CORE_SIZE_BONUS)
			var blast_applied_size_percent := int(round((upgrade_player_size_bonus - blast_old_size_bonus) * 100.0))
			result["explosion_radius"] = 36
			result["skill_text"] = "爆裂 +36，玩家体积 +%d%%（最高 +240%%）" % blast_applied_size_percent
		"graze_barrier":
			apply_graze_shield(22, 4.0)
			result["shield"] = 22
			result["shield_duration"] = 4.0
		"clear_barrier":
			result["cleared_projectiles"] = GameManager.clear_enemy_projectiles_from_upgrade()
			apply_graze_shield(16, 3.5)
			result["shield"] = 16
			result["shield_duration"] = 3.5
			CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.38, 0.92, 1.0, 0.82), 1.8)
		"pulse_nova":
			upgrade_explosion_radius_bonus += 18.0
			result["explosion_radius"] = 18
			result["nova_projectiles"] = _fire_upgrade_nova()
		"charged_volley":
			upgrade_damage_bonus += 3
			projectile_damage += 3
			result["damage_bonus"] = 3
			result["volley_projectiles"] = _fire_charged_volley()
		"chain_spark":
			chain_spark_stacks += 1
			result["skill_text"] = "连锁弹 %d 枚/次攻击，单枚伤害 %d%%" % [
				chain_spark_stacks,
				int(round((0.66 + float(maxi(0, chain_spark_stacks - 1)) * 0.06) * 100.0))
			]
		"orbit_blade":
			orbit_blade_stacks += 1
			result["skill_text"] = "两侧回旋弹各 %d 枚/次攻击，单枚伤害 %d%%" % [
				orbit_blade_stacks,
				int(round((0.54 + float(maxi(0, orbit_blade_stacks - 1)) * 0.08) * 100.0))
			]
		"overload_burst":
			overload_burst_stacks += 1
			result["skill_text"] = "每 4 次攻击释放 %d 枚爆裂弹，单枚伤害 %d%%" % [
				6 + overload_burst_stacks * 2,
				int(round((0.50 + float(overload_burst_stacks) * 0.08) * 100.0))
			]
		"homing_shards":
			homing_shard_stacks += 1
			result["skill_text"] = "追踪碎片 %d 枚/次攻击，单枚伤害 %d%%，追踪强度 %.2f" % [
				homing_shard_stacks,
				int(round((0.56 + float(maxi(0, homing_shard_stacks - 1)) * 0.08) * 100.0)),
				4.2 + float(homing_shard_stacks) * 0.65
			]
		"heavy_shot":
			heavy_shot_stacks += 1
			upgrade_damage_bonus += 2
			projectile_damage += 2
			var heavy_old_size_bonus := upgrade_player_size_bonus
			upgrade_player_size_bonus = minf(PLAYER_SIZE_BONUS_CAP, upgrade_player_size_bonus + HEAVY_SHOT_SIZE_BONUS)
			var heavy_applied_size_percent := int(round((upgrade_player_size_bonus - heavy_old_size_bonus) * 100.0))
			result["damage_bonus"] = 2
			result["skill_text"] = "重弹 1 枚/3 次攻击，击退 +45%%，玩家体积 +%d%%（最高 +240%%），当前 %d 层" % [heavy_applied_size_percent, heavy_shot_stacks]
		"close_slash":
			close_slash_stacks += 1
			result["skill_text"] = "刀环半径 %d，冷却 %.2f 秒" % [
				int(round(72.0 + float(close_slash_stacks) * 13.0)),
				maxf(0.22, 1.18 - float(close_slash_stacks) * 0.09)
			]
		"pulse_field":
			pulse_field_stacks += 1
			result["skill_text"] = "脉冲半径 %d，冷却 %.2f 秒" % [
				int(round(96.0 + float(pulse_field_stacks) * 14.0)),
				maxf(0.55, 2.25 - float(pulse_field_stacks) * 0.12)
			]
		"channel_beam":
			channel_beam_stacks += 1
			result["skill_text"] = "光束射程 %d，间隔 %.2f 秒，单跳伤害 %.1f%%" % [
				int(round(330.0 + float(channel_beam_stacks) * 28.0)),
				maxf(0.05, 0.32 - float(channel_beam_stacks) * 0.025 - float(conduit_coil_stacks) * 0.01),
				(0.24 + float(channel_beam_stacks) * 0.045) * 100.0
			]
		"shatter_blast":
			shatter_blast_stacks += 1
			upgrade_explosion_radius_bonus += 18.0
			result["explosion_radius"] = 18
			result["skill_text"] = "爆裂伤害 +12%%，爆裂范围 +18，当前 %d 层" % shatter_blast_stacks
		"pierce_amp":
			pierce_amp_stacks += 1
			upgrade_pierce_bonus += 1
			result["skill_text"] = "穿透 +1，投射物伤害 +%d%%，当前 %d 层" % [pierce_amp_stacks * 5, pierce_amp_stacks]
		"conduit_coil":
			conduit_coil_stacks += 1
			result["skill_text"] = "光束伤害 +10%%，连锁/追踪伤害 +6%%，当前 %d 层" % conduit_coil_stacks
		"guard_blade":
			guard_blade_stacks += 1
			apply_graze_shield(8 + guard_blade_stacks * 2, 4.0)
			result["shield"] = 8 + guard_blade_stacks * 2
			result["shield_duration"] = 4.0
			result["skill_text"] = "近身技能伤害 +10%%，护盾 +%d，当前 %d 层" % [8 + guard_blade_stacks * 2, guard_blade_stacks]
		"form_focused":
			upgrade_damage_bonus += 8
			projectile_damage += 8
		"form_scatter":
			upgrade_projectile_count_bonus += 1
			projectile_count += 1
		"form_piercing":
			upgrade_pierce_bonus += 1
		"form_burst":
			upgrade_explosion_radius_bonus += 28.0
	_emit_build_summary()
	return result

func equip_weapon(new_weapon: Dictionary, old_weapon: Dictionary = {}) -> void:
	equip_item(new_weapon, old_weapon)

func equip_item(new_item: Dictionary, old_item: Dictionary = {}) -> void:
	if not old_item.is_empty():
		_remove_equipment_stats(old_item)
	if not new_item.is_empty():
		_apply_equipment_stats(new_item)
	GameManager.update_player_health(health, max_health)
	_emit_build_summary()

func heal_from_life_steal(hit_damage: int) -> void:
	if equipment_life_steal_bonus <= 0 or health <= 0 or health >= max_health:
		return
	var heal_amount: int = max(1, int(round(float(hit_damage) * float(equipment_life_steal_bonus) / 100.0)))
	health = min(max_health, health + heal_amount)
	GameManager.update_player_health(health, max_health)

func _heal_after_upgrade(amount: int) -> int:
	var old_health := health
	health = min(max_health, health + maxi(0, amount))
	return health - old_health

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
	attack_sequence += 1
	var base_direction: Vector2 = global_position.direction_to(target.global_position)
	var total_projectiles := _get_total_projectile_count()
	for index in range(total_projectiles):
		var spread: float = deg_to_rad(equipment_spread_degrees * (index - (total_projectiles - 1) / 2.0))
		_spawn_player_projectile(base_direction.rotated(spread), 1.0, [])
	_fire_extra_skill_projectiles(base_direction)

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
	var body_margin := screen_margin + maxf(0.0, (scale.x - 1.0) * 18.0)
	global_position.x = clampf(global_position.x, bounds.position.x + body_margin, bounds.end.x - body_margin)
	global_position.y = clampf(global_position.y, bounds.position.y + body_margin, bounds.end.y - body_margin)

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
	return max(0.05, base_fire_interval / max(speed_multiplier, 0.1))

func _get_base_projectile_damage() -> int:
	return max(1, int(round(float(projectile_damage + equipment_damage_bonus) * equipment_damage_multiplier)))

func _get_flow_damage_multiplier(_include_stationary_bonus: bool = false) -> float:
	var mass_bonus := _get_mass_resonance_damage_bonus()
	var slow_bonus := _get_slow_resonance_damage_bonus()
	var pierce_bonus := float(pierce_amp_stacks) * 0.05
	return 1.0 + mass_bonus + slow_bonus + pierce_bonus

func _get_mass_resonance_damage_bonus() -> float:
	if mass_resonance_stacks <= 0:
		return 0.0
	var player_size_bonus := maxf(0.0, _get_player_size_multiplier() - 1.0)
	var raw_bonus := (player_size_bonus / 0.10) * MASS_DAMAGE_PER_10_PERCENT * float(mass_resonance_stacks)
	return raw_bonus

func _get_slow_resonance_damage_bonus() -> float:
	if slow_resonance_stacks <= 0 or base_move_speed <= 0.0:
		return 0.0
	var slow_ratio := clampf((base_move_speed - move_speed) / base_move_speed, 0.0, 0.90)
	var raw_bonus := (slow_ratio / 0.10) * SLOW_DAMAGE_PER_10_PERCENT * float(slow_resonance_stacks)
	return raw_bonus

func _get_player_size_multiplier() -> float:
	var size_bonus := clampf(upgrade_player_size_bonus, 0.0, PLAYER_SIZE_BONUS_CAP)
	return clampf(1.0 + size_bonus, 0.85, 1.0 + PLAYER_SIZE_BONUS_CAP)

func _get_stationary_focus_tier() -> int:
	if still_focus_stacks <= 0:
		return 0
	return clampi(int(floor(stationary_focus_time / STILL_FOCUS_INTERVAL)), 0, STILL_FOCUS_MAX_TIER)

func _get_stationary_crit_bonus() -> int:
	var tier := _get_stationary_focus_tier()
	if tier <= 0:
		return 0
	return tier * STILL_FOCUS_CRIT_PER_TIER * still_focus_stacks

func _get_total_projectile_count() -> int:
	return maxi(1, projectile_count + equipment_projectile_count_bonus + affix_projectile_count_bonus)

func _get_total_pierce() -> int:
	return equipment_pierce_bonus + affix_pierce_bonus + upgrade_pierce_bonus

func _roll_projectile_damage() -> Dictionary:
	var damage := maxi(1, int(round(float(_get_base_projectile_damage()) * _get_flow_damage_multiplier())))
	var critical_chance := clampf(float(equipment_critical_chance_bonus + _get_stationary_crit_bonus()) / 100.0, 0.0, 0.95)
	var is_critical := randf() < critical_chance
	if is_critical:
		damage *= 2
	return {
		"damage": damage,
		"is_critical": is_critical
	}

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
	ratio += float(shatter_blast_stacks) * 0.12
	return ratio

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

func _add_upgrade_stack(upgrade_id: String) -> void:
	upgrade_stacks[upgrade_id] = int(upgrade_stacks.get(upgrade_id, 0)) + 1

func _get_projectile_power_tags(projectile: Node) -> Array[String]:
	var tags: Array[String] = []
	if projectile.is_critical:
		tags.append("critical")
	if int(projectile.pierce_remaining) > 0:
		tags.append("pierce")
	if float(projectile.explosion_radius) > 0.0:
		tags.append("blast")
	if _get_total_projectile_count() >= 3:
		tags.append("multi")
	if upgrade_damage_bonus >= 10:
		tags.append("charged")
	return tags

func _spawn_player_projectile(direction: Vector2, damage_multiplier: float = 1.0, extra_tags: Array[String] = []) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position
	projectile.direction = direction.normalized()
	var damage_roll := _roll_projectile_damage()
	projectile.damage = maxi(1, int(round(float(damage_roll.get("damage", 1)) * damage_multiplier)))
	projectile.is_critical = bool(damage_roll.get("is_critical", false))
	projectile.pierce_remaining = _get_total_pierce()
	projectile.explosion_radius = _get_total_explosion_radius()
	if extra_tags.has("overload") and projectile.explosion_radius <= 0.0:
		projectile.explosion_radius = 56.0 + float(overload_burst_stacks) * 8.0
	projectile.explosion_damage = int(round(float(projectile.damage) * _get_total_explosion_damage_ratio()))
	if extra_tags.has("overload") and projectile.explosion_damage <= 0:
		projectile.explosion_damage = maxi(1, int(round(float(projectile.damage) * (0.30 + float(overload_burst_stacks) * 0.04))))
	if extra_tags.has("chain"):
		projectile.lifetime = maxf(projectile.lifetime, 1.45 + float(chain_spark_stacks) * 0.08)
		projectile.knockback_force *= 1.0 + float(chain_spark_stacks) * 0.04 + float(conduit_coil_stacks) * 0.03
	if extra_tags.has("orbit"):
		projectile.lifetime = maxf(projectile.lifetime, 1.35 + float(orbit_blade_stacks) * 0.08)
		projectile.knockback_force *= 1.0 + float(orbit_blade_stacks) * 0.05
	projectile.source_player = self
	projectile.life_steal_percent = equipment_life_steal_bonus
	projectile.power_tags = _get_projectile_power_tags(projectile)
	if extra_tags.has("homing"):
		projectile.homing_strength = 4.2 + float(homing_shard_stacks) * 0.65
		projectile.homing_strength += float(conduit_coil_stacks) * 0.45
		projectile.lifetime = maxf(projectile.lifetime, 1.75)
	if extra_tags.has("heavy"):
		projectile.speed *= 0.78
		projectile.knockback_force *= 1.45 + float(heavy_shot_stacks) * 0.12
		projectile.lifetime = maxf(projectile.lifetime, 1.65)
		if projectile.explosion_radius <= 0.0 and heavy_shot_stacks >= 2:
			projectile.explosion_radius = 38.0 + float(heavy_shot_stacks) * 8.0
			projectile.explosion_damage = maxi(projectile.explosion_damage, int(round(float(projectile.damage) * 0.28)))
	for tag in extra_tags:
		if not projectile.power_tags.has(tag):
			projectile.power_tags.append(tag)
	get_tree().current_scene.add_child(projectile)

func _fire_extra_skill_projectiles(base_direction: Vector2) -> void:
	var chain_count := chain_spark_stacks
	var chain_multiplier := 0.66 + float(maxi(0, chain_spark_stacks - 1)) * 0.06 + float(conduit_coil_stacks) * 0.06
	for index in range(chain_count):
		var angle := deg_to_rad(18.0 + float(index) * 10.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		_spawn_player_projectile(base_direction.rotated(angle * side), chain_multiplier, ["chain"])
	var orbit_count := orbit_blade_stacks
	var orbit_multiplier := 0.54 + float(maxi(0, orbit_blade_stacks - 1)) * 0.08
	for index in range(orbit_count):
		var side_angle := deg_to_rad(82.0 + float(index) * 8.0)
		_spawn_player_projectile(base_direction.rotated(side_angle), orbit_multiplier, ["orbit"])
		_spawn_player_projectile(base_direction.rotated(-side_angle), orbit_multiplier, ["orbit"])
	if overload_burst_stacks > 0 and attack_sequence % 4 == 0:
		var bullet_count := 6 + overload_burst_stacks * 2
		var overload_multiplier := 0.50 + float(overload_burst_stacks) * 0.08
		for index in range(bullet_count):
			var angle := TAU * float(index) / float(bullet_count)
			_spawn_player_projectile(Vector2.RIGHT.rotated(angle), overload_multiplier, ["overload", "blast"])
	if homing_shard_stacks > 0:
		var homing_count := homing_shard_stacks
		var homing_multiplier := 0.56 + float(maxi(0, homing_shard_stacks - 1)) * 0.08 + float(conduit_coil_stacks) * 0.06
		for index in range(homing_count):
			var angle := deg_to_rad((float(index) - float(homing_count - 1) * 0.5) * 24.0)
			_spawn_player_projectile(base_direction.rotated(angle), homing_multiplier, ["homing"])
	if heavy_shot_stacks > 0 and attack_sequence % 3 == 0:
		_spawn_player_projectile(base_direction, 1.55 + float(heavy_shot_stacks) * 0.12, ["heavy", "charged"])

func _update_close_range_skills(delta: float) -> void:
	if close_slash_cooldown > 0.0:
		close_slash_cooldown -= delta
	if pulse_field_cooldown > 0.0:
		pulse_field_cooldown -= delta
	if close_slash_stacks > 0 and close_slash_cooldown <= 0.0:
		_fire_close_slash()
		close_slash_cooldown = maxf(0.22, 1.18 - float(close_slash_stacks) * 0.09)
	if pulse_field_stacks > 0 and pulse_field_cooldown <= 0.0:
		_fire_pulse_field()
		pulse_field_cooldown = maxf(0.55, 2.25 - float(pulse_field_stacks) * 0.12)

func _update_channel_skill(delta: float) -> void:
	if channel_beam_stacks <= 0:
		return
	channel_beam_tick_timer -= delta
	if channel_beam_tick_timer > 0.0:
		return
	channel_beam_tick_timer = maxf(0.05, 0.32 - float(channel_beam_stacks) * 0.025 - float(conduit_coil_stacks) * 0.01)
	_fire_channel_beam_tick()

func _update_motion_focus(delta: float, input_direction: Vector2) -> void:
	var old_tier := _get_stationary_focus_tier()
	var is_moving := input_direction.length_squared() > 0.01 or knockback_velocity.length_squared() > 100.0
	if is_moving:
		stationary_focus_time = maxf(0.0, stationary_focus_time - STILL_FOCUS_INTERVAL * delta)
	else:
		stationary_focus_time = minf(STILL_FOCUS_INTERVAL * float(STILL_FOCUS_MAX_TIER), stationary_focus_time + delta)
	var new_tier := _get_stationary_focus_tier()
	if new_tier != old_tier or new_tier != last_stationary_focus_tier:
		last_stationary_focus_tier = new_tier
		_emit_build_summary()

func _update_player_body_scale() -> void:
	scale = Vector2.ONE * _get_player_size_multiplier()

func _fire_close_slash() -> void:
	var stationary_tier := _get_stationary_focus_tier()
	var radius := 72.0 + float(close_slash_stacks) * 13.0 + float(stationary_tier) * 6.0
	var damage_multiplier := 0.50 + float(close_slash_stacks) * 0.10 + float(guard_blade_stacks) * 0.10
	var damage := maxi(1, int(round(float(_get_base_projectile_damage()) * damage_multiplier * _get_flow_damage_multiplier(true))))
	var hit_count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance > radius:
			continue
		if enemy.has_method("take_damage"):
			var knockback := global_position.direction_to(enemy.global_position) * (150.0 + float(close_slash_stacks) * 16.0)
			enemy.take_damage(damage, knockback)
			hit_count += 1
	_show_close_slash_effect(radius)
	if hit_count > 0:
		if guard_blade_stacks > 0:
			apply_graze_shield(guard_blade_stacks * 2, 2.5)
		CombatFeedback.show_text(get_tree().current_scene, global_position, "斩击", Color(0.82, 1.0, 0.72, 1.0))
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.62, 1.0, 0.58, 0.74), 1.25 + float(close_slash_stacks) * 0.18)

func _show_close_slash_effect(radius: float) -> void:
	var world := get_tree().current_scene
	CombatFeedback.show_ring(world, global_position, radius, Color(0.72, 1.0, 0.55, 0.78), 5.0 + float(close_slash_stacks) * 0.45, 0.20)
	CombatFeedback.show_ring(world, global_position, radius * 0.64, Color(0.95, 1.0, 0.70, 0.46), 2.2 + float(close_slash_stacks) * 0.25, 0.14)
	var slash_count := mini(8, 3 + close_slash_stacks)
	var rotation_offset := float(attack_sequence % 8) * 0.42
	for index in range(slash_count):
		var angle := rotation_offset + TAU * float(index) / float(slash_count)
		var start := global_position + Vector2.RIGHT.rotated(angle - 0.26) * radius * 0.32
		var end := global_position + Vector2.RIGHT.rotated(angle + 0.26) * radius
		CombatFeedback.show_line(world, start, end, Color(0.86, 1.0, 0.58, 0.72), 3.0 + float(close_slash_stacks) * 0.22, 0.16)

func _fire_pulse_field() -> void:
	var stationary_tier := _get_stationary_focus_tier()
	var radius := 96.0 + float(pulse_field_stacks) * 14.0 + float(stationary_tier) * 8.0
	var damage_multiplier := 0.38 + float(pulse_field_stacks) * 0.06 + float(guard_blade_stacks) * 0.10
	var damage := maxi(1, int(round(float(_get_base_projectile_damage()) * damage_multiplier * _get_flow_damage_multiplier(true))))
	var hit_count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance > radius:
			continue
		if enemy.has_method("take_damage"):
			var knockback := global_position.direction_to(enemy.global_position) * (105.0 + float(pulse_field_stacks) * 12.0)
			enemy.take_damage(damage, knockback)
			hit_count += 1
	_show_pulse_field_effect(radius)
	if hit_count > 0:
		if guard_blade_stacks > 0:
			apply_graze_shield(guard_blade_stacks * 2, 2.5)
		CombatFeedback.show_text(get_tree().current_scene, global_position, "脉冲", Color(0.55, 0.9, 1.0, 1.0))
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.35, 0.82, 1.0, 0.52), 1.45 + float(pulse_field_stacks) * 0.16)

func _show_pulse_field_effect(radius: float) -> void:
	var world := get_tree().current_scene
	var outer_width := 4.0 + float(pulse_field_stacks) * 0.35
	CombatFeedback.show_ring(world, global_position, radius, Color(0.34, 0.86, 1.0, 0.72), outer_width, 0.24)
	CombatFeedback.show_ring(world, global_position, radius * 0.58, Color(0.66, 0.96, 1.0, 0.44), 2.4 + float(pulse_field_stacks) * 0.22, 0.18)
	CombatFeedback.show_ring(world, global_position, radius * 0.28, Color(0.92, 1.0, 1.0, 0.34), 1.6 + float(pulse_field_stacks) * 0.16, 0.14)
	var ray_count := mini(12, 5 + pulse_field_stacks)
	var rotation_offset := float(Time.get_ticks_msec() % 1000) / 1000.0 * TAU
	for index in range(ray_count):
		var angle := rotation_offset + TAU * float(index) / float(ray_count)
		var direction := Vector2.RIGHT.rotated(angle)
		var start := global_position + direction * radius * 0.18
		var end := global_position + direction * radius
		CombatFeedback.show_line(world, start, end, Color(0.42, 0.92, 1.0, 0.48), 2.0 + float(pulse_field_stacks) * 0.16, 0.18)

func _fire_channel_beam_tick() -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	var stationary_tier := _get_stationary_focus_tier()
	var max_range := 330.0 + float(channel_beam_stacks) * 28.0 + float(stationary_tier) * 18.0
	var distance := global_position.distance_to(target.global_position)
	if distance > max_range:
		return
	var damage := maxi(1, int(round(float(_get_base_projectile_damage()) * (0.24 + float(channel_beam_stacks) * 0.045 + float(conduit_coil_stacks) * 0.10) * _get_flow_damage_multiplier(true))))
	if target.has_method("take_damage"):
		var knockback := global_position.direction_to(target.global_position) * 36.0
		target.take_damage(damage, knockback)
	var midpoint := global_position.lerp(target.global_position, 0.52)
	CombatFeedback.show_line(get_tree().current_scene, global_position, target.global_position, Color(0.55, 0.72, 1.0, 0.58), 3.0 + float(channel_beam_stacks) * 0.45, 0.10)
	CombatFeedback.show_burst(get_tree().current_scene, midpoint, Color(0.58, 0.72, 1.0, 0.42), 0.42 + float(channel_beam_stacks) * 0.03)

func _fire_upgrade_nova() -> int:
	var bullet_count := 10
	for index in range(bullet_count):
		var angle := TAU * float(index) / float(bullet_count)
		_spawn_player_projectile(Vector2.RIGHT.rotated(angle), 0.68, ["nova", "blast"])
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1.0, 0.72, 0.25, 0.85), 1.9)
	return bullet_count

func _fire_charged_volley() -> int:
	var target := _find_nearest_enemy()
	var base_direction := Vector2.RIGHT
	if target != null:
		base_direction = global_position.direction_to(target.global_position)
	var bullet_count := 5
	for index in range(bullet_count):
		var offset_angle := deg_to_rad(float(index - 2) * 5.5)
		_spawn_player_projectile(base_direction.rotated(offset_angle), 1.12, ["volley", "charged"])
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1.0, 0.93, 0.36, 0.82), 1.45)
	return bullet_count

func _emit_build_summary() -> void:
	GameManager.update_player_build_summary({
		"damage": _get_base_projectile_damage(),
		"projectiles": _get_total_projectile_count(),
		"pierce": _get_total_pierce(),
		"explosion_radius": int(round(_get_total_explosion_radius())),
		"player_size_bonus": int(round((_get_player_size_multiplier() - 1.0) * 100.0)),
		"flow_damage_bonus_percent": int(round((_get_flow_damage_multiplier() - 1.0) * 100.0)),
		"mass_damage_bonus_percent": int(round(_get_mass_resonance_damage_bonus() * 100.0)),
		"slow_damage_bonus_percent": int(round(_get_slow_resonance_damage_bonus() * 100.0)),
		"stationary_focus_tier": _get_stationary_focus_tier(),
		"stationary_critical_bonus": _get_stationary_crit_bonus(),
		"attack_interval": fire_interval,
		"move_speed": int(round(move_speed)),
		"critical_chance": equipment_critical_chance_bonus + _get_stationary_crit_bonus(),
		"shield": graze_shield,
		"upgrade_damage_bonus": upgrade_damage_bonus,
		"upgrade_attack_speed_stacks": upgrade_attack_speed_stacks,
		"upgrade_projectile_count_bonus": upgrade_projectile_count_bonus,
		"upgrade_pierce_bonus": upgrade_pierce_bonus,
		"upgrade_explosion_radius_bonus": int(round(upgrade_explosion_radius_bonus)),
		"upgrade_player_size_bonus": int(round(upgrade_player_size_bonus * 100.0)),
		"mass_resonance_stacks": mass_resonance_stacks,
		"slow_resonance_stacks": slow_resonance_stacks,
		"still_focus_stacks": still_focus_stacks,
		"chain_spark_stacks": chain_spark_stacks,
		"orbit_blade_stacks": orbit_blade_stacks,
		"overload_burst_stacks": overload_burst_stacks,
		"homing_shard_stacks": homing_shard_stacks,
		"heavy_shot_stacks": heavy_shot_stacks,
		"close_slash_stacks": close_slash_stacks,
		"pulse_field_stacks": pulse_field_stacks,
		"channel_beam_stacks": channel_beam_stacks,
		"shatter_blast_stacks": shatter_blast_stacks,
		"pierce_amp_stacks": pierce_amp_stacks,
		"conduit_coil_stacks": conduit_coil_stacks,
		"guard_blade_stacks": guard_blade_stacks,
		"upgrade_stacks": upgrade_stacks.duplicate(true)
	})

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
