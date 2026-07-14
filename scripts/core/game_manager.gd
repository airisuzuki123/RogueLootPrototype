extends Node

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

const GRAZE_FEEDBACK_INTERVAL_MSEC: int = 220

signal gold_changed(total: int)
signal enemy_killed(total: int)
signal graze_changed(total: int)
signal health_changed(current: int, maximum: int)
signal experience_changed(current: int, required: int, level: int)
signal equipment_changed(equipped_items: Dictionary)
signal loot_message_changed(message: String)
signal equipment_choice_requested(candidate: Dictionary, current: Dictionary, salvage_value: int)
signal inventory_changed(items: Array)
signal inventory_open_changed(is_open: bool)
signal upgrade_choices_requested(choices: Array)
signal run_ended(kills: int, gold: int)
signal run_time_changed(elapsed_seconds: int, phase: Dictionary, remaining_seconds: int)
signal run_phase_changed(phase: Dictionary)
signal run_phase_objective_changed(phase: Dictionary, progress: int, target: int, completed: bool)
signal run_milestone_message_changed(message: String)
signal encounter_requested(encounter: Dictionary)
signal encounter_changed(encounter: Dictionary, active: bool)
signal encounter_completed(encounter: Dictionary)
signal stage_event_requested(event: Dictionary)
signal stage_event_changed(event: Dictionary, active: bool)
signal stage_event_completed(event: Dictionary)
signal shop_open_changed(is_open: bool, event: Dictionary, offers: Array)

const MAX_INVENTORY_SIZE: int = 36
const RUN_PHASES: Array[Dictionary] = [
	{
		"id": "opening",
		"name": "初始清场",
		"duration": 45.0,
		"spawn_interval": 1.25,
		"spawn_count": 1,
		"enemy_level_bonus": 0,
		"enemy_weight_bonus": {"grunt": -8, "runner": -8, "ranged": 18},
		"bullet_pattern": "aimed",
		"bullet_patterns": ["aimed", "aimed_burst"],
		"enemy_bullet_patterns": {
			"ranged": ["aimed", "aimed_burst"],
			"weaver": ["aimed_burst", "fan"],
			"turret": ["ring"]
		},
		"bullet_speed_multiplier": 0.88,
		"arena_patterns": [],
		"arena_pattern_interval": 0.0,
		"goal": "阅读直线与集束弹道，击杀敌人完成第一轮升级",
		"kill_target": 10,
		"reward_gold": 8,
		"reward_experience": 2,
		"reward_heal": 0
	},
	{
		"id": "chase",
		"name": "追击加压",
		"duration": 60.0,
		"spawn_interval": 1.05,
		"spawn_count": 1,
		"enemy_level_bonus": 0,
		"enemy_weight_bonus": {"grunt": -14, "tank": -8, "ranged": 28, "weaver": 18},
		"bullet_pattern": "fan",
		"bullet_patterns": ["fan", "aimed_burst"],
		"enemy_bullet_patterns": {
			"ranged": ["fan", "aimed_burst"],
			"weaver": ["fan", "sweep", "fan"],
			"turret": ["ring", "cross"]
		},
		"bullet_speed_multiplier": 0.95,
		"arena_patterns": ["side_curtain"],
		"arena_pattern_interval": 9.0,
		"goal": "穿过扇形弹幕，保持移动空间",
		"kill_target": 18,
		"reward_gold": 12,
		"reward_experience": 3,
		"reward_heal": 10
	},
	{
		"id": "mixed",
		"name": "混编压迫",
		"duration": 75.0,
		"spawn_interval": 1.00,
		"spawn_count": 1,
		"enemy_level_bonus": 1,
		"enemy_weight_bonus": {"grunt": -18, "runner": -8, "tank": -2, "ranged": 26, "weaver": 18, "turret": 12},
		"bullet_pattern": "ring",
		"bullet_patterns": ["ring", "cross", "sweep"],
		"enemy_bullet_patterns": {
			"ranged": ["ring", "cross", "ring"],
			"weaver": ["cross", "sweep", "cross"],
			"turret": ["ring", "double_ring", "cross"]
		},
		"bullet_speed_multiplier": 0.96,
		"arena_patterns": ["side_curtain", "cross_curtain", "center_pulse"],
		"arena_pattern_interval": 10.0,
		"goal": "观察环形和交叉弹幕缺口，处理远程压力",
		"kill_target": 26,
		"reward_gold": 16,
		"reward_experience": 4,
		"reward_heal": 15
	},
	{
		"id": "surge",
		"name": "密集来袭",
		"duration": 90.0,
		"spawn_interval": 0.88,
		"spawn_count": 1,
		"enemy_level_bonus": 1,
		"enemy_weight_bonus": {"grunt": -24, "runner": -6, "tank": -4, "ranged": 26, "weaver": 20, "turret": 18},
		"bullet_pattern": "spiral",
		"bullet_patterns": ["spiral", "fan", "double_ring", "sweep"],
		"enemy_bullet_patterns": {
			"ranged": ["spiral", "fan", "spiral"],
			"weaver": ["sweep", "fan", "sweep"],
			"turret": ["spiral", "double_ring", "pinwheel"]
		},
		"bullet_speed_multiplier": 1.02,
		"arena_patterns": ["cross_curtain", "alternating_curtain", "center_pulse"],
		"arena_pattern_interval": 9.0,
		"goal": "预判旋转和双层环弹幕轨迹，保持输出空间",
		"kill_target": 40,
		"reward_gold": 24,
		"reward_experience": 5,
		"reward_heal": 20
	},
	{
		"id": "endless_pressure",
		"name": "终局试炼",
		"duration": 75.0,
		"spawn_interval": 0.65,
		"spawn_count": 2,
		"enemy_level_bonus": 2,
		"enemy_weight_bonus": {"grunt": -30, "runner": -8, "tank": -2, "ranged": 32, "weaver": 24, "turret": 26},
		"bullet_pattern": "wall",
		"bullet_patterns": ["wall", "spiral", "flower", "pinwheel"],
		"enemy_bullet_patterns": {
			"ranged": ["wall", "spiral", "wall"],
			"weaver": ["wall", "sweep", "fan"],
			"turret": ["flower", "pinwheel", "double_ring"]
		},
		"bullet_speed_multiplier": 1.15,
		"arena_patterns": ["alternating_curtain", "corner_pinwheel", "center_pulse"],
		"arena_pattern_interval": 6.0,
		"goal": "穿越弹幕墙和花形弹幕，撑过最后一波压力",
		"kill_target": 60,
		"reward_gold": 35,
		"reward_experience": 6,
		"reward_heal": 25
	}
]

const ENCOUNTER_SCHEDULE: Array[Dictionary] = [
	{
		"id": "elite_weaver",
		"kind": "elite",
		"title": "精英：织弹追猎者",
		"trigger_time": 82.0,
		"enemy_type": "weaver",
		"objective": "击败精英，穿过连续扇形扫射",
		"spawn_message": "精英遭遇：织弹追猎者正在入场",
		"defeat_message": "精英已击败：织弹追猎者",
		"health_multiplier": 3.2,
		"touch_damage_multiplier": 1.2,
		"move_speed_multiplier": 1.08,
		"attack_interval_multiplier": 0.82,
		"projectile_speed_multiplier": 1.05,
		"visual_scale": 1.45,
		"color": Color(0.95, 0.48, 1.0, 1.0),
		"bullet_patterns": ["fan", "sweep", "cross"],
		"reward_gold": 18,
		"reward_experience": 6,
		"reward_heal": 18,
		"reward_equipment_count": 1,
		"reward_level_bonus": 1
	},
	{
		"id": "elite_turret",
		"kind": "elite",
		"title": "精英：环阵炮台",
		"trigger_time": 176.0,
		"enemy_type": "turret",
		"objective": "击败精英，观察环形与交叉弹幕缺口",
		"spawn_message": "精英遭遇：环阵炮台锁定战场",
		"defeat_message": "精英已击败：环阵炮台",
		"health_multiplier": 4.0,
		"touch_damage_multiplier": 1.25,
		"move_speed_multiplier": 0.88,
		"attack_interval_multiplier": 0.78,
		"projectile_speed_multiplier": 1.08,
		"visual_scale": 1.65,
		"color": Color(1.0, 0.36, 0.68, 1.0),
		"bullet_patterns": ["ring", "double_ring", "pinwheel"],
		"reward_gold": 26,
		"reward_experience": 8,
		"reward_heal": 22,
		"reward_equipment_count": 1,
		"reward_level_bonus": 2
	},
	{
		"id": "boss_prism_core",
		"kind": "boss",
		"title": "Boss：棱镜核心",
		"trigger_time": 272.0,
		"enemy_type": "turret",
		"objective": "击败 Boss，处理墙幕、花形弹幕和旋转缺口",
		"spawn_message": "Boss 遭遇：棱镜核心展开",
		"defeat_message": "Boss 已击败：棱镜核心",
		"health_multiplier": 8.5,
		"health_bonus": 120,
		"touch_damage_multiplier": 1.45,
		"move_speed_multiplier": 0.72,
		"attack_interval_multiplier": 0.62,
		"projectile_speed_multiplier": 1.12,
		"visual_scale": 2.35,
		"color": Color(1.0, 0.86, 0.26, 1.0),
		"bullet_patterns": ["wall", "flower", "pinwheel", "double_ring"],
		"reward_gold": 60,
		"reward_experience": 14,
		"reward_heal": 35,
		"reward_equipment_count": 2,
		"reward_level_bonus": 3,
		"complete_run_on_defeat": true
	}
]

const STAGE_EVENT_SCHEDULE: Array[Dictionary] = [
	{
		"id": "opening_chest",
		"kind": "chest",
		"title": "宝箱：清场补给",
		"trigger_time": 50.0,
		"objective": "触碰宝箱，获得一份早期构筑补给",
		"spawn_message": "宝箱事件：清场补给已出现",
		"complete_message": "宝箱已开启：清场补给",
		"reward_gold": 10,
		"reward_experience": 3,
		"reward_heal": 12,
		"reward_equipment_count": 1,
		"reward_level_bonus": 1
	},
	{
		"id": "midrun_chest",
		"kind": "chest",
		"title": "宝箱：弹幕间隙",
		"trigger_time": 142.0,
		"objective": "在弹幕压力中触碰宝箱，补强当前装备",
		"spawn_message": "宝箱事件：弹幕间隙已出现",
		"complete_message": "宝箱已开启：弹幕间隙",
		"reward_gold": 18,
		"reward_experience": 5,
		"reward_heal": 18,
		"reward_equipment_count": 1,
		"reward_level_bonus": 2
	},
	{
		"id": "midrun_shop",
		"kind": "shop",
		"title": "商店：临时补给站",
		"trigger_time": 198.0,
		"objective": "触碰商店，用金币购买一项补给",
		"spawn_message": "商店事件：临时补给站已出现",
		"complete_message": "商店已离开：临时补给站",
		"offers": [
			{
				"id": "shop_heal",
				"title": "应急治疗",
				"description": "恢复 45 生命",
				"cost": 18,
				"reward_heal": 45
			},
			{
				"id": "shop_training",
				"title": "战斗训练",
				"description": "获得 8 经验",
				"cost": 22,
				"reward_experience": 8
			},
			{
				"id": "shop_equipment",
				"title": "鉴定装备",
				"description": "获得 1 件高一级装备",
				"cost": 32,
				"reward_equipment_count": 1,
				"reward_level_bonus": 2
			}
		]
	},
	{
		"id": "preboss_chest",
		"kind": "chest",
		"title": "宝箱：终局整备",
		"trigger_time": 240.0,
		"objective": "终局前打开宝箱，获得 Boss 前补给",
		"spawn_message": "宝箱事件：终局整备已出现",
		"complete_message": "宝箱已开启：终局整备",
		"reward_gold": 28,
		"reward_experience": 7,
		"reward_heal": 28,
		"reward_equipment_count": 1,
		"reward_level_bonus": 3
	}
]

var gold: int = 0
var kills: int = 0
var grazes: int = 0
var level: int = 1
var experience: int = 0
var experience_to_next_level: int = 5
var player_health: int = 0
var player_max_health: int = 0
var player: Node = null
var is_run_over: bool = false
var is_run_completed: bool = false
var is_upgrade_pending: bool = false
var is_equipment_choice_pending: bool = false
var is_inventory_open: bool = false
var is_shop_open: bool = false
var pending_upgrade_choices: Array = []
var pending_equipment_choice: Dictionary = {}
var pending_equipment_salvage_value: int = 0
var active_shop_event: Dictionary = {}
var shop_offers: Array[Dictionary] = []
var inventory: Array[Dictionary] = []
var equipped_items := {
	"weapon": {},
	"helmet": {},
	"armor": {},
	"boots": {},
	"necklace": {},
	"ring": {}
}
var latest_loot_message: String = ""
var latest_milestone_message: String = ""
var triggered_encounter_ids := {}
var active_encounter: Dictionary = {}
var triggered_stage_event_ids := {}
var active_stage_event: Dictionary = {}
var run_elapsed_time: float = 0.0
var current_phase_index: int = 0
var current_phase_kill_start: int = 0
var current_phase_objective_completed: bool = false
var current_phase_warning_sent: bool = false
var latest_run_time_second: int = -1
var phase_bullet_pattern_counters := {}
var latest_graze_feedback_msec: int = -100000

const UPGRADE_POOL := [
	{
		"id": "damage",
		"title": "强化弹体",
		"description": "投射物伤害 +5"
	},
	{
		"id": "attack_speed",
		"title": "快速施放",
		"description": "射击间隔缩短 18%"
	},
	{
		"id": "move_speed",
		"title": "迅捷步伐",
		"description": "移动速度 +35"
	},
	{
		"id": "max_health",
		"title": "生命强化",
		"description": "最大生命 +25，并回复 25 生命"
	},
	{
		"id": "heal",
		"title": "喘息之机",
		"description": "回复 40 生命"
	},
	{
		"id": "strong_heal",
		"title": "紧急治疗",
		"description": "回复 70 生命"
	},
	{
		"id": "recovery_training",
		"title": "复苏训练",
		"description": "最大生命 +12，并回复 45 生命"
	},
	{
		"id": "multishot",
		"title": "分裂射击",
		"description": "每次攻击投射物 +1"
	}
]

func reset_run() -> void:
	gold = 0
	kills = 0
	grazes = 0
	level = 1
	experience = 0
	experience_to_next_level = 5
	player_health = 0
	player_max_health = 0
	player = null
	is_run_over = false
	is_run_completed = false
	is_upgrade_pending = false
	is_equipment_choice_pending = false
	is_inventory_open = false
	is_shop_open = false
	pending_upgrade_choices.clear()
	pending_equipment_choice.clear()
	pending_equipment_salvage_value = 0
	active_shop_event.clear()
	shop_offers.clear()
	inventory.clear()
	_reset_equipped_items()
	latest_loot_message = ""
	latest_milestone_message = ""
	triggered_encounter_ids.clear()
	active_encounter.clear()
	triggered_stage_event_ids.clear()
	active_stage_event.clear()
	run_elapsed_time = 0.0
	current_phase_index = 0
	current_phase_kill_start = 0
	current_phase_objective_completed = false
	current_phase_warning_sent = false
	latest_run_time_second = -1
	phase_bullet_pattern_counters.clear()
	latest_graze_feedback_msec = -100000
	gold_changed.emit(gold)
	enemy_killed.emit(kills)
	graze_changed.emit(grazes)
	experience_changed.emit(experience, experience_to_next_level, level)
	inventory_changed.emit(inventory)
	inventory_open_changed.emit(is_inventory_open)
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)
	equipment_changed.emit(equipped_items)
	loot_message_changed.emit(latest_loot_message)
	run_milestone_message_changed.emit(latest_milestone_message)
	encounter_changed.emit(active_encounter, false)
	stage_event_changed.emit(active_stage_event, false)
	run_phase_changed.emit(get_current_run_phase())
	_emit_run_time_changed(true)
	_emit_phase_objective_changed()

func update_run_time(delta: float) -> void:
	if is_run_over or is_gameplay_paused():
		return
	run_elapsed_time += delta
	_update_run_phase()
	_update_encounter_schedule()
	_update_stage_event_schedule()
	if _is_run_duration_complete():
		run_elapsed_time = _get_total_run_duration()
		_emit_run_time_changed(true)
		complete_run()
		return
	_update_phase_warning()
	_emit_run_time_changed(false)

func get_current_run_phase() -> Dictionary:
	if RUN_PHASES.is_empty():
		return {}
	return RUN_PHASES[clampi(current_phase_index, 0, RUN_PHASES.size() - 1)].duplicate(true)

func get_current_phase_spawn_interval() -> float:
	return float(get_current_run_phase().get("spawn_interval", 1.25))

func get_current_phase_spawn_count() -> int:
	return maxi(1, int(get_current_run_phase().get("spawn_count", 1)))

func get_current_phase_enemy_level_bonus() -> int:
	return maxi(0, int(get_current_run_phase().get("enemy_level_bonus", 0)))

func get_current_phase_enemy_weight_bonus(enemy_type: String) -> int:
	var weight_bonus: Dictionary = get_current_run_phase().get("enemy_weight_bonus", {})
	return int(weight_bonus.get(enemy_type, 0))

func get_current_phase_bullet_pattern() -> String:
	return get_current_phase_bullet_pattern_for_enemy("")

func get_current_phase_bullet_pattern_for_enemy(enemy_type: String) -> String:
	var phase := get_current_run_phase()
	var patterns: Array = []
	var enemy_patterns: Dictionary = phase.get("enemy_bullet_patterns", {})
	if enemy_patterns.has(enemy_type):
		patterns = enemy_patterns[enemy_type]
	if patterns.is_empty():
		patterns = phase.get("bullet_patterns", [])
	if patterns.is_empty():
		return str(phase.get("bullet_pattern", "aimed"))
	var phase_id := str(phase.get("id", "phase"))
	var counter_key := "%s:%s" % [phase_id, enemy_type if not enemy_type.is_empty() else "default"]
	var counter := int(phase_bullet_pattern_counters.get(counter_key, 0))
	phase_bullet_pattern_counters[counter_key] = counter + 1
	return str(patterns[counter % patterns.size()])

func get_current_phase_bullet_speed_multiplier() -> float:
	return maxf(0.2, float(get_current_run_phase().get("bullet_speed_multiplier", 1.0)))

func get_run_elapsed_seconds() -> int:
	return int(floor(run_elapsed_time))

func get_current_phase_remaining_seconds() -> int:
	var phase := get_current_run_phase()
	var duration := float(phase.get("duration", -1.0))
	if duration < 0.0:
		return -1
	var phase_elapsed := run_elapsed_time - _get_phase_start_time(current_phase_index)
	return maxi(0, int(ceil(duration - phase_elapsed)))

func get_current_phase_objective_progress() -> int:
	return maxi(0, kills - current_phase_kill_start)

func get_current_phase_objective_target() -> int:
	return maxi(0, int(get_current_run_phase().get("kill_target", 0)))

func is_current_phase_objective_completed() -> bool:
	return current_phase_objective_completed

func get_next_run_phase() -> Dictionary:
	var next_index := current_phase_index + 1
	if next_index < 0 or next_index >= RUN_PHASES.size():
		return {}
	return RUN_PHASES[next_index].duplicate(true)

func get_active_encounter() -> Dictionary:
	return active_encounter.duplicate(true)

func get_active_stage_event() -> Dictionary:
	return active_stage_event.duplicate(true)

func complete_encounter(encounter_id: String) -> void:
	if active_encounter.is_empty() or str(active_encounter.get("id", "")) != encounter_id:
		return
	var completed_encounter := active_encounter.duplicate(true)
	_apply_encounter_reward(completed_encounter)
	active_encounter.clear()
	encounter_completed.emit(completed_encounter)
	encounter_changed.emit(active_encounter, false)
	if bool(completed_encounter.get("complete_run_on_defeat", false)):
		complete_run()

func complete_stage_event(event_id: String) -> bool:
	if active_stage_event.is_empty() or str(active_stage_event.get("id", "")) != event_id:
		return false
	var completed_event := active_stage_event.duplicate(true)
	_apply_stage_event_reward(completed_event)
	active_stage_event.clear()
	stage_event_completed.emit(completed_event)
	stage_event_changed.emit(active_stage_event, false)
	return true

func open_shop_event(event_id: String) -> bool:
	if is_run_over or is_shop_open:
		return false
	if active_stage_event.is_empty() or str(active_stage_event.get("id", "")) != event_id:
		return false
	active_shop_event = active_stage_event.duplicate(true)
	shop_offers = _build_shop_offers(active_shop_event)
	is_shop_open = true
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)
	return true

func close_shop_event() -> void:
	if not is_shop_open:
		return
	var completed_event := active_shop_event.duplicate(true)
	is_shop_open = false
	active_shop_event.clear()
	shop_offers.clear()
	if not completed_event.is_empty() and str(active_stage_event.get("id", "")) == str(completed_event.get("id", "")):
		active_stage_event.clear()
		stage_event_completed.emit(completed_event)
		stage_event_changed.emit(active_stage_event, false)
		var message := str(completed_event.get("complete_message", "商店已关闭"))
		_set_loot_message(message)
		_set_milestone_message(message)
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)

func register_player(player_node: Node) -> void:
	player = player_node
	if player.has_method("sync_health_state"):
		player.sync_health_state()

func update_player_health(current: int, maximum: int) -> void:
	player_health = current
	player_max_health = maximum
	health_changed.emit(current, maximum)

func add_gold(amount: int, apply_bonus: bool = true) -> int:
	if is_run_over:
		return 0
	var final_amount := amount
	if apply_bonus and player != null and player.has_method("get_gold_bonus_percent"):
		var bonus_percent := int(player.get_gold_bonus_percent())
		if bonus_percent > 0:
			final_amount += int(round(float(amount) * float(bonus_percent) / 100.0))
	final_amount = maxi(0, final_amount)
	gold += final_amount
	gold_changed.emit(gold)
	_set_loot_message("金币 +%d" % final_amount)
	return final_amount

func spend_gold(amount: int) -> bool:
	if is_run_over:
		return false
	var cost := maxi(0, amount)
	if gold < cost:
		_set_loot_message("金币不足，需要 %d" % cost)
		return false
	gold -= cost
	gold_changed.emit(gold)
	return true

func buy_shop_offer(offer_index: int) -> bool:
	if not is_shop_open or offer_index < 0 or offer_index >= shop_offers.size():
		return false
	var offer: Dictionary = shop_offers[offer_index]
	if bool(offer.get("sold", false)):
		_set_loot_message("该商品已购买")
		return false
	var cost := maxi(0, int(offer.get("cost", 0)))
	if not spend_gold(cost):
		return false
	var reward_text := _apply_reward_bundle(offer)
	offer["sold"] = true
	shop_offers[offer_index] = offer
	var message := "购买：%s，花费 %d 金币，%s" % [str(offer.get("title", "商品")), cost, reward_text]
	_set_loot_message(message)
	_set_milestone_message(message)
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)
	return true

func pickup_equipment(equipment: Dictionary) -> bool:
	if is_run_over or equipment.is_empty():
		return false
	if inventory.size() >= MAX_INVENTORY_SIZE:
		_set_loot_message("背包已满，无法拾取：%s" % equipment["name"])
		return false
	inventory.append(equipment.duplicate(true))
	_sort_inventory()
	inventory_changed.emit(inventory)
	_set_loot_message("已放入背包：%s" % equipment["name"])
	return true

func toggle_inventory_open() -> void:
	if is_run_over or is_upgrade_pending or is_shop_open:
		return
	set_inventory_open(not is_inventory_open)

func set_inventory_open(open: bool) -> void:
	if is_run_over:
		open = false
	if is_upgrade_pending and open:
		return
	if is_shop_open and open:
		return
	if is_inventory_open == open:
		return
	is_inventory_open = open
	inventory_open_changed.emit(is_inventory_open)

func equip_inventory_equipment(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var new_equipment := inventory[index].duplicate(true)
	var slot_id := str(new_equipment.get("slot", "weapon"))
	inventory.remove_at(index)
	var old_equipment: Dictionary = equipped_items.get(slot_id, {}).duplicate(true)
	if not old_equipment.is_empty():
		inventory.append(old_equipment)
	equipped_items[slot_id] = new_equipment
	if player != null and player.has_method("equip_item"):
		player.equip_item(new_equipment, old_equipment)
	elif player != null and player.has_method("equip_weapon"):
		player.equip_weapon(new_equipment, old_equipment)
	_sort_inventory()
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipped_items)
	if old_equipment.is_empty():
		_set_loot_message("已装备：%s" % new_equipment["name"])
	else:
		_set_loot_message("已装备：%s，原%s放入背包" % [new_equipment["name"], EquipmentFactory.get_slot_label(slot_id)])

func unequip_item(slot_id: String) -> bool:
	if not equipped_items.has(slot_id):
		return false
	var equipment: Dictionary = equipped_items.get(slot_id, {}).duplicate(true)
	if equipment.is_empty():
		_set_loot_message("%s槽位为空" % EquipmentFactory.get_slot_label(slot_id))
		return false
	if inventory.size() >= MAX_INVENTORY_SIZE:
		_set_loot_message("背包已满，无法卸下：%s" % equipment["name"])
		return false
	equipped_items[slot_id] = {}
	inventory.append(equipment)
	if player != null and player.has_method("equip_item"):
		player.equip_item({}, equipment)
	elif player != null and player.has_method("equip_weapon"):
		player.equip_weapon({}, equipment)
	_sort_inventory()
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipped_items)
	_set_loot_message("已卸下：%s" % equipment["name"])
	return true

func salvage_inventory_equipment(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var equipment := inventory[index]
	var value := EquipmentFactory.get_salvage_value(equipment)
	var salvaged_name := str(equipment["name"])
	inventory.remove_at(index)
	var gained_gold := add_gold(value)
	inventory_changed.emit(inventory)
	_set_loot_message("已分解：%s，金币 +%d" % [salvaged_name, gained_gold])

func salvage_inventory_by_rarity(rarity_name: String) -> void:
	salvage_inventory_by_rarities([rarity_name])

func salvage_inventory_by_rarities(rarity_names: Array) -> void:
	if rarity_names.is_empty():
		_set_loot_message("请选择要分解的品质")
		return
	var kept_items: Array[Dictionary] = []
	var total_value := 0
	var salvaged_count := 0
	for equipment in inventory:
		if rarity_names.has(str(equipment.get("rarity", ""))):
			total_value += EquipmentFactory.get_salvage_value(equipment)
			salvaged_count += 1
		else:
			kept_items.append(equipment)
	if salvaged_count <= 0:
		_set_loot_message("没有可分解的指定品质装备")
		return
	inventory = kept_items
	_sort_inventory()
	var gained_gold := add_gold(total_value)
	inventory_changed.emit(inventory)
	_set_loot_message("已分解%d件装备，金币 +%d" % [salvaged_count, gained_gold])

func get_inventory_items() -> Array:
	return inventory.duplicate(true)

func get_inventory_count() -> int:
	return inventory.size()

func get_inventory_capacity() -> int:
	return MAX_INVENTORY_SIZE

func get_equipped_item(slot_id: String) -> Dictionary:
	return equipped_items.get(slot_id, {}).duplicate(true)

func _legacy_pickup_equipment_choice(equipment: Dictionary) -> void:
	is_equipment_choice_pending = true
	pending_equipment_choice = equipment.duplicate(true)
	pending_equipment_salvage_value = _calculate_salvage_value(pending_equipment_choice)
	var slot_id := str(pending_equipment_choice.get("slot", "weapon"))
	_set_loot_message("发现装备：%s" % pending_equipment_choice["name"])
	equipment_choice_requested.emit(pending_equipment_choice, get_equipped_item(slot_id), pending_equipment_salvage_value)

func equip_pending_equipment() -> void:
	if is_run_over or pending_equipment_choice.is_empty():
		return
	var new_equipment := pending_equipment_choice.duplicate(true)
	var slot_id := str(new_equipment.get("slot", "weapon"))
	var old_equipment: Dictionary = equipped_items.get(slot_id, {}).duplicate(true)
	equipped_items[slot_id] = new_equipment
	if player != null and player.has_method("equip_item"):
		player.equip_item(new_equipment, old_equipment)
	elif player != null and player.has_method("equip_weapon"):
		player.equip_weapon(new_equipment, old_equipment)
	equipment_changed.emit(equipped_items)
	_set_loot_message("已装备：%s" % new_equipment["name"])
	_clear_pending_equipment_choice()

func salvage_pending_equipment() -> void:
	if is_run_over or pending_equipment_choice.is_empty():
		return
	var salvaged_name := str(pending_equipment_choice["name"])
	var value := pending_equipment_salvage_value
	_clear_pending_equipment_choice()
	var gained_gold := add_gold(value)
	_set_loot_message("已分解：%s，金币 +%d" % [salvaged_name, gained_gold])

func register_kill() -> void:
	if is_run_over:
		return
	kills += 1
	enemy_killed.emit(kills)
	_update_current_phase_objective()

func register_graze() -> bool:
	if is_run_over:
		return false
	grazes += 1
	graze_changed.emit(grazes)
	var now_msec := Time.get_ticks_msec()
	if now_msec - latest_graze_feedback_msec < GRAZE_FEEDBACK_INTERVAL_MSEC:
		return false
	latest_graze_feedback_msec = now_msec
	return true

func add_experience(amount: int) -> void:
	if is_run_over:
		return
	experience += amount
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = int(ceil(float(experience_to_next_level) * 1.35 + 2.0))
		_request_upgrade_choices()
	experience_changed.emit(experience, experience_to_next_level, level)

func apply_upgrade(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= pending_upgrade_choices.size():
		return
	var upgrade: Dictionary = pending_upgrade_choices[choice_index]
	pending_upgrade_choices.clear()
	is_upgrade_pending = false
	if player != null and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade["id"])

func is_gameplay_paused() -> bool:
	return is_upgrade_pending or is_equipment_choice_pending or is_inventory_open or is_shop_open

func end_run(completed: bool = false) -> void:
	if is_run_over:
		return
	is_run_over = true
	is_run_completed = completed
	set_inventory_open(false)
	close_shop_event()
	if completed:
		_set_milestone_message("试炼完成")
	run_ended.emit(kills, gold)

func complete_run() -> void:
	end_run(true)

func _update_run_phase() -> void:
	var new_phase_index := _get_phase_index_for_time(run_elapsed_time)
	if new_phase_index == current_phase_index:
		return
	current_phase_index = new_phase_index
	current_phase_kill_start = kills
	current_phase_objective_completed = false
	current_phase_warning_sent = false
	phase_bullet_pattern_counters.clear()
	var phase := get_current_run_phase()
	run_phase_changed.emit(phase)
	var message := "进入阶段：%s - %s" % [str(phase.get("name", "未知阶段")), str(phase.get("goal", ""))]
	_set_loot_message(message)
	_set_milestone_message(message)
	_emit_run_time_changed(true)
	_emit_phase_objective_changed()

func _update_current_phase_objective() -> void:
	if current_phase_objective_completed:
		return
	var target := get_current_phase_objective_target()
	if target <= 0:
		return
	var progress := get_current_phase_objective_progress()
	if progress < target:
		_emit_phase_objective_changed()
		return
	current_phase_objective_completed = true
	_apply_phase_objective_reward()
	_emit_phase_objective_changed()

func _apply_phase_objective_reward() -> void:
	var phase := get_current_run_phase()
	var reward_parts: Array[String] = []
	var reward_gold := maxi(0, int(phase.get("reward_gold", 0)))
	var reward_experience := maxi(0, int(phase.get("reward_experience", 0)))
	var reward_heal := maxi(0, int(phase.get("reward_heal", 0)))
	if reward_gold > 0:
		var gained_gold := add_gold(reward_gold)
		reward_parts.append("金币 +%d" % gained_gold)
	if reward_experience > 0:
		add_experience(reward_experience)
		reward_parts.append("经验 +%d" % reward_experience)
	if reward_heal > 0 and player != null and player.has_method("heal_fixed_amount"):
		var healed_amount := int(player.heal_fixed_amount(reward_heal))
		if healed_amount > 0:
			reward_parts.append("生命 +%d" % healed_amount)
	var reward_text := "，".join(reward_parts) if not reward_parts.is_empty() else "无额外奖励"
	var message := "阶段目标完成：%s，%s" % [str(phase.get("name", "未知阶段")), reward_text]
	_set_loot_message(message)
	_set_milestone_message(message)

func _update_phase_warning() -> void:
	if current_phase_warning_sent:
		return
	var remaining_seconds := get_current_phase_remaining_seconds()
	if remaining_seconds < 0 or remaining_seconds > 10:
		return
	current_phase_warning_sent = true
	var next_phase := get_next_run_phase()
	var message := ""
	if next_phase.is_empty():
		message = "终局试炼即将完成，坚持最后 %d 秒" % remaining_seconds
	else:
		message = "%d 秒后进入：%s" % [remaining_seconds, str(next_phase.get("name", "下一阶段"))]
	_set_milestone_message(message)

func _update_encounter_schedule() -> void:
	if is_run_over or not active_encounter.is_empty():
		return
	for encounter in ENCOUNTER_SCHEDULE:
		var encounter_id := str(encounter.get("id", ""))
		if encounter_id.is_empty() or triggered_encounter_ids.has(encounter_id):
			continue
		if run_elapsed_time < float(encounter.get("trigger_time", 0.0)):
			continue
		_start_encounter(encounter)
		return

func _start_encounter(encounter: Dictionary) -> void:
	var encounter_id := str(encounter.get("id", ""))
	if encounter_id.is_empty():
		return
	triggered_encounter_ids[encounter_id] = true
	active_encounter = encounter.duplicate(true)
	var message := str(active_encounter.get("spawn_message", active_encounter.get("title", "遭遇开始")))
	_set_loot_message(message)
	_set_milestone_message(message)
	encounter_changed.emit(active_encounter, true)
	encounter_requested.emit(active_encounter)

func _update_stage_event_schedule() -> void:
	if is_run_over or not active_stage_event.is_empty():
		return
	for event in STAGE_EVENT_SCHEDULE:
		var event_id := str(event.get("id", ""))
		if event_id.is_empty() or triggered_stage_event_ids.has(event_id):
			continue
		if run_elapsed_time < float(event.get("trigger_time", 0.0)):
			continue
		_start_stage_event(event)
		return

func _start_stage_event(event: Dictionary) -> void:
	var event_id := str(event.get("id", ""))
	if event_id.is_empty():
		return
	triggered_stage_event_ids[event_id] = true
	active_stage_event = event.duplicate(true)
	var message := str(active_stage_event.get("spawn_message", active_stage_event.get("title", "事件开始")))
	_set_loot_message(message)
	_set_milestone_message(message)
	stage_event_changed.emit(active_stage_event, true)
	stage_event_requested.emit(active_stage_event)

func _build_shop_offers(event: Dictionary) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for offer in event.get("offers", []):
		var offer_data: Dictionary = offer
		offer_data = offer_data.duplicate(true)
		offer_data["sold"] = false
		offers.append(offer_data)
	return offers

func _apply_stage_event_reward(event: Dictionary) -> void:
	var reward_text := _apply_reward_bundle(event)
	var message := "%s，%s" % [str(event.get("complete_message", "事件完成")), reward_text]
	_set_loot_message(message)
	_set_milestone_message(message)

func _apply_encounter_reward(encounter: Dictionary) -> void:
	var reward_text := _apply_reward_bundle(encounter)
	var message := "%s，%s" % [str(encounter.get("defeat_message", "遭遇完成")), reward_text]
	_set_loot_message(message)
	_set_milestone_message(message)

func _apply_reward_bundle(source: Dictionary) -> String:
	var reward_parts: Array[String] = []
	var reward_gold := maxi(0, int(source.get("reward_gold", 0)))
	var reward_experience := maxi(0, int(source.get("reward_experience", 0)))
	var reward_heal := maxi(0, int(source.get("reward_heal", 0)))
	var reward_equipment_count := maxi(0, int(source.get("reward_equipment_count", 0)))
	if reward_gold > 0:
		var gained_gold := add_gold(reward_gold)
		reward_parts.append("金币 +%d" % gained_gold)
	if reward_experience > 0:
		add_experience(reward_experience)
		reward_parts.append("经验 +%d" % reward_experience)
	if reward_heal > 0 and player != null and player.has_method("heal_fixed_amount"):
		var healed_amount := int(player.heal_fixed_amount(reward_heal))
		if healed_amount > 0:
			reward_parts.append("生命 +%d" % healed_amount)
	if reward_equipment_count > 0:
		var reward_level := maxi(1, level + get_current_phase_enemy_level_bonus() + int(source.get("reward_level_bonus", 0)))
		var equipment_added := 0
		for index in range(reward_equipment_count):
			var equipment := EquipmentFactory.roll_equipment(reward_level)
			if pickup_equipment(equipment):
				equipment_added += 1
			else:
				var fallback_gold := add_gold(EquipmentFactory.get_salvage_value(equipment))
				reward_parts.append("背包已满，折算金币 +%d" % fallback_gold)
		if equipment_added > 0:
			reward_parts.append("装备 +%d" % equipment_added)
	return "，".join(reward_parts) if not reward_parts.is_empty() else "无额外奖励"

func _get_phase_index_for_time(elapsed_time: float) -> int:
	var cursor := 0.0
	for index in range(RUN_PHASES.size()):
		var duration := float(RUN_PHASES[index].get("duration", -1.0))
		if duration < 0.0:
			return index
		cursor += duration
		if elapsed_time < cursor:
			return index
	return maxi(0, RUN_PHASES.size() - 1)

func _is_run_duration_complete() -> bool:
	if not active_encounter.is_empty() and str(active_encounter.get("kind", "")) == "boss":
		return false
	var total_duration := _get_total_run_duration()
	return total_duration >= 0.0 and run_elapsed_time >= total_duration

func _get_total_run_duration() -> float:
	var total_duration := 0.0
	for phase in RUN_PHASES:
		var duration := float(phase.get("duration", -1.0))
		if duration < 0.0:
			return -1.0
		total_duration += duration
	return total_duration

func _get_phase_start_time(phase_index: int) -> float:
	var cursor := 0.0
	for index in range(mini(phase_index, RUN_PHASES.size())):
		var duration := float(RUN_PHASES[index].get("duration", -1.0))
		if duration < 0.0:
			return cursor
		cursor += duration
	return cursor

func _emit_run_time_changed(force: bool) -> void:
	var elapsed_seconds := get_run_elapsed_seconds()
	if not force and elapsed_seconds == latest_run_time_second:
		return
	latest_run_time_second = elapsed_seconds
	run_time_changed.emit(elapsed_seconds, get_current_run_phase(), get_current_phase_remaining_seconds())

func _emit_phase_objective_changed() -> void:
	run_phase_objective_changed.emit(
		get_current_run_phase(),
		get_current_phase_objective_progress(),
		get_current_phase_objective_target(),
		current_phase_objective_completed
	)

func _request_upgrade_choices() -> void:
	is_upgrade_pending = true
	var pool := UPGRADE_POOL.duplicate(true)
	var form_upgrade := _get_current_form_upgrade_choice()
	if not form_upgrade.is_empty():
		pool.append(form_upgrade)
	pool.shuffle()
	pending_upgrade_choices.clear()
	for index in range(min(3, pool.size())):
		pending_upgrade_choices.append(pool[index])
	upgrade_choices_requested.emit(pending_upgrade_choices)

func _get_current_form_upgrade_choice() -> Dictionary:
	var weapon: Dictionary = equipped_items.get("weapon", {})
	var form: Dictionary = weapon.get("form", {})
	match str(form.get("id", "")):
		"focused":
			return {
				"id": "form_focused",
				"title": "聚能专精",
				"description": "当前武器为聚能法杖：投射物伤害 +8"
			}
		"scatter":
			return {
				"id": "form_scatter",
				"title": "散射专精",
				"description": "当前武器为散射法杖：每次攻击投射物 +1"
			}
		"piercing":
			return {
				"id": "form_piercing",
				"title": "穿透专精",
				"description": "当前武器为穿透法杖：投射物穿透 +1"
			}
		"burst":
			return {
				"id": "form_burst",
				"title": "爆裂专精",
				"description": "当前武器为爆裂法杖：爆裂范围 +28"
			}
	return {}

func _set_loot_message(message: String) -> void:
	latest_loot_message = message
	loot_message_changed.emit(latest_loot_message)

func _set_milestone_message(message: String) -> void:
	latest_milestone_message = message
	run_milestone_message_changed.emit(latest_milestone_message)

func _clear_pending_equipment_choice() -> void:
	pending_equipment_choice.clear()
	pending_equipment_salvage_value = 0
	is_equipment_choice_pending = false

func _calculate_salvage_value(equipment: Dictionary) -> int:
	return EquipmentFactory.get_salvage_value(equipment)

func _reset_equipped_items() -> void:
	equipped_items = _create_empty_equipped_items()

func _create_empty_equipped_items() -> Dictionary:
	var empty_items := {}
	for slot in EquipmentFactory.EQUIPMENT_SLOTS:
		empty_items[str(slot["id"])] = {}
	return empty_items

func _sort_inventory() -> void:
	inventory.sort_custom(_is_inventory_item_before)

func _is_inventory_item_before(left: Dictionary, right: Dictionary) -> bool:
	return EquipmentFactory.should_sort_before(left, right)
