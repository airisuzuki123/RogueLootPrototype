extends RefCounted

const CLASS_ORDER := [
	"bulwark_gunner",
	"steady_marksman",
	"close_blade_guard",
	"roaming_arc",
	"heavy_bomber"
]

const CLASS_DEFINITIONS := {
	"bulwark_gunner": {
		"name": "巨躯炮台",
		"summary": "更大的体型和更慢的移动，换取体积转伤害的开局方向。",
		"effects": ["玩家体积 +15%", "当前移速 -10%", "体积共鸣伤害最终值 x1.20"],
		"initial_stats": {"player_size_bonus": 0.15, "move_speed_multiplier": 0.90},
		"multipliers": {"mass_resonance_damage": 1.20},
		"route_bias": {"bulk": 2, "close": 1, "blast": 1},
		"tag_bias": ["large_body", "slow_move"]
	},
	"steady_marksman": {
		"name": "沉稳射手",
		"summary": "开局带少量暴击，更适合原地蓄专注后的稳定输出。",
		"effects": ["暴击率 +5%", "静立聚焦暴击率最终值 x1.25", "移动时专注衰减速度 -20%"],
		"initial_stats": {"critical_chance": 5},
		"multipliers": {"stationary_crit": 1.25},
		"focus_decay": {"stationary_move_decay_multiplier": 0.80},
		"route_bias": {"bulk": 1, "pierce": 1, "chain": 1},
		"tag_bias": ["stationary", "slow_attack"]
	},
	"close_blade_guard": {
		"name": "贴身刃卫",
		"summary": "用开局护盾撑住近身距离，强化刀环和脉冲场。",
		"effects": ["开局护盾 +20，持续 999 秒", "近身刀环和脉冲场伤害 x1.20", "近身技能半径 +8%"],
		"initial_stats": {"shield": 20, "shield_duration": 999.0},
		"multipliers": {"close_damage": 1.20, "close_radius": 1.08},
		"route_bias": {"close": 2, "bulk": 1, "agile": 1},
		"tag_bias": ["shielded", "close_skill"]
	},
	"roaming_arc": {
		"name": "游走电弧",
		"summary": "更快、更小，适合连锁、回旋和追踪弹道持续游走。",
		"effects": ["当前移速 +15%", "玩家体积 -12%", "连锁、回旋和追踪伤害 x1.15"],
		"initial_stats": {"move_speed_multiplier": 1.15, "player_size_bonus": -0.12},
		"multipliers": {"chain_orbit_homing_damage": 1.15},
		"route_bias": {"agile": 2, "chain": 2, "pierce": 1},
		"tag_bias": ["fast_move", "small_body", "chain_skill"]
	},
	"heavy_bomber": {
		"name": "重弹爆破",
		"summary": "牺牲一点射击频率，提前推向爆裂范围和高单发。",
		"effects": ["爆裂范围 +20", "重压弹芯和过载爆发伤害 x1.15", "射击间隔 +8%"],
		"initial_stats": {"explosion_radius": 20.0, "fire_interval_multiplier": 1.08},
		"multipliers": {"heavy_overload_damage": 1.15},
		"route_bias": {"blast": 2, "bulk": 1, "pierce": 1},
		"tag_bias": ["blast", "heavy_hit", "slow_attack"]
	}
}

static func get_class_data(class_id: String) -> Dictionary:
	if not CLASS_DEFINITIONS.has(class_id):
		return {}
	var data: Dictionary = CLASS_DEFINITIONS[class_id].duplicate(true)
	data["id"] = class_id
	return data

static func get_class_list() -> Array[Dictionary]:
	var classes: Array[Dictionary] = []
	for class_id in CLASS_ORDER:
		var data := get_class_data(str(class_id))
		if not data.is_empty():
			classes.append(data)
	return classes
