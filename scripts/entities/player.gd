extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")
const SkillCatalog := preload("res://scripts/items/skill_catalog.gd")
const PLAYER_SIZE_BONUS_CAP := 2.40
const PLAYER_SIZE_PENALTY_CAP := -0.40
const MIN_TRADEOFF_MOVE_SPEED := 80.0
const MULTISHOT_SIZE_BONUS := 0.30
const MULTISHOT_SPEED_MULTIPLIER := 0.80
const BLAST_CORE_SIZE_BONUS := 0.20
const HEAVY_SHOT_SIZE_BONUS := 0.15
const LIGHT_FRAME_SIZE_REDUCTION := 0.12
const LIGHT_FRAME_MOVE_SPEED_BONUS := 70.0
const DAMAGE_UPGRADE_PERCENT := 0.25
const ATTACK_SPEED_DAMAGE_PENALTY := 0.10
const LIGHT_FRAME_DAMAGE_PENALTY := 0.10
const PIERCING_DAMAGE_PENALTY := 0.10
const CHAIN_DAMAGE_PENALTY := 0.12
const MASS_DAMAGE_PER_10_PERCENT := 0.16
const SMALL_DAMAGE_PER_10_PERCENT := 0.08
const SMALL_CRIT_PER_10_PERCENT := 10
const SLOW_DAMAGE_PER_10_PERCENT := 0.18
const FAST_DAMAGE_PER_10_PERCENT := 0.10
const FAST_CRIT_PER_10_PERCENT := 8
const RAPID_SKILL_DAMAGE_PER_10_PERCENT := 0.22
const BLOOD_DAMAGE_PER_10_PERCENT := 0.16
const BLOOD_CRIT_PER_10_PERCENT := 10
const STILL_FOCUS_INTERVAL := 0.70
const STILL_FOCUS_CRIT_PER_TIER := 10
const STILL_FOCUS_MAX_TIER := 12
const MOVEMENT_FOCUS_INTERVAL := 0.60
const MOVEMENT_FOCUS_DAMAGE_PER_TIER := 0.08
const MOVEMENT_FOCUS_CRIT_PER_TIER := 5
const MOVEMENT_FOCUS_MAX_TIER := 10
const DAMAGE_TRADEOFF_FIRE_INTERVAL_MULTIPLIER := 1.10
const MAX_HEALTH_SPEED_MULTIPLIER := 0.95
const BLAST_CORE_FIRE_INTERVAL_MULTIPLIER := 1.15
const HEAVY_SHOT_FIRE_INTERVAL_MULTIPLIER := 1.10
const HOMING_SPEED_MULTIPLIER := 0.88
const CHANNEL_BEAM_SPEED_MULTIPLIER := 0.90
const PIERCE_DAMAGE_PER_STACK := 0.55
const SHATTER_EXPLOSION_DAMAGE_PER_STACK := 0.55
const GUARD_CLOSE_DAMAGE_PER_STACK := 0.55
const CONDUIT_BEAM_DAMAGE_PER_STACK := 1.50
const CONDUIT_CHAIN_DAMAGE_PER_STACK := 0.75
const CONDUIT_BEAM_INTERVAL_REDUCTION := 0.03
const LIFE_STEAL_BASE_CAP_RATIO := 0.06
const LIFE_STEAL_CAP_PER_PERCENT := 1.0
const EXPLOSION_RADIUS_CAP := 72.0

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
var initial_fire_interval: float
var equipment_damage_bonus: int = 0
var equipment_attack_speed_bonus: int = 0
var equipment_health_bonus: int = 0
var equipment_move_speed_bonus: int = 0
var equipment_critical_chance_bonus: int = 0
var equipment_life_steal_bonus: int = 0
var equipment_gold_bonus: int = 0
var class_critical_chance_bonus: int = 0
var class_explosion_radius_bonus: float = 0.0
var class_data: Dictionary = {}
var class_multipliers: Dictionary = {}
var class_focus_decay: Dictionary = {}
var class_gain_multipliers: Dictionary = {}
var equipment_projectile_count_bonus: int = 0
var equipment_pierce_bonus: int = 0
var equipment_form_damage_bonus: int = 0
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
var light_frame_stacks: int = 0
var light_resonance_stacks: int = 0
var slow_resonance_stacks: int = 0
var haste_resonance_stacks: int = 0
var rapid_resonance_stacks: int = 0
var blood_pact_stacks: int = 0
var still_focus_stacks: int = 0
var motion_focus_stacks: int = 0
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
var giant_echo_stacks: int = 0
var light_edge_stacks: int = 0
var compressed_core_stacks: int = 0
var reflow_shards_stacks: int = 0
var crimson_leech_stacks: int = 0
var attack_sequence: int = 0
var close_slash_cooldown: float = 0.0
var pulse_field_cooldown: float = 0.0
var channel_beam_tick_timer: float = 0.0
var stationary_focus_time: float = 0.0
var movement_focus_time: float = 0.0
var last_stationary_focus_tier: int = 0
var last_movement_focus_tier: int = 0
var last_stand_trigger_used: bool = false
var momentum_cache_cooldown: float = 0.0
var anchor_discharge_cooldown: float = 0.0
var life_steal_window_elapsed: float = 0.0
var life_steal_recovered_this_second: int = 0
var upgrade_stacks := {}
@onready var visual: Polygon2D = $Visual
@onready var hit_core: Polygon2D = $HitCore

func _ready() -> void:
	health = max_health
	base_move_speed = move_speed
	base_fire_interval = fire_interval
	initial_fire_interval = fire_interval
	sync_health_state()

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	_update_invulnerability(delta)
	_update_graze_shield(delta)
	_update_trigger_cooldowns(delta)
	_update_life_steal_window(delta)
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
	var old_health := health
	health -= remaining_damage
	GameManager.update_player_health(max(health, 0), max_health)
	_emit_low_life_trigger_if_crossed(old_health, health)
	_emit_build_summary()
	CombatFeedback.show_damage(get_tree().current_scene, global_position, remaining_damage, Color(1, 0.25, 0.25, 1))
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1, 0.2, 0.2, 0.9), 1.3)
	if health <= 0:
		GameManager.end_run()
		queue_free()

func sync_health_state() -> void:
	GameManager.update_player_health(health, max_health)
	GameManager.update_player_graze_shield(graze_shield, graze_shield_timer)
	_emit_build_summary()

func apply_character_class(new_class_data: Dictionary) -> void:
	class_data = new_class_data.duplicate(true)
	class_multipliers = class_data.get("multipliers", {}).duplicate(true)
	class_focus_decay = class_data.get("focus_decay", {}).duplicate(true)
	class_gain_multipliers = class_data.get("gain_multipliers", {}).duplicate(true)
	var initial_stats: Dictionary = class_data.get("initial_stats", {})
	var size_bonus := float(initial_stats.get("player_size_bonus", 0.0))
	if size_bonus != 0.0:
		upgrade_player_size_bonus = clampf(upgrade_player_size_bonus + size_bonus, PLAYER_SIZE_PENALTY_CAP, PLAYER_SIZE_BONUS_CAP)
	var move_speed_multiplier := float(initial_stats.get("move_speed_multiplier", 1.0))
	if move_speed_multiplier > 0.0 and move_speed_multiplier != 1.0:
		move_speed = maxf(MIN_TRADEOFF_MOVE_SPEED, move_speed * move_speed_multiplier)
	var fire_interval_multiplier := float(initial_stats.get("fire_interval_multiplier", 1.0))
	if fire_interval_multiplier > 0.0 and fire_interval_multiplier != 1.0:
		_apply_fire_interval_multiplier(fire_interval_multiplier)
	class_critical_chance_bonus = int(initial_stats.get("critical_chance", 0))
	class_explosion_radius_bonus = float(initial_stats.get("explosion_radius", 0.0))
	var shield := int(initial_stats.get("shield", 0))
	if shield > 0:
		apply_graze_shield(shield, float(initial_stats.get("shield_duration", 999.0)))
	_update_player_body_scale()
	_emit_build_summary()

func set_movement_bounds(bounds: Rect2) -> void:
	movement_bounds = bounds
	_clamp_to_movement_bounds()

func handle_gameplay_trigger(trigger: Dictionary) -> void:
	match str(trigger.get("id", "")):
		"stage_started":
			last_stand_trigger_used = false
		"encounter_defeated":
			_handle_elite_reactor_trigger(str(trigger.get("kind", "")))
		"low_life_entered":
			_handle_last_stand_trigger()
		"focus_tier_changed":
			_handle_focus_tier_trigger(trigger)

func heal_fixed_amount(amount: int) -> int:
	if amount <= 0 or health <= 0 or health >= max_health:
		return 0
	var old_health := health
	health = min(max_health, health + amount)
	GameManager.update_player_health(health, max_health)
	_emit_build_summary()
	return health - old_health

func apply_graze_shield(amount: int, duration: float) -> void:
	if amount <= 0 or duration <= 0.0 or health <= 0:
		return
	graze_shield += amount
	graze_shield_timer = maxf(graze_shield_timer, duration)
	_sync_graze_shield_state()
	_emit_build_summary()

func _update_trigger_cooldowns(delta: float) -> void:
	momentum_cache_cooldown = maxf(0.0, momentum_cache_cooldown - delta)
	anchor_discharge_cooldown = maxf(0.0, anchor_discharge_cooldown - delta)

func _update_life_steal_window(delta: float) -> void:
	life_steal_window_elapsed += delta
	if life_steal_window_elapsed < 1.0:
		return
	life_steal_window_elapsed = fmod(life_steal_window_elapsed, 1.0)
	life_steal_recovered_this_second = 0

func _emit_low_life_trigger_if_crossed(old_health: int, new_health: int) -> void:
	if max_health <= 0:
		return
	var threshold := int(round(float(max_health) * _skill_float("last_stand_matrix", "threshold", 0.35)))
	if old_health > threshold and new_health <= threshold:
		GameManager.emit_gameplay_trigger("low_life_entered", {
			"health": new_health,
			"max_health": max_health
		})

func _is_low_life_for_trigger() -> bool:
	if max_health <= 0:
		return false
	return health <= int(round(float(max_health) * _skill_float("last_stand_matrix", "threshold", 0.35)))

func _handle_elite_reactor_trigger(kind: String) -> void:
	var stacks := int(upgrade_stacks.get("elite_reactor", 0))
	if stacks <= 0 or not ["elite", "boss"].has(kind):
		return
	var cleared := GameManager.clear_enemy_projectiles_from_upgrade()
	var shield := stacks * _skill_int("elite_reactor", "shield_per_stack", 18)
	var duration := _skill_float("elite_reactor", "shield_duration", 4.0)
	apply_graze_shield(shield, duration)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.42, 0.86, 1.0, 0.82), 1.7)
	GameManager.record_gameplay_trigger_effect("破阵反应")
	GameManager.show_milestone_message("破阵反应：清除敌弹 %d，护盾 +%d，持续 %.1f 秒" % [cleared, shield, duration])

func _handle_last_stand_trigger() -> void:
	var stacks := int(upgrade_stacks.get("last_stand_matrix", 0))
	if stacks <= 0 or last_stand_trigger_used:
		return
	last_stand_trigger_used = true
	var cleared := GameManager.clear_enemy_projectiles_from_upgrade()
	var shield := stacks * _skill_int("last_stand_matrix", "shield_per_stack", 26)
	var duration := _skill_float("last_stand_matrix", "shield_duration", 4.0)
	apply_graze_shield(shield, duration)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1.0, 0.25, 0.42, 0.84), 1.9)
	GameManager.record_gameplay_trigger_effect("背水矩阵")
	GameManager.show_milestone_message("背水矩阵：清除敌弹 %d，护盾 +%d，持续 %.1f 秒" % [cleared, shield, duration])

func _handle_focus_tier_trigger(trigger: Dictionary) -> void:
	var old_stationary := int(trigger.get("old_stationary_tier", 0))
	var new_stationary := int(trigger.get("stationary_tier", 0))
	var old_movement := int(trigger.get("old_movement_tier", 0))
	var new_movement := int(trigger.get("movement_tier", 0))
	_handle_momentum_cache_trigger(old_movement, new_movement)
	_handle_anchor_discharge_trigger(old_stationary, new_stationary)

func _handle_momentum_cache_trigger(old_tier: int, new_tier: int) -> void:
	var stacks := int(upgrade_stacks.get("momentum_cache", 0))
	var required_tier := _skill_int("momentum_cache", "required_movement_tier", 8)
	if stacks <= 0 or momentum_cache_cooldown > 0.0 or old_tier >= required_tier or new_tier < required_tier:
		return
	var shield := stacks * _skill_int("momentum_cache", "shield_per_stack", 10)
	var duration := _skill_float("momentum_cache", "shield_duration", 2.5)
	momentum_cache_cooldown = _skill_float("momentum_cache", "cooldown", 9.0)
	apply_graze_shield(shield, duration)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.46, 1.0, 0.76, 0.76), 1.25)
	GameManager.record_gameplay_trigger_effect("疾行缓存")

func _handle_anchor_discharge_trigger(old_tier: int, new_tier: int) -> void:
	var stacks := int(upgrade_stacks.get("anchor_discharge", 0))
	var required_tier := _skill_int("anchor_discharge", "required_stationary_tier", 6)
	if stacks <= 0 or anchor_discharge_cooldown > 0.0 or old_tier >= required_tier or new_tier < required_tier:
		return
	var cleared := GameManager.clear_enemy_projectiles_from_upgrade()
	var shield := stacks * _skill_int("anchor_discharge", "shield_per_stack", 8)
	var duration := _skill_float("anchor_discharge", "shield_duration", 2.5)
	anchor_discharge_cooldown = _skill_float("anchor_discharge", "cooldown", 12.0)
	apply_graze_shield(shield, duration)
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.78, 0.72, 1.0, 0.78), 1.55)
	GameManager.record_gameplay_trigger_effect("锚定释放")
	if cleared > 0:
		GameManager.show_milestone_message("锚定释放：清除敌弹 %d，护盾 +%d，持续 %.1f 秒" % [cleared, shield, duration])

func take_event_damage(amount: int) -> int:
	if GameManager.is_run_over or amount <= 0 or health <= 0:
		return 0
	var old_health := health
	health = max(0, health - amount)
	GameManager.update_player_health(health, max_health)
	_emit_low_life_trigger_if_crossed(old_health, health)
	_emit_build_summary()
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
			_apply_fire_interval_multiplier(_skill_float("damage", "fire_interval_multiplier", DAMAGE_TRADEOFF_FIRE_INTERVAL_MULTIPLIER))
			var damage_percent := int(round(_skill_float("damage", "projectile_damage_percent", DAMAGE_UPGRADE_PERCENT) * _get_class_gain_multiplier("projectile_damage_percent") * 100.0))
			result["skill_text"] = "投射物伤害 +%d%%，射击间隔 +10%%" % damage_percent
		"attack_speed":
			upgrade_attack_speed_stacks += 1
			base_fire_interval = max(0.06, base_fire_interval * _skill_float("attack_speed", "fire_interval_multiplier", 0.75))
			fire_interval = _calculate_fire_interval()
			result["attack_speed_percent"] = 25
			result["skill_text"] = "投射物伤害 -10%"
		"move_speed":
			var move_speed_bonus := _scale_class_float_gain("move_speed", _skill_float("move_speed", "move_speed_bonus", 70.0))
			move_speed += move_speed_bonus
			var move_old_size_bonus := upgrade_player_size_bonus
			upgrade_player_size_bonus = minf(PLAYER_SIZE_BONUS_CAP, upgrade_player_size_bonus + _scale_class_float_gain("player_size_bonus", _skill_float("move_speed", "player_size_bonus", 0.05)))
			var move_applied_size_percent := int(round((upgrade_player_size_bonus - move_old_size_bonus) * 100.0))
			result["move_speed_bonus"] = int(round(move_speed_bonus))
			result["skill_text"] = "玩家体积 +%d%%（最高 +240%%）" % move_applied_size_percent
		"max_health":
			var max_health_bonus := _scale_class_int_gain("max_health", _skill_int("max_health", "max_health_bonus", 30))
			max_health += max_health_bonus
			move_speed = maxf(MIN_TRADEOFF_MOVE_SPEED, move_speed * _skill_float("max_health", "move_speed_multiplier", MAX_HEALTH_SPEED_MULTIPLIER))
			result["heal"] = _heal_after_upgrade(_scale_class_int_gain("heal", _skill_int("max_health", "heal", 30)))
			GameManager.update_player_health(health, max_health)
			result["max_health_bonus"] = max_health_bonus
			result["skill_text"] = "当前移速 -5%（最低 80）"
		"heal":
			result["heal"] = _heal_after_upgrade(_scale_class_int_gain("heal", _skill_int("heal", "heal", 40)))
			GameManager.update_player_health(health, max_health)
		"strong_heal":
			result["heal"] = _heal_after_upgrade(_scale_class_int_gain("heal", _skill_int("strong_heal", "heal", 70)))
			GameManager.update_player_health(health, max_health)
		"recovery_training":
			var recovery_health_bonus := _scale_class_int_gain("max_health", _skill_int("recovery_training", "max_health_bonus", 25))
			max_health += recovery_health_bonus
			move_speed = maxf(MIN_TRADEOFF_MOVE_SPEED, move_speed * _skill_float("recovery_training", "move_speed_multiplier", MAX_HEALTH_SPEED_MULTIPLIER))
			result["heal"] = _heal_after_upgrade(_scale_class_int_gain("heal", _skill_int("recovery_training", "heal", 60)))
			GameManager.update_player_health(health, max_health)
			result["max_health_bonus"] = recovery_health_bonus
			result["skill_text"] = "当前移速 -5%（最低 80）"
		"multishot":
			var multishot_projectile_bonus := _scale_class_int_gain("projectile_count", _skill_int("multishot", "projectile_count_bonus", 1))
			upgrade_projectile_count_bonus += multishot_projectile_bonus
			projectile_count += multishot_projectile_bonus
			var multishot_old_size_bonus := upgrade_player_size_bonus
			var multishot_old_move_speed := move_speed
			upgrade_player_size_bonus = minf(PLAYER_SIZE_BONUS_CAP, upgrade_player_size_bonus + _scale_class_float_gain("player_size_bonus", _skill_float("multishot", "player_size_bonus", MULTISHOT_SIZE_BONUS)))
			move_speed = maxf(MIN_TRADEOFF_MOVE_SPEED, move_speed * _skill_float("multishot", "move_speed_multiplier", MULTISHOT_SPEED_MULTIPLIER))
			var multishot_applied_size_percent := int(round((upgrade_player_size_bonus - multishot_old_size_bonus) * 100.0))
			var multishot_applied_slow_percent := 0
			if multishot_old_move_speed > 0.0:
				multishot_applied_slow_percent = int(round((multishot_old_move_speed - move_speed) / multishot_old_move_speed * 100.0))
			result["skill_text"] = "投射物 +%d，玩家体积 +%d%%（最高 +240%%），当前移速 -%d%%（最低 80）" % [multishot_projectile_bonus, multishot_applied_size_percent, multishot_applied_slow_percent]
		"mass_resonance":
			mass_resonance_stacks += 1
			result["skill_text"] = "玩家体积每 +10%%，投射物伤害 +16%%"
		"light_frame":
			light_frame_stacks += 1
			var light_old_size_bonus := upgrade_player_size_bonus
			upgrade_player_size_bonus = maxf(PLAYER_SIZE_PENALTY_CAP, upgrade_player_size_bonus - _scale_class_float_gain("player_size_reduction", _skill_float("light_frame", "player_size_reduction", LIGHT_FRAME_SIZE_REDUCTION)))
			move_speed += _scale_class_float_gain("move_speed", _skill_float("light_frame", "move_speed_bonus", LIGHT_FRAME_MOVE_SPEED_BONUS))
			var light_applied_size_percent := int(round((light_old_size_bonus - upgrade_player_size_bonus) * 100.0))
			result["move_speed_bonus"] = int(round(_scale_class_float_gain("move_speed", _skill_float("light_frame", "move_speed_bonus", LIGHT_FRAME_MOVE_SPEED_BONUS))))
			result["skill_text"] = "玩家体积 -%d%%（最低 -40%%），投射物伤害 -10%%" % light_applied_size_percent
		"light_resonance":
			light_resonance_stacks += 1
			result["skill_text"] = "玩家体积每低于 100%% 10%%，投射物伤害 +8%%、暴击率 +10%%"
		"light_edge":
			light_edge_stacks += 1
			result["skill_text"] = "玩家体积每低于 100%% 10%%，暴击伤害 +25%%，当前暴击倍率 %.2f 倍" % _get_critical_damage_multiplier()
		"slow_resonance":
			slow_resonance_stacks += 1
			result["skill_text"] = "移速每低于初始值 10%%，投射物伤害 +18%%"
		"haste_resonance":
			haste_resonance_stacks += 1
			result["skill_text"] = "当前移速每高于初始值 10%%，投射物伤害 +10%%、暴击率 +8%%"
		"rapid_resonance":
			rapid_resonance_stacks += 1
			result["skill_text"] = "射击间隔每低于初始值 10%%，连锁/回旋/追踪/过载伤害 +22%%"
		"reflow_shards":
			reflow_shards_stacks += 1
			_apply_fire_interval_multiplier(_skill_float("reflow_shards", "fire_interval_multiplier", 0.90))
			result["skill_text"] = "射击间隔 -10%%；游走层数使连锁/回旋/追踪伤害 +12%%，最多 10 层"
		"blood_pact":
			blood_pact_stacks += 1
			var blood_cost := mini(_skill_int("blood_pact", "health_cost", 22), maxi(0, health - 1))
			if blood_cost > 0:
				var blood_old_health := health
				health -= blood_cost
				GameManager.update_player_health(health, max_health)
				_emit_low_life_trigger_if_crossed(blood_old_health, health)
				CombatFeedback.show_damage(get_tree().current_scene, global_position, blood_cost, Color(1.0, 0.20, 0.32, 1.0))
				CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1.0, 0.12, 0.24, 0.78), 1.1)
			result["skill_text"] = "当前生命 -%d（最低 1）；生命每损失 10%%，投射物伤害 +16%%、暴击率 +10%%" % blood_cost
		"still_focus":
			still_focus_stacks += 1
			result["skill_text"] = "静止每 0.7 秒暴击率 +10%%，最多 12 层专注"
		"motion_focus":
			motion_focus_stacks += 1
			result["skill_text"] = "移动每 0.6 秒游走伤害 +8%%、暴击率 +5%%，最多 10 层游走"
		"piercing_rounds":
			var piercing_bonus := _scale_class_int_gain("pierce", _skill_int("piercing_rounds", "pierce_bonus", 1))
			upgrade_pierce_bonus += piercing_bonus
			result["skill_text"] = "穿透 +%d，投射物伤害 -10%%" % piercing_bonus
		"blast_core":
			var blast_radius := _scale_class_float_gain("explosion_radius", _skill_float("blast_core", "explosion_radius", 40.0))
			upgrade_explosion_radius_bonus += blast_radius
			var blast_old_size_bonus := upgrade_player_size_bonus
			upgrade_player_size_bonus = minf(PLAYER_SIZE_BONUS_CAP, upgrade_player_size_bonus + _scale_class_float_gain("player_size_bonus", _skill_float("blast_core", "player_size_bonus", BLAST_CORE_SIZE_BONUS)))
			_apply_fire_interval_multiplier(_skill_float("blast_core", "fire_interval_multiplier", BLAST_CORE_FIRE_INTERVAL_MULTIPLIER))
			var blast_applied_size_percent := int(round((upgrade_player_size_bonus - blast_old_size_bonus) * 100.0))
			result["explosion_radius"] = int(round(blast_radius))
			result["skill_text"] = "玩家体积 +%d%%（最高 +240%%），射击间隔 +15%%" % blast_applied_size_percent
		"graze_barrier":
			var graze_shield_gain := _scale_class_int_gain("shield", _skill_int("graze_barrier", "shield", 22))
			apply_graze_shield(graze_shield_gain, 4.0)
			result["shield"] = graze_shield_gain
			result["shield_duration"] = 4.0
		"clear_barrier":
			result["cleared_projectiles"] = GameManager.clear_enemy_projectiles_from_upgrade()
			var clear_shield_gain := _scale_class_int_gain("shield", _skill_int("clear_barrier", "shield", 16))
			apply_graze_shield(clear_shield_gain, 3.5)
			result["shield"] = clear_shield_gain
			result["shield_duration"] = 3.5
			CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.38, 0.92, 1.0, 0.82), 1.8)
		"pulse_nova":
			var nova_radius := _scale_class_float_gain("explosion_radius", 18.0)
			upgrade_explosion_radius_bonus += nova_radius
			result["explosion_radius"] = int(round(nova_radius))
			result["nova_projectiles"] = _fire_upgrade_nova()
		"charged_volley":
			var volley_damage_bonus := _scale_class_int_gain("damage_flat", 3)
			upgrade_damage_bonus += volley_damage_bonus
			projectile_damage += volley_damage_bonus
			result["damage_bonus"] = volley_damage_bonus
			result["volley_projectiles"] = _fire_charged_volley()
		"chain_spark":
			chain_spark_stacks += 1
			result["skill_text"] = "连锁弹 %d 枚/次攻击，单枚伤害 %d%%，投射物伤害 -12%%" % [
				chain_spark_stacks,
				int(round(_skill_float("chain_spark", "base_damage_multiplier", 1.15) * (1.0 + _stacked_percent_bonus(_skill_float("chain_spark", "damage_per_extra_stack", 0.20), maxi(0, chain_spark_stacks - 1))) * 100.0))
			]
		"orbit_blade":
			orbit_blade_stacks += 1
			result["skill_text"] = "两侧回旋弹各 %d 枚/次攻击，单枚伤害 %d%%" % [
				orbit_blade_stacks,
				int(round(_skill_float("orbit_blade", "base_damage_multiplier", 1.05) * (1.0 + _stacked_percent_bonus(_skill_float("orbit_blade", "damage_per_extra_stack", 0.18), maxi(0, orbit_blade_stacks - 1))) * 100.0))
			]
		"overload_burst":
			overload_burst_stacks += 1
			result["skill_text"] = "每 4 次攻击释放 %d 枚爆裂弹，单枚伤害 %d%%" % [
				_skill_int("overload_burst", "base_projectiles", 6) + overload_burst_stacks * _skill_int("overload_burst", "projectiles_per_stack", 2),
				int(round(_skill_float("overload_burst", "base_damage_multiplier", 2.50) * (1.0 + _stacked_percent_bonus(_skill_float("overload_burst", "damage_per_extra_stack", 0.25), maxi(0, overload_burst_stacks - 1))) * 100.0))
			]
		"homing_shards":
			homing_shard_stacks += 1
			var homing_old_move_speed := move_speed
			move_speed = maxf(MIN_TRADEOFF_MOVE_SPEED, move_speed * _skill_float("homing_shards", "move_speed_multiplier", HOMING_SPEED_MULTIPLIER))
			var homing_slow_percent := 0
			if homing_old_move_speed > 0.0:
				homing_slow_percent = int(round((homing_old_move_speed - move_speed) / homing_old_move_speed * 100.0))
			result["skill_text"] = "追踪碎片 %d 枚/次攻击，单枚伤害 %d%%，追踪强度 %.2f，当前移速 -%d%%（最低 80）" % [
				homing_shard_stacks,
				int(round(_skill_float("homing_shards", "base_damage_multiplier", 1.15) * (1.0 + _stacked_percent_bonus(_skill_float("homing_shards", "damage_per_extra_stack", 0.20), maxi(0, homing_shard_stacks - 1))) * 100.0)),
				_skill_float("homing_shards", "base_tracking", 4.8) + float(homing_shard_stacks) * _skill_float("homing_shards", "tracking_per_stack", 0.85),
				homing_slow_percent
			]
		"heavy_shot":
			heavy_shot_stacks += 1
			var heavy_old_size_bonus := upgrade_player_size_bonus
			upgrade_player_size_bonus = minf(PLAYER_SIZE_BONUS_CAP, upgrade_player_size_bonus + _scale_class_float_gain("player_size_bonus", _skill_float("heavy_shot", "player_size_bonus", HEAVY_SHOT_SIZE_BONUS)))
			_apply_fire_interval_multiplier(_skill_float("heavy_shot", "fire_interval_multiplier", HEAVY_SHOT_FIRE_INTERVAL_MULTIPLIER))
			var heavy_applied_size_percent := int(round((upgrade_player_size_bonus - heavy_old_size_bonus) * 100.0))
			var heavy_damage_percent := int(round(_skill_float("heavy_shot", "projectile_damage_percent", 0.20) * _get_class_gain_multiplier("projectile_damage_percent") * 100.0))
			result["skill_text"] = "投射物伤害 +%d%%，重弹 1 枚/3 次攻击，击退 +45%%，玩家体积 +%d%%（最高 +240%%），射击间隔 +10%%" % [heavy_damage_percent, heavy_applied_size_percent]
		"compressed_core":
			compressed_core_stacks += 1
			_apply_fire_interval_multiplier(_skill_float("compressed_core", "fire_interval_multiplier", 1.15))
			result["skill_text"] = "投射物 -1（最低 1），投射物伤害 x%.2f，射击间隔 +15%%" % _skill_float("compressed_core", "damage_multiplier", 2.50)
		"close_slash":
			close_slash_stacks += 1
			result["skill_text"] = "刀环半径 %d，冷却 %.2f 秒" % [
				int(round(_skill_float("close_slash", "base_radius", 72.0) + float(close_slash_stacks) * _skill_float("close_slash", "radius_per_stack", 22.0))),
				maxf(_skill_float("close_slash", "min_cooldown", 0.22), _skill_float("close_slash", "base_cooldown", 1.18) - float(close_slash_stacks) * _skill_float("close_slash", "cooldown_reduction", 0.12))
			]
		"pulse_field":
			pulse_field_stacks += 1
			result["skill_text"] = "脉冲半径 %d，冷却 %.2f 秒" % [
				int(round(_skill_float("pulse_field", "base_radius", 96.0) + float(pulse_field_stacks) * _skill_float("pulse_field", "radius_per_stack", 24.0))),
				maxf(_skill_float("pulse_field", "min_cooldown", 0.55), _skill_float("pulse_field", "base_cooldown", 2.25) - float(pulse_field_stacks) * _skill_float("pulse_field", "cooldown_reduction", 0.18))
			]
		"channel_beam":
			channel_beam_stacks += 1
			var beam_old_move_speed := move_speed
			move_speed = maxf(MIN_TRADEOFF_MOVE_SPEED, move_speed * _skill_float("channel_beam", "move_speed_multiplier", CHANNEL_BEAM_SPEED_MULTIPLIER))
			var beam_slow_percent := 0
			if beam_old_move_speed > 0.0:
				beam_slow_percent = int(round((beam_old_move_speed - move_speed) / beam_old_move_speed * 100.0))
			result["skill_text"] = "光束射程 %d，间隔 %.2f 秒，单跳伤害 %.1f%%，当前移速 -%d%%（最低 80）" % [
				int(round(_skill_float("channel_beam", "base_range", 330.0) + float(channel_beam_stacks) * _skill_float("channel_beam", "range_per_stack", 28.0))),
				_get_channel_beam_interval(),
				_skill_float("channel_beam", "base_damage_multiplier", 0.85) * (1.0 + _stacked_percent_bonus(_skill_float("channel_beam", "damage_per_extra_stack", 0.18), maxi(0, channel_beam_stacks - 1))) * 100.0,
				beam_slow_percent
			]
		"shatter_blast":
			shatter_blast_stacks += 1
			var shatter_radius := _scale_class_float_gain("explosion_radius", _skill_float("shatter_blast", "explosion_radius", 16.0))
			upgrade_explosion_radius_bonus += shatter_radius
			result["explosion_radius"] = int(round(shatter_radius))
			result["skill_text"] = "爆裂伤害 +55%%"
		"pierce_amp":
			pierce_amp_stacks += 1
			var pierce_amp_bonus := _scale_class_int_gain("pierce", _skill_int("pierce_amp", "pierce_bonus", 1))
			upgrade_pierce_bonus += pierce_amp_bonus
			result["skill_text"] = "穿透 +%d，投射物伤害 +55%%" % pierce_amp_bonus
		"conduit_coil":
			conduit_coil_stacks += 1
			result["skill_text"] = "光束伤害 +150%%，连锁/追踪伤害 +75%%，光束间隔 -0.03 秒"
		"guard_blade":
			guard_blade_stacks += 1
			var guard_shield := _scale_class_int_gain("shield", _skill_int("guard_blade", "base_shield", 16) + guard_blade_stacks * _skill_int("guard_blade", "shield_per_stack", 4))
			var guard_duration := _skill_float("guard_blade", "shield_duration", 4.0)
			apply_graze_shield(guard_shield, guard_duration)
			result["shield"] = guard_shield
			result["shield_duration"] = guard_duration
			result["skill_text"] = "近身技能伤害 +55%%，近身命中护盾 +4"
		"giant_echo":
			giant_echo_stacks += 1
			var echo_shield := _scale_class_int_gain("shield", _skill_int("giant_echo", "shield", 18))
			var echo_duration := _skill_float("giant_echo", "shield_duration", 4.0)
			apply_graze_shield(echo_shield, echo_duration)
			result["shield"] = echo_shield
			result["shield_duration"] = echo_duration
			result["skill_text"] = "玩家体积每 +10%%，近身刀环和脉冲场伤害 +20%%"
		"crimson_leech":
			crimson_leech_stacks += 1
			var crimson_cost := mini(_skill_int("crimson_leech", "health_cost", 15), maxi(0, health - 1))
			if crimson_cost > 0:
				var crimson_old_health := health
				health -= crimson_cost
				GameManager.update_player_health(health, max_health)
				_emit_low_life_trigger_if_crossed(crimson_old_health, health)
				CombatFeedback.show_damage(get_tree().current_scene, global_position, crimson_cost, Color(1.0, 0.18, 0.30, 1.0))
				CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(1.0, 0.16, 0.34, 0.74), 1.05)
			result["skill_text"] = "当前生命 -%d（最低 1）；生命低于 35%% 时，投射物伤害 +60%%、吸血 +8%%" % crimson_cost
		"elite_reactor":
			var elite_stack := int(upgrade_stacks.get("elite_reactor", 0))
			var elite_shield := elite_stack * _skill_int("elite_reactor", "shield_per_stack", 18)
			result["skill_text"] = "击败精英或 Boss 时清除敌弹，护盾 +%d，持续 %.1f 秒" % [elite_shield, _skill_float("elite_reactor", "shield_duration", 4.0)]
		"last_stand_matrix":
			var last_stand_stack := int(upgrade_stacks.get("last_stand_matrix", 0))
			var last_stand_shield := last_stand_stack * _skill_int("last_stand_matrix", "shield_per_stack", 26)
			result["skill_text"] = "每关首次生命低于 35%% 时清除敌弹，护盾 +%d，持续 %.1f 秒" % [last_stand_shield, _skill_float("last_stand_matrix", "shield_duration", 4.0)]
			if _is_low_life_for_trigger():
				_handle_last_stand_trigger()
		"momentum_cache":
			var momentum_stack := int(upgrade_stacks.get("momentum_cache", 0))
			result["skill_text"] = "游走达到 %d 层时，护盾 +%d，持续 %.1f 秒，冷却 %.1f 秒" % [
				_skill_int("momentum_cache", "required_movement_tier", 8),
				momentum_stack * _skill_int("momentum_cache", "shield_per_stack", 10),
				_skill_float("momentum_cache", "shield_duration", 2.5),
				_skill_float("momentum_cache", "cooldown", 9.0)
			]
		"anchor_discharge":
			var anchor_stack := int(upgrade_stacks.get("anchor_discharge", 0))
			result["skill_text"] = "静立达到 %d 层时清除敌弹，护盾 +%d，持续 %.1f 秒，冷却 %.1f 秒" % [
				_skill_int("anchor_discharge", "required_stationary_tier", 6),
				anchor_stack * _skill_int("anchor_discharge", "shield_per_stack", 8),
				_skill_float("anchor_discharge", "shield_duration", 2.5),
				_skill_float("anchor_discharge", "cooldown", 12.0)
			]
		"form_focused":
			var focused_damage_bonus := _scale_class_int_gain("damage_flat", 8)
			upgrade_damage_bonus += focused_damage_bonus
			projectile_damage += focused_damage_bonus
			result["damage_bonus"] = focused_damage_bonus
			result["skill_text"] = "聚能强化：投射物伤害 +%d" % focused_damage_bonus
		"form_scatter":
			var scatter_projectile_bonus := _scale_class_int_gain("projectile_count", 1)
			upgrade_projectile_count_bonus += scatter_projectile_bonus
			projectile_count += scatter_projectile_bonus
			result["skill_text"] = "散射强化：投射物 +%d" % scatter_projectile_bonus
		"form_piercing":
			var form_pierce_bonus := _scale_class_int_gain("pierce", 1)
			upgrade_pierce_bonus += form_pierce_bonus
			result["skill_text"] = "穿透强化：投射物穿透 +%d" % form_pierce_bonus
		"form_burst":
			var form_burst_radius := _scale_class_float_gain("explosion_radius", _skill_float("form_burst", "explosion_radius", 14.0))
			upgrade_explosion_radius_bonus += form_burst_radius
			result["explosion_radius"] = int(round(form_burst_radius))
			result["skill_text"] = "爆裂强化：爆裂范围 +%d" % int(round(form_burst_radius))
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
	var life_steal_percent := _get_total_life_steal_percent()
	if life_steal_percent <= 0 or health <= 0 or health >= max_health:
		return
	var cap_remaining: int = _get_life_steal_cap_per_second() - life_steal_recovered_this_second
	if cap_remaining <= 0:
		return
	var raw_heal: int = maxi(1, int(round(float(hit_damage) * float(life_steal_percent) / 100.0)))
	var heal_amount: int = mini(raw_heal, mini(cap_remaining, max_health - health))
	if heal_amount <= 0:
		return
	health = min(max_health, health + heal_amount)
	life_steal_recovered_this_second += heal_amount
	GameManager.update_player_health(health, max_health)
	_emit_build_summary()

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
		var spread: float = _get_primary_projectile_spread_angle(index, total_projectiles)
		_spawn_player_projectile(base_direction.rotated(spread), 1.0, [])
	_fire_extra_skill_projectiles(base_direction)

func _get_primary_projectile_spread_angle(index: int, total_projectiles: int) -> float:
	if total_projectiles <= 1 or index == 0:
		return 0.0
	var pair_index := int(ceil(float(index) / 2.0))
	var side := -1.0 if index % 2 == 1 else 1.0
	return deg_to_rad(equipment_spread_degrees * float(pair_index) * side)

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
		var affix_value := _scale_class_int_gain(str(affix["id"]), int(affix["value"]))
		match affix["id"]:
			"damage":
				equipment_damage_bonus += affix_value
			"attack_speed":
				equipment_attack_speed_bonus += affix_value
			"max_health":
				equipment_health_bonus += affix_value
				max_health += affix_value
				health += affix_value
			"move_speed":
				equipment_move_speed_bonus += affix_value
				move_speed += affix_value
			"critical_chance":
				equipment_critical_chance_bonus += affix_value
			"life_steal":
				equipment_life_steal_bonus += affix_value
			"gold_bonus":
				equipment_gold_bonus += affix_value
			"projectile_count":
				affix_projectile_count_bonus += affix_value
			"pierce":
				affix_pierce_bonus += affix_value
			"explosion_radius":
				affix_explosion_radius_bonus += affix_value
	fire_interval = _calculate_fire_interval()

func _remove_equipment_stats(equipment: Dictionary) -> void:
	if str(equipment.get("slot", "weapon")) == "weapon":
		_reset_weapon_form()
	for affix in equipment.get("affixes", []):
		var affix_value := _scale_class_int_gain(str(affix["id"]), int(affix["value"]))
		match affix["id"]:
			"damage":
				equipment_damage_bonus -= affix_value
			"attack_speed":
				equipment_attack_speed_bonus -= affix_value
			"max_health":
				equipment_health_bonus -= affix_value
				max_health -= affix_value
				health = min(health, max_health)
			"move_speed":
				equipment_move_speed_bonus -= affix_value
				move_speed -= affix_value
			"critical_chance":
				equipment_critical_chance_bonus -= affix_value
			"life_steal":
				equipment_life_steal_bonus -= affix_value
			"gold_bonus":
				equipment_gold_bonus -= affix_value
			"projectile_count":
				affix_projectile_count_bonus -= affix_value
			"pierce":
				affix_pierce_bonus -= affix_value
			"explosion_radius":
				affix_explosion_radius_bonus -= affix_value
	fire_interval = _calculate_fire_interval()

func _calculate_fire_interval() -> float:
	var speed_multiplier := 1.0 + float(equipment_attack_speed_bonus) / 100.0
	return max(0.05, base_fire_interval / max(speed_multiplier, 0.1))

func _apply_fire_interval_multiplier(multiplier: float) -> void:
	base_fire_interval = maxf(0.06, base_fire_interval * maxf(0.1, multiplier))
	fire_interval = _calculate_fire_interval()

func _get_base_projectile_damage() -> int:
	return max(1, int(round(float(projectile_damage + equipment_damage_bonus + equipment_form_damage_bonus) * equipment_damage_multiplier)))

func _stacked_percent_bonus(percent: float, stacks: int) -> float:
	if stacks <= 0:
		return 0.0
	return percent * float(stacks)

func _skill_float(upgrade_id: String, key: String, fallback: float) -> float:
	return float(SkillCatalog.get_upgrade_value(upgrade_id, key, fallback))

func _skill_int(upgrade_id: String, key: String, fallback: int) -> int:
	return int(SkillCatalog.get_upgrade_value(upgrade_id, key, fallback))

func _get_projectile_damage_upgrade_multiplier() -> float:
	var damage_stacks := int(upgrade_stacks.get("damage", 0))
	var piercing_rounds_stacks := int(upgrade_stacks.get("piercing_rounds", 0))
	var bonus := 0.0
	bonus += _stacked_percent_bonus(_skill_float("damage", "projectile_damage_percent", DAMAGE_UPGRADE_PERCENT) * _get_class_gain_multiplier("projectile_damage_percent"), damage_stacks)
	bonus -= _stacked_percent_bonus(_skill_float("attack_speed", "projectile_damage_penalty", ATTACK_SPEED_DAMAGE_PENALTY), upgrade_attack_speed_stacks)
	bonus -= _stacked_percent_bonus(_skill_float("light_frame", "projectile_damage_penalty", LIGHT_FRAME_DAMAGE_PENALTY), light_frame_stacks)
	bonus -= _stacked_percent_bonus(_skill_float("piercing_rounds", "projectile_damage_penalty", PIERCING_DAMAGE_PENALTY), piercing_rounds_stacks)
	bonus -= _stacked_percent_bonus(_skill_float("chain_spark", "projectile_damage_penalty", CHAIN_DAMAGE_PENALTY), chain_spark_stacks)
	bonus += _stacked_percent_bonus(_skill_float("heavy_shot", "projectile_damage_percent", 0.20) * _get_class_gain_multiplier("projectile_damage_percent"), heavy_shot_stacks)
	bonus += _stacked_percent_bonus(_skill_float("compressed_core", "damage_multiplier", 2.50) - 1.0, compressed_core_stacks)
	return maxf(0.20, 1.0 + bonus)

func _get_flow_damage_multiplier(_include_stationary_bonus: bool = false) -> float:
	var bonus := _get_projectile_damage_upgrade_multiplier() - 1.0
	bonus += _get_mass_resonance_damage_bonus()
	bonus += _get_light_resonance_damage_bonus()
	bonus += _get_slow_resonance_damage_bonus()
	bonus += _get_haste_resonance_damage_bonus()
	bonus += _get_blood_pact_damage_bonus()
	bonus += _get_crimson_leech_damage_bonus()
	bonus += _get_movement_focus_damage_bonus()
	bonus += _stacked_percent_bonus(_skill_float("pierce_amp", "damage_per_stack", PIERCE_DAMAGE_PER_STACK), pierce_amp_stacks)
	return maxf(0.20, 1.0 + bonus)

func _get_mass_resonance_damage_bonus() -> float:
	if mass_resonance_stacks <= 0:
		return 0.0
	var player_size_bonus := maxf(0.0, _get_player_size_multiplier() - 1.0)
	var per_stack_bonus := (player_size_bonus / 0.10) * _skill_float("mass_resonance", "damage_per_10_percent", MASS_DAMAGE_PER_10_PERCENT)
	return _stacked_percent_bonus(per_stack_bonus, mass_resonance_stacks) * _get_class_multiplier("mass_resonance_damage")

func _get_light_resonance_damage_bonus() -> float:
	if light_resonance_stacks <= 0:
		return 0.0
	var player_size_penalty := maxf(0.0, 1.0 - _get_player_size_multiplier())
	var per_stack_bonus := (player_size_penalty / 0.10) * _skill_float("light_resonance", "damage_per_10_percent", SMALL_DAMAGE_PER_10_PERCENT)
	return _stacked_percent_bonus(per_stack_bonus, light_resonance_stacks)

func _get_light_resonance_crit_bonus() -> int:
	if light_resonance_stacks <= 0:
		return 0
	var player_size_penalty := maxf(0.0, 1.0 - _get_player_size_multiplier())
	return int(round((player_size_penalty / 0.10) * float(_skill_int("light_resonance", "crit_per_10_percent", SMALL_CRIT_PER_10_PERCENT)) * float(light_resonance_stacks)))

func _get_slow_resonance_damage_bonus() -> float:
	if slow_resonance_stacks <= 0 or base_move_speed <= 0.0:
		return 0.0
	var slow_ratio := clampf((base_move_speed - move_speed) / base_move_speed, 0.0, 0.90)
	var per_stack_bonus := (slow_ratio / 0.10) * _skill_float("slow_resonance", "damage_per_10_percent", SLOW_DAMAGE_PER_10_PERCENT)
	return _stacked_percent_bonus(per_stack_bonus, slow_resonance_stacks)

func _get_haste_resonance_damage_bonus() -> float:
	if haste_resonance_stacks <= 0 or base_move_speed <= 0.0:
		return 0.0
	var fast_ratio := maxf(0.0, (move_speed - base_move_speed) / base_move_speed)
	var per_stack_bonus := (fast_ratio / 0.10) * _skill_float("haste_resonance", "damage_per_10_percent", FAST_DAMAGE_PER_10_PERCENT)
	return _stacked_percent_bonus(per_stack_bonus, haste_resonance_stacks)

func _get_haste_resonance_crit_bonus() -> int:
	if haste_resonance_stacks <= 0 or base_move_speed <= 0.0:
		return 0
	var fast_ratio := maxf(0.0, (move_speed - base_move_speed) / base_move_speed)
	return int(round((fast_ratio / 0.10) * float(_skill_int("haste_resonance", "crit_per_10_percent", FAST_CRIT_PER_10_PERCENT)) * float(haste_resonance_stacks)))

func _get_rapid_skill_damage_bonus() -> float:
	if rapid_resonance_stacks <= 0 or initial_fire_interval <= 0.0:
		return 0.0
	var rapid_ratio := maxf(0.0, (initial_fire_interval - fire_interval) / initial_fire_interval)
	var per_stack_bonus := (rapid_ratio / 0.10) * _skill_float("rapid_resonance", "skill_damage_per_10_percent", RAPID_SKILL_DAMAGE_PER_10_PERCENT)
	return _stacked_percent_bonus(per_stack_bonus, rapid_resonance_stacks)

func _get_reflow_skill_damage_bonus() -> float:
	var movement_tier := _get_movement_focus_tier()
	if reflow_shards_stacks <= 0 or movement_tier <= 0:
		return 0.0
	var per_stack_bonus := float(movement_tier) * _skill_float("reflow_shards", "skill_damage_per_movement_tier", 0.12)
	return _stacked_percent_bonus(per_stack_bonus, reflow_shards_stacks)

func _get_blood_pact_damage_bonus() -> float:
	if blood_pact_stacks <= 0 or max_health <= 0:
		return 0.0
	var missing_ratio := clampf(float(max_health - health) / float(max_health), 0.0, 0.95)
	var per_stack_bonus := (missing_ratio / 0.10) * _skill_float("blood_pact", "damage_per_10_percent", BLOOD_DAMAGE_PER_10_PERCENT)
	return _stacked_percent_bonus(per_stack_bonus, blood_pact_stacks)

func _is_crimson_leech_active() -> bool:
	if crimson_leech_stacks <= 0 or max_health <= 0:
		return false
	return float(health) / float(max_health) <= _skill_float("crimson_leech", "low_life_threshold", 0.35)

func _get_crimson_leech_damage_bonus() -> float:
	if not _is_crimson_leech_active():
		return 0.0
	return _stacked_percent_bonus(_skill_float("crimson_leech", "low_life_damage_bonus", 0.60), crimson_leech_stacks)

func _get_blood_pact_crit_bonus() -> int:
	if blood_pact_stacks <= 0 or max_health <= 0:
		return 0
	var missing_ratio := clampf(float(max_health - health) / float(max_health), 0.0, 0.95)
	return int(round((missing_ratio / 0.10) * float(_skill_int("blood_pact", "crit_per_10_percent", BLOOD_CRIT_PER_10_PERCENT)) * float(blood_pact_stacks)))

func _get_player_size_multiplier() -> float:
	var size_bonus := clampf(upgrade_player_size_bonus, PLAYER_SIZE_PENALTY_CAP, PLAYER_SIZE_BONUS_CAP)
	return clampf(1.0 + size_bonus, 1.0 + PLAYER_SIZE_PENALTY_CAP, 1.0 + PLAYER_SIZE_BONUS_CAP)

func _get_stationary_focus_tier() -> int:
	if still_focus_stacks <= 0:
		return 0
	return clampi(int(floor(stationary_focus_time / _skill_float("still_focus", "interval", STILL_FOCUS_INTERVAL))), 0, _skill_int("still_focus", "max_tier", STILL_FOCUS_MAX_TIER))

func _get_stationary_crit_bonus() -> int:
	var tier := _get_stationary_focus_tier()
	if tier <= 0:
		return 0
	var crit_bonus := tier * _skill_int("still_focus", "crit_per_tier", STILL_FOCUS_CRIT_PER_TIER) * still_focus_stacks
	return int(round(float(crit_bonus) * _get_class_multiplier("stationary_crit")))

func _get_movement_focus_tier() -> int:
	if motion_focus_stacks <= 0:
		return 0
	return clampi(int(floor(movement_focus_time / _skill_float("motion_focus", "interval", MOVEMENT_FOCUS_INTERVAL))), 0, _skill_int("motion_focus", "max_tier", MOVEMENT_FOCUS_MAX_TIER))

func _get_movement_focus_damage_bonus() -> float:
	var tier := _get_movement_focus_tier()
	if tier <= 0:
		return 0.0
	var per_stack_bonus := float(tier) * _skill_float("motion_focus", "damage_per_tier", MOVEMENT_FOCUS_DAMAGE_PER_TIER)
	return _stacked_percent_bonus(per_stack_bonus, motion_focus_stacks)

func _get_movement_focus_crit_bonus() -> int:
	var tier := _get_movement_focus_tier()
	if tier <= 0:
		return 0
	return tier * _skill_int("motion_focus", "crit_per_tier", MOVEMENT_FOCUS_CRIT_PER_TIER) * motion_focus_stacks

func _get_giant_echo_close_damage_bonus() -> float:
	if giant_echo_stacks <= 0:
		return 0.0
	var player_size_bonus := maxf(0.0, _get_player_size_multiplier() - 1.0)
	var per_stack_bonus := (player_size_bonus / 0.10) * _skill_float("giant_echo", "close_damage_per_10_percent", 0.20)
	return _stacked_percent_bonus(per_stack_bonus, giant_echo_stacks)

func _get_class_multiplier(key: String) -> float:
	return float(class_multipliers.get(key, 1.0))

func _get_class_gain_multiplier(key: String) -> float:
	return maxf(0.0, float(class_gain_multipliers.get(key, 1.0)))

func _scale_class_int_gain(key: String, base_value: int) -> int:
	if base_value == 0:
		return 0
	var multiplier := _get_class_gain_multiplier(key)
	if multiplier <= 0.0:
		return 0
	var sign := 1 if base_value > 0 else -1
	var scaled := int(round(abs(base_value) * multiplier))
	if scaled == 0:
		scaled = 1
	return sign * scaled

func _scale_class_float_gain(key: String, base_value: float) -> float:
	if base_value == 0.0:
		return 0.0
	return base_value * _get_class_gain_multiplier(key)

func _get_light_edge_critical_damage_multiplier() -> float:
	if light_edge_stacks <= 0:
		return 1.0
	var player_size_penalty := maxf(0.0, 1.0 - _get_player_size_multiplier())
	var per_stack_bonus := (player_size_penalty / 0.10) * _skill_float("light_edge", "crit_damage_per_10_percent", 0.25)
	return 1.0 + _stacked_percent_bonus(per_stack_bonus, light_edge_stacks)

func _get_critical_damage_multiplier() -> float:
	return 2.0 * _get_light_edge_critical_damage_multiplier()

func _get_total_life_steal_percent() -> int:
	var total := equipment_life_steal_bonus
	if _is_crimson_leech_active():
		total += crimson_leech_stacks * _skill_int("crimson_leech", "low_life_life_steal", 8)
	return total

func _get_life_steal_cap_per_second() -> int:
	var life_steal_percent := _get_total_life_steal_percent()
	if life_steal_percent <= 0:
		return 0
	return maxi(1, int(round(float(max_health) * LIFE_STEAL_BASE_CAP_RATIO + float(life_steal_percent) * LIFE_STEAL_CAP_PER_PERCENT)))

func _get_close_slash_cooldown() -> float:
	return maxf(
		_skill_float("close_slash", "min_cooldown", 0.22),
		_skill_float("close_slash", "base_cooldown", 1.18) - float(close_slash_stacks) * _skill_float("close_slash", "cooldown_reduction", 0.12)
	)

func _get_pulse_field_cooldown() -> float:
	return maxf(
		_skill_float("pulse_field", "min_cooldown", 0.55),
		_skill_float("pulse_field", "base_cooldown", 2.25) - float(pulse_field_stacks) * _skill_float("pulse_field", "cooldown_reduction", 0.18)
	)

func _get_channel_beam_interval() -> float:
	return maxf(
		0.05,
		_skill_float("channel_beam", "base_interval", 0.32) - float(channel_beam_stacks) * _skill_float("channel_beam", "interval_reduction", 0.035) - float(conduit_coil_stacks) * _skill_float("conduit_coil", "beam_interval_reduction", CONDUIT_BEAM_INTERVAL_REDUCTION)
	)

func _get_total_crit_bonus() -> int:
	return equipment_critical_chance_bonus + class_critical_chance_bonus + _get_stationary_crit_bonus() + _get_light_resonance_crit_bonus() + _get_haste_resonance_crit_bonus() + _get_blood_pact_crit_bonus() + _get_movement_focus_crit_bonus()

func _get_total_projectile_count() -> int:
	var compressed_penalty := compressed_core_stacks * _skill_int("compressed_core", "projectile_count_penalty", 1)
	return maxi(1, projectile_count + equipment_projectile_count_bonus + affix_projectile_count_bonus - compressed_penalty)

func _get_total_pierce() -> int:
	return equipment_pierce_bonus + affix_pierce_bonus + upgrade_pierce_bonus

func _roll_projectile_damage() -> Dictionary:
	var damage := maxi(1, int(round(float(_get_base_projectile_damage()) * _get_flow_damage_multiplier())))
	var critical_chance := clampf(float(_get_total_crit_bonus()) / 100.0, 0.0, 0.95)
	var is_critical := randf() < critical_chance
	if is_critical:
		damage = maxi(1, int(round(float(damage) * _get_critical_damage_multiplier())))
	return {
		"damage": damage,
		"is_critical": is_critical
	}

func _get_final_projectile_damage() -> int:
	return maxi(1, int(round(float(_get_base_projectile_damage()) * _get_flow_damage_multiplier())))

func _get_total_explosion_radius() -> float:
	return minf(EXPLOSION_RADIUS_CAP, equipment_explosion_radius + affix_explosion_radius_bonus + upgrade_explosion_radius_bonus + class_explosion_radius_bonus)

func _get_total_explosion_damage_ratio() -> float:
	var total_radius := _get_total_explosion_radius()
	if total_radius <= 0.0:
		return 0.0
	var ratio := equipment_explosion_damage_ratio
	if affix_explosion_radius_bonus > 0.0 or upgrade_explosion_radius_bonus > 0.0 or class_explosion_radius_bonus > 0.0:
		ratio = maxf(ratio, 0.25)
		if equipment_explosion_damage_ratio > 0.0:
			ratio += 0.08
	if shatter_blast_stacks > 0:
		ratio *= 1.0 + _stacked_percent_bonus(_skill_float("shatter_blast", "explosion_damage_per_stack", SHATTER_EXPLOSION_DAMAGE_PER_STACK), shatter_blast_stacks)
	return ratio

func _apply_weapon_form(form: Dictionary) -> void:
	if form.is_empty():
		_reset_weapon_form()
		return
	equipment_projectile_count_bonus = _scale_class_int_gain("projectile_count", int(form.get("projectile_bonus", 0)))
	equipment_pierce_bonus = _scale_class_int_gain("pierce", int(form.get("pierce", 0)))
	equipment_form_damage_bonus = _scale_class_int_gain("damage_flat", int(form.get("damage_bonus", 0)))
	equipment_damage_multiplier = float(form.get("damage_multiplier", 1.0))
	equipment_spread_degrees = float(form.get("spread_degrees", 8.0))
	equipment_explosion_radius = _scale_class_float_gain("explosion_radius", float(form.get("explosion_radius", 0.0)))
	equipment_explosion_damage_ratio = float(form.get("explosion_damage_ratio", 0.0))

func _reset_weapon_form() -> void:
	equipment_projectile_count_bonus = 0
	equipment_pierce_bonus = 0
	equipment_form_damage_bonus = 0
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
	if upgrade_damage_bonus >= 10 or _get_projectile_damage_upgrade_multiplier() >= 1.20:
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
		projectile.explosion_radius = minf(EXPLOSION_RADIUS_CAP, 34.0 + float(overload_burst_stacks) * 5.0)
	projectile.explosion_damage = int(round(float(projectile.damage) * _get_total_explosion_damage_ratio()))
	if extra_tags.has("overload") and projectile.explosion_damage <= 0:
		projectile.explosion_damage = maxi(1, int(round(float(projectile.damage) * (0.30 + float(overload_burst_stacks) * 0.04))))
	if extra_tags.has("chain"):
		projectile.lifetime = maxf(projectile.lifetime, 1.45 + float(chain_spark_stacks) * _skill_float("chain_spark", "lifetime_bonus", 0.08))
		projectile.knockback_force *= 1.0 + float(chain_spark_stacks) * 0.04 + float(conduit_coil_stacks) * 0.08
	if extra_tags.has("orbit"):
		projectile.lifetime = maxf(projectile.lifetime, 1.35 + float(orbit_blade_stacks) * _skill_float("orbit_blade", "lifetime_bonus", 0.08))
		projectile.knockback_force *= 1.0 + float(orbit_blade_stacks) * 0.05
	projectile.source_player = self
	projectile.life_steal_percent = _get_total_life_steal_percent()
	projectile.power_tags = _get_projectile_power_tags(projectile)
	if extra_tags.has("homing"):
		projectile.homing_strength = _skill_float("homing_shards", "base_tracking", 4.8) + float(homing_shard_stacks) * _skill_float("homing_shards", "tracking_per_stack", 0.85)
		projectile.homing_strength += float(conduit_coil_stacks) * 0.90
		projectile.lifetime = maxf(projectile.lifetime, 1.75)
	if extra_tags.has("heavy"):
		projectile.speed *= 0.78
		projectile.knockback_force *= 1.45 + float(heavy_shot_stacks) * 0.12
		projectile.lifetime = maxf(projectile.lifetime, 1.65)
		if projectile.explosion_radius <= 0.0 and heavy_shot_stacks >= 2:
			projectile.explosion_radius = minf(EXPLOSION_RADIUS_CAP, 26.0 + float(heavy_shot_stacks) * 5.0)
			projectile.explosion_damage = maxi(projectile.explosion_damage, int(round(float(projectile.damage) * 0.28)))
	for tag in extra_tags:
		if not projectile.power_tags.has(tag):
			projectile.power_tags.append(tag)
	get_tree().current_scene.add_child(projectile)

func _fire_extra_skill_projectiles(base_direction: Vector2) -> void:
	var fast_skill_bonus := _get_rapid_skill_damage_bonus() + _get_reflow_skill_damage_bonus()
	var chain_count := chain_spark_stacks
	var chain_bonus := fast_skill_bonus
	chain_bonus += _stacked_percent_bonus(_skill_float("chain_spark", "damage_per_extra_stack", 0.20), maxi(0, chain_spark_stacks - 1))
	chain_bonus += _stacked_percent_bonus(_skill_float("conduit_coil", "chain_damage_per_stack", CONDUIT_CHAIN_DAMAGE_PER_STACK), conduit_coil_stacks)
	var chain_multiplier := _skill_float("chain_spark", "base_damage_multiplier", 1.15) * (1.0 + chain_bonus) * _get_class_multiplier("chain_orbit_homing_damage")
	for index in range(chain_count):
		var angle := deg_to_rad(18.0 + float(index) * 10.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		_spawn_player_projectile(base_direction.rotated(angle * side), chain_multiplier, ["chain"])
	var orbit_count := orbit_blade_stacks
	var orbit_bonus := fast_skill_bonus + _stacked_percent_bonus(_skill_float("orbit_blade", "damage_per_extra_stack", 0.18), maxi(0, orbit_blade_stacks - 1))
	var orbit_multiplier := _skill_float("orbit_blade", "base_damage_multiplier", 1.05) * (1.0 + orbit_bonus) * _get_class_multiplier("chain_orbit_homing_damage")
	for index in range(orbit_count):
		var side_angle := deg_to_rad(82.0 + float(index) * 8.0)
		_spawn_player_projectile(base_direction.rotated(side_angle), orbit_multiplier, ["orbit"])
		_spawn_player_projectile(base_direction.rotated(-side_angle), orbit_multiplier, ["orbit"])
	if overload_burst_stacks > 0 and attack_sequence % 4 == 0:
		var bullet_count := _skill_int("overload_burst", "base_projectiles", 6) + overload_burst_stacks * _skill_int("overload_burst", "projectiles_per_stack", 2)
		var overload_bonus := fast_skill_bonus + _stacked_percent_bonus(_skill_float("overload_burst", "damage_per_extra_stack", 0.25), maxi(0, overload_burst_stacks - 1))
		var overload_multiplier := _skill_float("overload_burst", "base_damage_multiplier", 2.50) * (1.0 + overload_bonus) * _get_class_multiplier("heavy_overload_damage")
		for index in range(bullet_count):
			var angle := TAU * float(index) / float(bullet_count)
			_spawn_player_projectile(Vector2.RIGHT.rotated(angle), overload_multiplier, ["overload", "blast"])
	if homing_shard_stacks > 0:
		var homing_count := homing_shard_stacks
		var homing_bonus := fast_skill_bonus
		homing_bonus += _stacked_percent_bonus(_skill_float("homing_shards", "damage_per_extra_stack", 0.20), maxi(0, homing_shard_stacks - 1))
		homing_bonus += _stacked_percent_bonus(_skill_float("conduit_coil", "chain_damage_per_stack", CONDUIT_CHAIN_DAMAGE_PER_STACK), conduit_coil_stacks)
		var homing_multiplier := _skill_float("homing_shards", "base_damage_multiplier", 1.15) * (1.0 + homing_bonus) * _get_class_multiplier("chain_orbit_homing_damage")
		for index in range(homing_count):
			var angle := deg_to_rad((float(index) - float(homing_count - 1) * 0.5) * 24.0)
			_spawn_player_projectile(base_direction.rotated(angle), homing_multiplier, ["homing"])
	if heavy_shot_stacks > 0 and attack_sequence % 3 == 0:
		var heavy_multiplier := _skill_float("heavy_shot", "damage_multiplier", 2.20) * (1.0 + _stacked_percent_bonus(_skill_float("heavy_shot", "damage_per_extra_stack", 0.25), maxi(0, heavy_shot_stacks - 1))) * _get_class_multiplier("heavy_overload_damage")
		_spawn_player_projectile(base_direction, heavy_multiplier, ["heavy", "charged"])

func _update_close_range_skills(delta: float) -> void:
	if close_slash_cooldown > 0.0:
		close_slash_cooldown -= delta
	if pulse_field_cooldown > 0.0:
		pulse_field_cooldown -= delta
	if close_slash_stacks > 0 and close_slash_cooldown <= 0.0:
		_fire_close_slash()
		close_slash_cooldown = _get_close_slash_cooldown()
	if pulse_field_stacks > 0 and pulse_field_cooldown <= 0.0:
		_fire_pulse_field()
		pulse_field_cooldown = _get_pulse_field_cooldown()

func _update_channel_skill(delta: float) -> void:
	if channel_beam_stacks <= 0:
		return
	channel_beam_tick_timer -= delta
	if channel_beam_tick_timer > 0.0:
		return
	channel_beam_tick_timer = _get_channel_beam_interval()
	_fire_channel_beam_tick()

func _update_motion_focus(delta: float, input_direction: Vector2) -> void:
	var old_tier := _get_stationary_focus_tier()
	var old_movement_tier := _get_movement_focus_tier()
	var is_moving := input_direction.length_squared() > 0.01 or knockback_velocity.length_squared() > 100.0
	var still_interval := _skill_float("still_focus", "interval", STILL_FOCUS_INTERVAL)
	var still_max_tier := _skill_int("still_focus", "max_tier", STILL_FOCUS_MAX_TIER)
	var motion_interval := _skill_float("motion_focus", "interval", MOVEMENT_FOCUS_INTERVAL)
	var motion_max_tier := _skill_int("motion_focus", "max_tier", MOVEMENT_FOCUS_MAX_TIER)
	if is_moving:
		stationary_focus_time = maxf(0.0, stationary_focus_time - still_interval * delta * float(class_focus_decay.get("stationary_move_decay_multiplier", 1.0)))
		movement_focus_time = minf(motion_interval * float(motion_max_tier), movement_focus_time + delta)
	else:
		stationary_focus_time = minf(still_interval * float(still_max_tier), stationary_focus_time + delta)
		movement_focus_time = maxf(0.0, movement_focus_time - motion_interval * delta)
	var new_tier := _get_stationary_focus_tier()
	var new_movement_tier := _get_movement_focus_tier()
	if new_tier != old_tier or new_tier != last_stationary_focus_tier or new_movement_tier != old_movement_tier or new_movement_tier != last_movement_focus_tier:
		GameManager.emit_gameplay_trigger("focus_tier_changed", {
			"old_stationary_tier": old_tier,
			"stationary_tier": new_tier,
			"old_movement_tier": old_movement_tier,
			"movement_tier": new_movement_tier
		})
		last_stationary_focus_tier = new_tier
		last_movement_focus_tier = new_movement_tier
		_emit_build_summary()

func _update_player_body_scale() -> void:
	scale = Vector2.ONE * _get_player_size_multiplier()

func _fire_close_slash() -> void:
	var stationary_tier := _get_stationary_focus_tier()
	var radius := (_skill_float("close_slash", "base_radius", 72.0) + float(close_slash_stacks) * _skill_float("close_slash", "radius_per_stack", 22.0) + float(stationary_tier) * 6.0) * _get_class_multiplier("close_radius")
	var close_bonus := _get_giant_echo_close_damage_bonus()
	close_bonus += _stacked_percent_bonus(_skill_float("close_slash", "damage_per_extra_stack", 0.25), maxi(0, close_slash_stacks - 1))
	close_bonus += _stacked_percent_bonus(_skill_float("guard_blade", "close_damage_per_stack", GUARD_CLOSE_DAMAGE_PER_STACK), guard_blade_stacks)
	var damage_multiplier := _skill_float("close_slash", "base_damage_multiplier", 1.20) * (1.0 + close_bonus) * _get_class_multiplier("close_damage")
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
	var radius := (_skill_float("pulse_field", "base_radius", 96.0) + float(pulse_field_stacks) * _skill_float("pulse_field", "radius_per_stack", 24.0) + float(stationary_tier) * 8.0) * _get_class_multiplier("close_radius")
	var close_bonus := _get_giant_echo_close_damage_bonus()
	close_bonus += _stacked_percent_bonus(_skill_float("pulse_field", "damage_per_extra_stack", 0.20), maxi(0, pulse_field_stacks - 1))
	close_bonus += _stacked_percent_bonus(_skill_float("guard_blade", "close_damage_per_stack", GUARD_CLOSE_DAMAGE_PER_STACK), guard_blade_stacks)
	var damage_multiplier := _skill_float("pulse_field", "base_damage_multiplier", 1.0) * (1.0 + close_bonus) * _get_class_multiplier("close_damage")
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
	var max_range := _skill_float("channel_beam", "base_range", 330.0) + float(channel_beam_stacks) * _skill_float("channel_beam", "range_per_stack", 28.0) + float(stationary_tier) * 18.0
	var distance := global_position.distance_to(target.global_position)
	if distance > max_range:
		return
	var beam_bonus := _stacked_percent_bonus(_skill_float("channel_beam", "damage_per_extra_stack", 0.18), maxi(0, channel_beam_stacks - 1))
	beam_bonus += _stacked_percent_bonus(_skill_float("conduit_coil", "beam_damage_per_stack", CONDUIT_BEAM_DAMAGE_PER_STACK), conduit_coil_stacks)
	var beam_multiplier := _skill_float("channel_beam", "base_damage_multiplier", 0.85) * (1.0 + beam_bonus)
	var damage := maxi(1, int(round(float(_get_base_projectile_damage()) * beam_multiplier * _get_flow_damage_multiplier(true))))
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
		"final_projectile_damage": _get_final_projectile_damage(),
		"projectiles": _get_total_projectile_count(),
		"pierce": _get_total_pierce(),
		"explosion_radius": int(round(_get_total_explosion_radius())),
		"player_size_bonus": int(round((_get_player_size_multiplier() - 1.0) * 100.0)),
		"flow_damage_bonus_percent": int(round((_get_flow_damage_multiplier() - 1.0) * 100.0)),
		"mass_damage_bonus_percent": int(round(_get_mass_resonance_damage_bonus() * 100.0)),
		"light_damage_bonus_percent": int(round(_get_light_resonance_damage_bonus() * 100.0)),
		"light_critical_bonus": _get_light_resonance_crit_bonus(),
		"slow_damage_bonus_percent": int(round(_get_slow_resonance_damage_bonus() * 100.0)),
		"haste_damage_bonus_percent": int(round(_get_haste_resonance_damage_bonus() * 100.0)),
		"haste_critical_bonus": _get_haste_resonance_crit_bonus(),
		"rapid_skill_damage_bonus_percent": int(round(_get_rapid_skill_damage_bonus() * 100.0)),
		"reflow_skill_damage_bonus_percent": int(round(_get_reflow_skill_damage_bonus() * 100.0)),
		"blood_damage_bonus_percent": int(round(_get_blood_pact_damage_bonus() * 100.0)),
		"blood_critical_bonus": _get_blood_pact_crit_bonus(),
		"crimson_leech_damage_bonus_percent": int(round(_get_crimson_leech_damage_bonus() * 100.0)),
		"crimson_leech_active": _is_crimson_leech_active(),
		"total_life_steal_percent": _get_total_life_steal_percent(),
		"life_steal_cap_per_second": _get_life_steal_cap_per_second(),
		"movement_damage_bonus_percent": int(round(_get_movement_focus_damage_bonus() * 100.0)),
		"stationary_focus_tier": _get_stationary_focus_tier(),
		"movement_focus_tier": _get_movement_focus_tier(),
		"stationary_critical_bonus": _get_stationary_crit_bonus(),
		"movement_critical_bonus": _get_movement_focus_crit_bonus(),
		"giant_echo_close_damage_bonus_percent": int(round(_get_giant_echo_close_damage_bonus() * 100.0)),
		"class_name": str(class_data.get("name", "")),
		"class_gain_summary": str(class_data.get("gain_summary", "")),
		"critical_damage_multiplier": _get_critical_damage_multiplier(),
		"attack_interval": fire_interval,
		"move_speed": int(round(move_speed)),
		"critical_chance": _get_total_crit_bonus(),
		"shield": graze_shield,
		"upgrade_damage_bonus": upgrade_damage_bonus,
		"upgrade_projectile_damage_percent_bonus": int(round((_get_projectile_damage_upgrade_multiplier() - 1.0) * 100.0)),
		"upgrade_attack_speed_stacks": upgrade_attack_speed_stacks,
		"upgrade_projectile_count_bonus": upgrade_projectile_count_bonus,
		"upgrade_pierce_bonus": upgrade_pierce_bonus,
		"upgrade_explosion_radius_bonus": int(round(upgrade_explosion_radius_bonus)),
		"upgrade_player_size_bonus": int(round(upgrade_player_size_bonus * 100.0)),
		"mass_resonance_stacks": mass_resonance_stacks,
		"light_frame_stacks": light_frame_stacks,
		"light_resonance_stacks": light_resonance_stacks,
		"slow_resonance_stacks": slow_resonance_stacks,
		"haste_resonance_stacks": haste_resonance_stacks,
		"rapid_resonance_stacks": rapid_resonance_stacks,
		"blood_pact_stacks": blood_pact_stacks,
		"still_focus_stacks": still_focus_stacks,
		"motion_focus_stacks": motion_focus_stacks,
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
		"giant_echo_stacks": giant_echo_stacks,
		"light_edge_stacks": light_edge_stacks,
		"compressed_core_stacks": compressed_core_stacks,
		"reflow_shards_stacks": reflow_shards_stacks,
		"crimson_leech_stacks": crimson_leech_stacks,
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
