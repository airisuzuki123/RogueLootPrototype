extends Node

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

const GRAZE_REWARD_REQUIRED: int = 6
const GRAZE_REWARD_HEAL: int = 4
const GRAZE_REWARD_SHIELD: int = 12
const GRAZE_REWARD_SHIELD_DURATION: float = 2.5
const GRAZE_REWARD_COOLDOWN: float = 3.5
const SPECIAL_NODE_MIN_INTERVAL: float = 22.0
const BOSS_PREP_LOCKOUT_SECONDS: float = 12.0
const STAGE_COUNT: int = 10
const SHOP_REFRESH_BASE_COST: int = 8

signal gold_changed(total: int)
signal enemy_killed(total: int)
signal graze_changed(total: int)
signal health_changed(current: int, maximum: int)
signal build_summary_changed(summary: Dictionary)
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
signal event_choice_open_changed(is_open: bool, event: Dictionary, choices: Array)
signal combat_cleanup_requested()

const MAX_INVENTORY_SIZE: int = 36
const RUN_PHASES: Array[Dictionary] = [
	{
		"id": "stage_01",
		"name": "第 1 关：开场清场",
		"duration": 30.0,
		"spawn_interval": 1.05,
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
		"goal": "在 30 秒内熟悉直线弹道，尽量多拿金币",
		"kill_target": 8,
		"reward_gold": 8,
		"reward_experience": 2,
		"reward_heal": 0
	},
	{
		"id": "stage_02",
		"name": "第 2 关：扇形穿行",
		"duration": 30.0,
		"spawn_interval": 0.98,
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
		"arena_pattern_interval": 10.0,
		"goal": "穿过扇形弹幕，保留横向移动空间",
		"kill_target": 12,
		"reward_gold": 12,
		"reward_experience": 3,
		"reward_heal": 10
	},
	{
		"id": "stage_03",
		"name": "第 3 关：环形缺口",
		"duration": 30.0,
		"spawn_interval": 0.92,
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
		"arena_pattern_interval": 9.0,
		"goal": "观察环形和交叉弹幕缺口，建立第一套构筑",
		"kill_target": 14,
		"reward_gold": 16,
		"reward_experience": 4,
		"reward_heal": 15
	},
	{
		"id": "stage_04",
		"name": "第 4 关：精英织弹",
		"duration": 30.0,
		"spawn_interval": 1.10,
		"spawn_count": 1,
		"enemy_level_bonus": 1,
		"enemy_weight_bonus": {"grunt": -30, "runner": -8, "tank": -4, "ranged": 20, "weaver": 24, "turret": 8},
		"bullet_pattern": "sweep",
		"bullet_patterns": ["fan", "sweep", "cross"],
		"enemy_bullet_patterns": {
			"ranged": ["fan", "aimed_burst"],
			"weaver": ["sweep", "fan", "cross"],
			"turret": ["ring", "cross"]
		},
		"bullet_speed_multiplier": 1.00,
		"arena_patterns": ["cross_curtain", "center_pulse"],
		"arena_pattern_interval": 9.0,
		"goal": "特殊关卡：击败或压低精英，30 秒后清场进商店",
		"kill_target": 10,
		"reward_gold": 18,
		"reward_experience": 5,
		"reward_heal": 16
	},
	{
		"id": "stage_05",
		"name": "第 5 关：旋转压力",
		"duration": 30.0,
		"spawn_interval": 0.84,
		"spawn_count": 1,
		"enemy_level_bonus": 2,
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
		"arena_pattern_interval": 8.0,
		"goal": "预判旋转弹幕轨迹，用商店强化后的技能清场",
		"kill_target": 16,
		"reward_gold": 20,
		"reward_experience": 5,
		"reward_heal": 16
	},
	{
		"id": "stage_06",
		"name": "第 6 关：墙幕切线",
		"duration": 30.0,
		"spawn_interval": 0.78,
		"spawn_count": 1,
		"enemy_level_bonus": 2,
		"enemy_weight_bonus": {"grunt": -26, "runner": -6, "tank": -4, "ranged": 28, "weaver": 22, "turret": 18},
		"bullet_pattern": "wall",
		"bullet_patterns": ["wall", "cross", "ring"],
		"enemy_bullet_patterns": {
			"ranged": ["wall", "cross"],
			"weaver": ["wall", "sweep", "fan"],
			"turret": ["ring", "double_ring", "wall"]
		},
		"bullet_speed_multiplier": 1.06,
		"arena_patterns": ["alternating_curtain", "cross_curtain"],
		"arena_pattern_interval": 8.0,
		"goal": "阅读墙幕缺口，检验穿透、爆裂或多重投射组合",
		"kill_target": 18,
		"reward_gold": 22,
		"reward_experience": 5,
		"reward_heal": 18
	},
	{
		"id": "stage_07",
		"name": "第 7 关：折幕炮台",
		"duration": 30.0,
		"spawn_interval": 1.02,
		"spawn_count": 1,
		"enemy_level_bonus": 3,
		"enemy_weight_bonus": {"grunt": -32, "runner": -8, "tank": -6, "ranged": 22, "weaver": 16, "turret": 26},
		"bullet_pattern": "ring",
		"bullet_patterns": ["ring", "double_ring", "pinwheel"],
		"enemy_bullet_patterns": {
			"ranged": ["ring", "cross"],
			"weaver": ["cross", "sweep"],
			"turret": ["ring", "double_ring", "pinwheel"]
		},
		"bullet_speed_multiplier": 1.08,
		"arena_patterns": ["center_pulse", "corner_pinwheel"],
		"arena_pattern_interval": 8.0,
		"goal": "特殊关卡：处理炮台精英与环形缺口",
		"kill_target": 12,
		"reward_gold": 26,
		"reward_experience": 6,
		"reward_heal": 18
	},
	{
		"id": "stage_08",
		"name": "第 8 关：棱镜核心",
		"duration": 30.0,
		"spawn_interval": 1.20,
		"spawn_count": 1,
		"enemy_level_bonus": 3,
		"enemy_weight_bonus": {"grunt": -34, "runner": -8, "tank": -6, "ranged": 20, "weaver": 18, "turret": 24},
		"bullet_pattern": "flower",
		"bullet_patterns": ["wall", "flower", "pinwheel", "double_ring"],
		"enemy_bullet_patterns": {
			"ranged": ["wall", "spiral"],
			"weaver": ["wall", "sweep", "fan"],
			"turret": ["flower", "pinwheel", "double_ring"]
		},
		"bullet_speed_multiplier": 1.12,
		"arena_patterns": ["alternating_curtain", "corner_pinwheel", "center_pulse"],
		"arena_pattern_interval": 7.0,
		"goal": "特殊 Boss 关：在短窗口内爆发输出并躲避花形弹幕",
		"kill_target": 10,
		"reward_gold": 30,
		"reward_experience": 7,
		"reward_heal": 20
	},
	{
		"id": "stage_09",
		"name": "第 9 关：组合压迫",
		"duration": 30.0,
		"spawn_interval": 0.70,
		"spawn_count": 2,
		"enemy_level_bonus": 4,
		"enemy_weight_bonus": {"grunt": -30, "runner": -8, "tank": -2, "ranged": 32, "weaver": 24, "turret": 26},
		"bullet_pattern": "wall",
		"bullet_patterns": ["wall", "spiral", "flower", "pinwheel"],
		"enemy_bullet_patterns": {
			"ranged": ["wall", "spiral", "wall"],
			"weaver": ["wall", "sweep", "fan"],
			"turret": ["flower", "pinwheel", "double_ring"]
		},
		"bullet_speed_multiplier": 1.16,
		"arena_patterns": ["alternating_curtain", "corner_pinwheel", "center_pulse"],
		"arena_pattern_interval": 6.5,
		"goal": "用成型组合处理高密度弹幕与刷怪",
		"kill_target": 22,
		"reward_gold": 32,
		"reward_experience": 7,
		"reward_heal": 20
	},
	{
		"id": "stage_10",
		"name": "第 10 关：终局收束",
		"duration": 30.0,
		"spawn_interval": 0.62,
		"spawn_count": 2,
		"enemy_level_bonus": 5,
		"enemy_weight_bonus": {"grunt": -30, "runner": -8, "tank": -2, "ranged": 32, "weaver": 24, "turret": 26},
		"bullet_pattern": "wall",
		"bullet_patterns": ["wall", "spiral", "flower", "pinwheel"],
		"enemy_bullet_patterns": {
			"ranged": ["wall", "spiral", "wall"],
			"weaver": ["wall", "sweep", "fan"],
			"turret": ["flower", "pinwheel", "double_ring"]
		},
		"bullet_speed_multiplier": 1.20,
		"arena_patterns": ["alternating_curtain", "corner_pinwheel", "center_pulse"],
		"arena_pattern_interval": 6.0,
		"goal": "撑过最后 30 秒，完成 10 关试炼",
		"kill_target": 26,
		"reward_gold": 40,
		"reward_experience": 8,
		"reward_heal": 25
	}
]

const ENCOUNTER_SCHEDULE: Array[Dictionary] = [
	{
		"id": "elite_weaver",
		"kind": "elite",
		"title": "精英：织弹追猎者",
		"stage_index": 4,
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
		"reward_level_bonus": 1,
		"variants": [
			{
				"id": "elite_arc_weaver",
				"title": "精英：弧光织手",
				"objective": "击败精英，处理交叉弹幕和扫射追压",
				"spawn_message": "精英遭遇：弧光织手切入战场",
				"defeat_message": "精英已击败：弧光织手",
				"health_multiplier": 3.45,
				"attack_interval_multiplier": 0.78,
				"projectile_speed_multiplier": 1.08,
				"color": Color(0.50, 0.72, 1.0, 1.0),
				"bullet_patterns": ["cross", "sweep", "aimed_burst"],
				"reward_gold": 16,
				"reward_experience": 7,
				"reward_heal": 12,
				"reward_graze_shield": 14,
				"reward_graze_shield_duration": 3.0,
				"reward_equipment_count": 1,
				"reward_level_bonus": 1
			}
		]
	},
	{
		"id": "elite_turret",
		"kind": "elite",
		"title": "精英：环阵炮台",
		"stage_index": 7,
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
		"reward_level_bonus": 2,
		"variants": [
			{
				"id": "elite_wall_turret",
				"title": "精英：折幕炮台",
				"objective": "击败精英，穿过弹幕墙和环形缺口",
				"spawn_message": "精英遭遇：折幕炮台封锁路线",
				"defeat_message": "精英已击败：折幕炮台",
				"health_multiplier": 4.25,
				"attack_interval_multiplier": 0.82,
				"projectile_speed_multiplier": 1.05,
				"color": Color(0.42, 1.0, 0.72, 1.0),
				"bullet_patterns": ["wall", "ring", "pinwheel"],
				"reward_gold": 22,
				"reward_experience": 8,
				"reward_heal": 18,
				"reward_clear_projectiles": true,
				"reward_equipment_count": 1,
				"reward_level_bonus": 2
			}
		]
	},
	{
		"id": "boss_prism_core",
		"kind": "boss",
		"title": "Boss：棱镜核心",
		"stage_index": 8,
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
		"boss_phases": [
			{
				"threshold": 0.70,
				"title": "棱镜核心：裂光阶段",
				"message": "Boss 阶段变化：裂光阶段",
				"bullet_patterns": ["flower", "double_ring", "pinwheel"],
				"attack_interval_multiplier": 0.86,
				"projectile_speed_multiplier": 1.06,
				"color": Color(1.0, 0.62, 0.28, 1.0),
				"burst_scale": 1.7
			},
			{
				"threshold": 0.35,
				"title": "棱镜核心：终局折射",
				"message": "Boss 阶段变化：终局折射",
				"bullet_patterns": ["wall", "pinwheel", "flower", "double_ring"],
				"attack_interval_multiplier": 0.72,
				"projectile_speed_multiplier": 1.14,
				"color": Color(1.0, 0.32, 0.82, 1.0),
				"burst_scale": 2.1
			}
		],
		"reward_gold": 60,
		"reward_experience": 14,
		"reward_heal": 35,
		"reward_equipment_count": 2,
		"reward_level_bonus": 3,
		"complete_run_on_defeat": false
	}
]

const STAGE_EVENT_SCHEDULE: Array[Dictionary] = []

var gold: int = 0
var kills: int = 0
var grazes: int = 0
var level: int = 1
var experience: int = 0
var experience_to_next_level: int = 5
var player_health: int = 0
var player_max_health: int = 0
var player_build_summary: Dictionary = {}
var player_graze_shield: int = 0
var player_graze_shield_remaining: float = 0.0
var player: Node = null
var is_run_over: bool = false
var is_run_completed: bool = false
var is_upgrade_pending: bool = false
var is_equipment_choice_pending: bool = false
var is_inventory_open: bool = false
var is_shop_open: bool = false
var is_event_choice_open: bool = false
var pending_upgrade_choices: Array = []
var pending_equipment_choice: Dictionary = {}
var pending_equipment_salvage_value: int = 0
var active_shop_event: Dictionary = {}
var shop_offers: Array[Dictionary] = []
var active_choice_event: Dictionary = {}
var event_choices: Array[Dictionary] = []
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
var last_special_node_time: float = -9999.0
var run_elapsed_time: float = 0.0
var current_phase_index: int = 0
var current_phase_kill_start: int = 0
var current_phase_objective_completed: bool = false
var current_phase_warning_sent: bool = false
var is_between_stages: bool = false
var next_phase_after_shop: int = 0
var shop_refresh_count: int = 0
var latest_run_time_second: int = -1
var phase_bullet_pattern_counters := {}
var graze_charge: int = 0
var graze_reward_cooldown_remaining: float = 0.0

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
	},
	{
		"id": "piercing_rounds",
		"title": "穿透弹芯",
		"description": "投射物穿透 +1"
	},
	{
		"id": "blast_core",
		"title": "爆裂核心",
		"description": "投射物命中时获得爆裂范围"
	},
	{
		"id": "graze_barrier",
		"title": "折光护盾",
		"description": "立即获得 22 点短暂护盾"
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
	player_build_summary.clear()
	player_graze_shield = 0
	player_graze_shield_remaining = 0.0
	player = null
	is_run_over = false
	is_run_completed = false
	is_upgrade_pending = false
	is_equipment_choice_pending = false
	is_inventory_open = false
	is_shop_open = false
	is_event_choice_open = false
	pending_upgrade_choices.clear()
	pending_equipment_choice.clear()
	pending_equipment_salvage_value = 0
	active_shop_event.clear()
	shop_offers.clear()
	active_choice_event.clear()
	event_choices.clear()
	inventory.clear()
	_reset_equipped_items()
	latest_loot_message = ""
	latest_milestone_message = ""
	triggered_encounter_ids.clear()
	active_encounter.clear()
	triggered_stage_event_ids.clear()
	active_stage_event.clear()
	last_special_node_time = -9999.0
	run_elapsed_time = 0.0
	current_phase_index = 0
	current_phase_kill_start = 0
	current_phase_objective_completed = false
	current_phase_warning_sent = false
	is_between_stages = false
	next_phase_after_shop = 0
	shop_refresh_count = 0
	latest_run_time_second = -1
	phase_bullet_pattern_counters.clear()
	graze_charge = 0
	graze_reward_cooldown_remaining = 0.0
	gold_changed.emit(gold)
	enemy_killed.emit(kills)
	graze_changed.emit(grazes)
	experience_changed.emit(experience, experience_to_next_level, level)
	inventory_changed.emit(inventory)
	inventory_open_changed.emit(is_inventory_open)
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)
	event_choice_open_changed.emit(is_event_choice_open, active_choice_event, event_choices)
	equipment_changed.emit(equipped_items)
	build_summary_changed.emit(player_build_summary)
	loot_message_changed.emit(latest_loot_message)
	run_milestone_message_changed.emit(latest_milestone_message)
	encounter_changed.emit(active_encounter, false)
	stage_event_changed.emit(active_stage_event, false)
	run_phase_changed.emit(get_current_run_phase())
	_emit_run_time_changed(true)
	_emit_phase_objective_changed()

func update_run_time(delta: float) -> void:
	if is_run_over or is_gameplay_paused() or is_between_stages:
		return
	_update_graze_reward_cooldown(delta)
	run_elapsed_time += delta
	if _is_current_stage_time_complete():
		_finish_current_combat_stage()
		return
	_update_encounter_schedule()
	_update_stage_event_schedule()
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
	var next_index := next_phase_after_shop if is_between_stages else current_phase_index + 1
	if next_index < 0 or next_index >= RUN_PHASES.size():
		return {}
	return RUN_PHASES[next_index].duplicate(true)

func get_active_encounter() -> Dictionary:
	return active_encounter.duplicate(true)

func get_active_stage_event() -> Dictionary:
	return active_stage_event.duplicate(true)

func show_milestone_message(message: String) -> void:
	if message.is_empty():
		return
	_set_milestone_message(message)

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
	if is_between_stages:
		var message := str(completed_event.get("complete_message", "商店已离开"))
		_set_loot_message(message)
		_set_milestone_message(message)
		shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)
		_advance_after_stage_shop()
		return
	if not completed_event.is_empty() and str(active_stage_event.get("id", "")) == str(completed_event.get("id", "")):
		active_stage_event.clear()
		stage_event_completed.emit(completed_event)
		stage_event_changed.emit(active_stage_event, false)
		var message := str(completed_event.get("complete_message", "商店已关闭"))
		_set_loot_message(message)
		_set_milestone_message(message)
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)

func refresh_shop_offers() -> bool:
	if not is_shop_open:
		return false
	var cost := get_shop_refresh_cost()
	if not spend_gold(cost):
		return false
	shop_refresh_count += 1
	if active_shop_event.has("completed_stage"):
		active_shop_event["offers"] = _roll_between_stage_shop_offers(int(active_shop_event.get("completed_stage", 1)))
	shop_offers = _build_shop_offers(active_shop_event)
	var message := "刷新商店：花费 %d 金币" % cost
	_set_loot_message(message)
	_set_milestone_message(message)
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)
	return true

func get_shop_refresh_cost() -> int:
	return SHOP_REFRESH_BASE_COST + shop_refresh_count * 4

func open_choice_event(event_id: String) -> bool:
	if is_run_over or is_event_choice_open:
		return false
	if active_stage_event.is_empty() or str(active_stage_event.get("id", "")) != event_id:
		return false
	active_choice_event = active_stage_event.duplicate(true)
	event_choices = _build_event_choices(active_choice_event)
	is_event_choice_open = true
	event_choice_open_changed.emit(is_event_choice_open, active_choice_event, event_choices)
	return true

func close_choice_event() -> void:
	if not is_event_choice_open:
		return
	var completed_event := active_choice_event.duplicate(true)
	is_event_choice_open = false
	active_choice_event.clear()
	event_choices.clear()
	_complete_open_stage_event(completed_event)
	event_choice_open_changed.emit(is_event_choice_open, active_choice_event, event_choices)

func choose_event_option(choice_index: int) -> bool:
	if not is_event_choice_open or choice_index < 0 or choice_index >= event_choices.size():
		return false
	var choice: Dictionary = event_choices[choice_index]
	var cost_gold := maxi(0, int(choice.get("cost_gold", 0)))
	if cost_gold > 0 and not spend_gold(cost_gold):
		return false
	var penalty_text := _apply_choice_penalty(choice)
	var reward_text := _apply_reward_bundle(choice)
	var completed_event := active_choice_event.duplicate(true)
	is_event_choice_open = false
	active_choice_event.clear()
	event_choices.clear()
	_complete_open_stage_event(completed_event)
	var parts: Array[String] = []
	if cost_gold > 0:
		parts.append("花费金币 %d" % cost_gold)
	if not penalty_text.is_empty():
		parts.append(penalty_text)
	parts.append(reward_text)
	var message := "选择：%s，%s" % [str(choice.get("title", "事件选项")), "，".join(parts)]
	_set_loot_message(message)
	_set_milestone_message(message)
	event_choice_open_changed.emit(is_event_choice_open, active_choice_event, event_choices)
	return true

func register_player(player_node: Node) -> void:
	player = player_node
	if player.has_method("sync_health_state"):
		player.sync_health_state()

func update_player_health(current: int, maximum: int) -> void:
	player_health = current
	player_max_health = maximum
	health_changed.emit(current, maximum)

func update_player_build_summary(summary: Dictionary) -> void:
	player_build_summary = summary.duplicate(true)
	build_summary_changed.emit(player_build_summary)

func update_player_graze_shield(amount: int, remaining: float, emit_change: bool = true) -> void:
	player_graze_shield = maxi(0, amount)
	player_graze_shield_remaining = maxf(0.0, remaining)
	if emit_change:
		graze_changed.emit(grazes)

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
	if is_event_choice_open and open:
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
	graze_charge = mini(GRAZE_REWARD_REQUIRED, graze_charge + 1)
	graze_changed.emit(grazes)
	if graze_charge < GRAZE_REWARD_REQUIRED or graze_reward_cooldown_remaining > 0.0:
		return false
	return _trigger_graze_reward()

func _update_graze_reward_cooldown(delta: float) -> void:
	if graze_reward_cooldown_remaining <= 0.0:
		return
	graze_reward_cooldown_remaining = maxf(0.0, graze_reward_cooldown_remaining - delta)
	if graze_reward_cooldown_remaining <= 0.0:
		graze_changed.emit(grazes)

func _trigger_graze_reward() -> bool:
	graze_charge = 0
	graze_reward_cooldown_remaining = GRAZE_REWARD_COOLDOWN
	var healed_amount := 0
	if player != null and player.has_method("heal_fixed_amount"):
		healed_amount = int(player.heal_fixed_amount(GRAZE_REWARD_HEAL))
	if player != null and player.has_method("apply_graze_shield"):
		player.apply_graze_shield(GRAZE_REWARD_SHIELD, GRAZE_REWARD_SHIELD_DURATION)
	var reward_parts: Array[String] = []
	if healed_amount > 0:
		reward_parts.append("生命 +%d" % healed_amount)
	reward_parts.append("护盾 +%d" % GRAZE_REWARD_SHIELD)
	_set_loot_message("擦弹专注：%s" % "，".join(reward_parts))
	graze_changed.emit(grazes)
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
	return is_upgrade_pending or is_equipment_choice_pending or is_inventory_open or is_shop_open or is_event_choice_open

func end_run(completed: bool = false) -> void:
	if is_run_over:
		return
	is_run_over = true
	is_run_completed = completed
	is_between_stages = false
	set_inventory_open(false)
	close_shop_event()
	close_choice_event()
	if completed:
		_set_milestone_message("试炼完成")
	run_ended.emit(kills, gold)

func complete_run() -> void:
	end_run(true)

func _is_current_stage_time_complete() -> bool:
	var duration := float(get_current_run_phase().get("duration", -1.0))
	if duration < 0.0:
		return false
	var stage_elapsed := run_elapsed_time - _get_phase_start_time(current_phase_index)
	return stage_elapsed >= duration

func _finish_current_combat_stage() -> void:
	var phase := get_current_run_phase()
	run_elapsed_time = _get_phase_start_time(current_phase_index) + float(phase.get("duration", 0.0))
	_emit_run_time_changed(true)
	if not current_phase_objective_completed:
		current_phase_objective_completed = true
		_apply_phase_objective_reward()
		_emit_phase_objective_changed()
	if not active_encounter.is_empty():
		var cleared_encounter := active_encounter.duplicate(true)
		active_encounter.clear()
		encounter_changed.emit(active_encounter, false)
		_set_loot_message("%s 已随关卡清场结束" % str(cleared_encounter.get("title", "遭遇")))
	if not active_stage_event.is_empty():
		active_stage_event.clear()
		stage_event_changed.emit(active_stage_event, false)
	combat_cleanup_requested.emit()
	var completed_stage := current_phase_index + 1
	if completed_stage >= STAGE_COUNT or current_phase_index >= RUN_PHASES.size() - 1:
		_set_milestone_message("第 10 关完成，试炼结束")
		complete_run()
		return
	is_between_stages = true
	next_phase_after_shop = current_phase_index + 1
	_open_between_stage_shop(completed_stage)

func _advance_after_stage_shop() -> void:
	if not is_between_stages:
		return
	is_between_stages = false
	shop_refresh_count = 0
	current_phase_index = clampi(next_phase_after_shop, 0, RUN_PHASES.size() - 1)
	current_phase_kill_start = kills
	current_phase_objective_completed = false
	current_phase_warning_sent = false
	phase_bullet_pattern_counters.clear()
	var phase := get_current_run_phase()
	run_phase_changed.emit(phase)
	var message := "进入关卡：%s - %s" % [str(phase.get("name", "未知阶段")), str(phase.get("goal", ""))]
	_set_loot_message(message)
	_set_milestone_message(message)
	_emit_run_time_changed(true)
	_emit_phase_objective_changed()

func _open_between_stage_shop(completed_stage: int) -> void:
	shop_refresh_count = 0
	active_shop_event = _build_between_stage_shop_event(completed_stage)
	shop_offers = _build_shop_offers(active_shop_event)
	is_shop_open = true
	var message := "第 %d 关结束，清场后进入商店" % completed_stage
	_set_loot_message(message)
	_set_milestone_message(message)
	shop_open_changed.emit(is_shop_open, active_shop_event, shop_offers)

func _build_between_stage_shop_event(completed_stage: int) -> Dictionary:
	var next_stage := completed_stage + 1
	return {
		"id": "between_stage_shop_%02d" % completed_stage,
		"kind": "shop",
		"title": "关间商店：第 %d 关后" % completed_stage,
		"objective": "购买技能或装备，刷新需消耗金币；离开后进入第 %d 关" % next_stage,
		"complete_message": "离开商店，进入第 %d 关" % next_stage,
		"completed_stage": completed_stage,
		"offers": _roll_between_stage_shop_offers(completed_stage)
	}

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
		message = "第 10 关即将完成，坚持最后 %d 秒" % remaining_seconds
	else:
		message = "%d 秒后清场并进入商店" % remaining_seconds
	_set_milestone_message(message)

func _update_encounter_schedule() -> void:
	if is_run_over or not active_encounter.is_empty():
		return
	if not _can_start_special_node():
		return
	for encounter in ENCOUNTER_SCHEDULE:
		var encounter_id := str(encounter.get("id", ""))
		if encounter_id.is_empty() or triggered_encounter_ids.has(encounter_id):
			continue
		if int(encounter.get("stage_index", -1)) != current_phase_index + 1:
			continue
		_start_encounter(encounter)
		return

func _start_encounter(encounter: Dictionary) -> void:
	var encounter_id := str(encounter.get("id", ""))
	if encounter_id.is_empty():
		return
	triggered_encounter_ids[encounter_id] = true
	last_special_node_time = run_elapsed_time
	active_encounter = _resolve_scheduled_entry(encounter)
	var message := str(active_encounter.get("spawn_message", active_encounter.get("title", "遭遇开始")))
	_set_loot_message(message)
	_set_milestone_message(message)
	encounter_changed.emit(active_encounter, true)
	encounter_requested.emit(active_encounter)

func _update_stage_event_schedule() -> void:
	if is_run_over or not active_stage_event.is_empty():
		return
	if not _can_start_special_node():
		return
	for event in STAGE_EVENT_SCHEDULE:
		var event_id := str(event.get("id", ""))
		if event_id.is_empty() or triggered_stage_event_ids.has(event_id):
			continue
		if run_elapsed_time < float(event.get("trigger_time", 0.0)):
			continue
		if _is_stage_event_blocked_by_boss(event):
			triggered_stage_event_ids[event_id] = true
			continue
		_start_stage_event(event)
		return

func _start_stage_event(event: Dictionary) -> void:
	var event_id := str(event.get("id", ""))
	if event_id.is_empty():
		return
	triggered_stage_event_ids[event_id] = true
	last_special_node_time = run_elapsed_time
	active_stage_event = _resolve_scheduled_entry(event)
	var message := str(active_stage_event.get("spawn_message", active_stage_event.get("title", "事件开始")))
	_set_loot_message(message)
	_set_milestone_message(message)
	stage_event_changed.emit(active_stage_event, true)
	stage_event_requested.emit(active_stage_event)

func _resolve_scheduled_entry(entry: Dictionary) -> Dictionary:
	var resolved := entry.duplicate(true)
	var variants: Array = entry.get("variants", [])
	if not variants.is_empty():
		var roll := randi_range(0, variants.size())
		if roll > 0:
			var variant: Dictionary = variants[roll - 1]
			for key in variant.keys():
				resolved[key] = variant[key]
	resolved.erase("variants")
	return resolved

func _can_start_special_node() -> bool:
	if is_gameplay_paused():
		return false
	if not active_encounter.is_empty() or not active_stage_event.is_empty():
		return false
	return run_elapsed_time - last_special_node_time >= SPECIAL_NODE_MIN_INTERVAL

func _is_stage_event_blocked_by_boss(event: Dictionary) -> bool:
	if str(event.get("kind", "")) == "chest" and str(event.get("id", "")) == "preboss_chest":
		return false
	var boss_time := _get_next_untriggered_boss_time()
	return boss_time >= 0.0 and boss_time - run_elapsed_time <= BOSS_PREP_LOCKOUT_SECONDS

func _get_next_untriggered_boss_time() -> float:
	for encounter in ENCOUNTER_SCHEDULE:
		if str(encounter.get("kind", "")) != "boss":
			continue
		var encounter_id := str(encounter.get("id", ""))
		if triggered_encounter_ids.has(encounter_id):
			continue
		var stage_index := int(encounter.get("stage_index", -1))
		if stage_index < 0:
			return -1.0
		return _get_phase_start_time(stage_index - 1)
	return -1.0

func _roll_between_stage_shop_offers(completed_stage: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = [
		{
			"id": "shop_heal",
			"title": "应急治疗",
			"description": "恢复 45 生命",
			"cost": 12 + completed_stage * 2,
			"reward_heal": 45
		},
		{
			"id": "shop_shield",
			"title": "折光护盾",
			"description": "获得 24 点短暂护盾",
			"cost": 14 + completed_stage * 2,
			"reward_graze_shield": 24,
			"reward_graze_shield_duration": 4.0
		},
		{
			"id": "shop_equipment",
			"title": "鉴定装备",
			"description": "获得 1 件当前关卡等级装备",
			"cost": 18 + completed_stage * 3,
			"reward_equipment_count": 1,
			"reward_level_bonus": 1
		},
		{
			"id": "shop_damage_skill",
			"title": "技能：强击弹体",
			"description": "投射物伤害 +5，适合暴击和穿透",
			"cost": 16 + completed_stage * 2,
			"reward_upgrade_id": "damage",
			"reward_upgrade_title": "强击弹体"
		},
		{
			"id": "shop_attack_speed_skill",
			"title": "技能：急速施放",
			"description": "射击间隔缩短，提升所有投射组合频率",
			"cost": 18 + completed_stage * 2,
			"reward_upgrade_id": "attack_speed",
			"reward_upgrade_title": "急速施放"
		},
		{
			"id": "shop_multishot_skill",
			"title": "技能：分裂射击",
			"description": "每次攻击投射物 +1，适合爆裂和暴击",
			"cost": 22 + completed_stage * 3,
			"reward_upgrade_id": "multishot",
			"reward_upgrade_title": "分裂射击"
		},
		{
			"id": "shop_pierce_skill",
			"title": "技能：穿透弹芯",
			"description": "投射物穿透 +1，适合多投射和直线清场",
			"cost": 20 + completed_stage * 3,
			"reward_upgrade_id": "piercing_rounds",
			"reward_upgrade_title": "穿透弹芯"
		},
		{
			"id": "shop_blast_skill",
			"title": "技能：爆裂核心",
			"description": "命中时产生范围爆裂，适合聚怪清场",
			"cost": 24 + completed_stage * 3,
			"reward_upgrade_id": "blast_core",
			"reward_upgrade_title": "爆裂核心"
		}
	]
	if completed_stage >= 4:
		pool.append({
			"id": "shop_clear",
			"title": "清场符标",
			"description": "清除敌弹并恢复少量生命",
			"cost": 20 + completed_stage * 2,
			"reward_heal": 12,
			"reward_clear_projectiles": true
		})
	pool.shuffle()
	var offers: Array[Dictionary] = []
	for index in range(min(4, pool.size())):
		offers.append(pool[index])
	return offers

func _build_shop_offers(event: Dictionary) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for offer in event.get("offers", []):
		var offer_data: Dictionary = offer
		offer_data = offer_data.duplicate(true)
		offer_data["sold"] = false
		offers.append(offer_data)
	return offers

func _build_event_choices(event: Dictionary) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for choice in event.get("choices", []):
		var choice_data: Dictionary = choice
		choices.append(choice_data.duplicate(true))
	return choices

func _complete_open_stage_event(completed_event: Dictionary) -> void:
	if completed_event.is_empty():
		return
	if str(active_stage_event.get("id", "")) != str(completed_event.get("id", "")):
		return
	active_stage_event.clear()
	stage_event_completed.emit(completed_event)
	stage_event_changed.emit(active_stage_event, false)

func _apply_stage_event_reward(event: Dictionary) -> void:
	var reward_text := _apply_reward_bundle(event)
	var message := "%s，%s" % [str(event.get("complete_message", "事件完成")), reward_text]
	_set_loot_message(message)
	_set_milestone_message(message)

func _apply_choice_penalty(choice: Dictionary) -> String:
	var parts: Array[String] = []
	var penalty_damage := maxi(0, int(choice.get("penalty_damage", 0)))
	if penalty_damage > 0 and player != null and player.has_method("take_event_damage"):
		var applied_damage := int(player.take_event_damage(penalty_damage))
		if applied_damage > 0:
			parts.append("生命 -%d" % applied_damage)
	return "，".join(parts)

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
	var reward_graze_shield := maxi(0, int(source.get("reward_graze_shield", 0)))
	var reward_upgrade_id := str(source.get("reward_upgrade_id", ""))
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
	if reward_graze_shield > 0 and player != null and player.has_method("apply_graze_shield"):
		var shield_duration := maxf(0.1, float(source.get("reward_graze_shield_duration", GRAZE_REWARD_SHIELD_DURATION)))
		player.apply_graze_shield(reward_graze_shield, shield_duration)
		reward_parts.append("护盾 +%d" % reward_graze_shield)
	if bool(source.get("reward_clear_projectiles", false)):
		var cleared_projectiles := _clear_enemy_projectiles()
		reward_parts.append("清除敌弹 %d" % cleared_projectiles)
	if not reward_upgrade_id.is_empty() and player != null and player.has_method("apply_upgrade"):
		player.apply_upgrade(reward_upgrade_id)
		reward_parts.append("技能：%s" % str(source.get("reward_upgrade_title", _get_upgrade_title(reward_upgrade_id))))
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

func _get_upgrade_title(upgrade_id: String) -> String:
	for upgrade in UPGRADE_POOL:
		if str(upgrade.get("id", "")) == upgrade_id:
			return str(upgrade.get("title", "强化"))
	var form_upgrade := _get_current_form_upgrade_choice()
	if str(form_upgrade.get("id", "")) == upgrade_id:
		return str(form_upgrade.get("title", "强化"))
	return "强化"

func _clear_enemy_projectiles() -> int:
	var cleared_count := 0
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		if projectile == null or not is_instance_valid(projectile):
			continue
		projectile.queue_free()
		cleared_count += 1
	return cleared_count

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
