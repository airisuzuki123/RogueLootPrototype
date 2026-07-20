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
		"summary": "更大的体型和更慢的移动，换取弹幕覆盖和体积转伤害。",
		"effects": ["玩家体积 +15%", "当前移速 -10%", "体积共鸣伤害最终值 x1.20", "获得投射物 +100%、穿透 +100%、爆裂范围 +50%", "获得移速 -50%"],
		"gain_summary": "投射物/穿透 x2，爆裂范围 x1.5，移速收益 x0.5",
		"clear_summary": "多投射、穿透和爆裂范围",
		"initial_stats": {"player_size_bonus": 0.15, "move_speed_multiplier": 0.90},
		"multipliers": {"mass_resonance_damage": 1.20},
		"gain_multipliers": {"projectile_count": 2.0, "pierce": 2.0, "explosion_radius": 1.5, "move_speed": 0.5, "player_size_bonus": 1.35},
		"upgrade_bias": {"multishot": 1.80, "piercing_rounds": 1.55, "mass_resonance": 1.55, "slow_resonance": 1.45, "blast_core": 1.35, "shatter_blast": 1.25, "giant_echo": 1.20},
		"route_bias": {"bulk": 3, "pierce": 2, "blast": 2, "close": 1},
		"tag_bias": ["large_body", "slow_move"]
	},
	"steady_marksman": {
		"name": "沉稳射手",
		"summary": "开局带少量暴击，更适合原地蓄专注后的稳定输出。",
		"effects": ["暴击率 +5%", "静立聚焦暴击率最终值 x1.25", "移动时专注衰减速度 -20%", "获得暴击率 +100%、穿透 +100%", "获得移速 -25%"],
		"gain_summary": "暴击率/穿透 x2，移速收益 x0.75",
		"clear_summary": "穿透弹芯、贯穿增幅和光束",
		"initial_stats": {"critical_chance": 5},
		"multipliers": {"stationary_crit": 1.25},
		"focus_decay": {"stationary_move_decay_multiplier": 0.80},
		"gain_multipliers": {"critical_chance": 2.0, "pierce": 2.0, "move_speed": 0.75},
		"upgrade_bias": {"still_focus": 1.80, "piercing_rounds": 1.45, "pierce_amp": 1.35, "anchor_discharge": 0.85, "channel_beam": 1.25, "damage": 1.15},
		"route_bias": {"bulk": 2, "pierce": 2, "chain": 1},
		"tag_bias": ["stationary"]
	},
	"close_blade_guard": {
		"name": "贴身刃卫",
		"summary": "用开局护盾撑住近身距离，强化刀环和脉冲场。",
		"effects": ["开局护盾 +20，持续 999 秒", "近身刀环和脉冲场伤害 x1.20", "近身技能半径 +15%", "获得护盾 +100%、最大生命 +50%", "获得投射物伤害 -25%"],
		"gain_summary": "护盾 x2，最大生命 x1.5，投射物伤害收益 x0.75",
		"clear_summary": "近身刀环、脉冲场和护身锋刃",
		"initial_stats": {"shield": 20, "shield_duration": 999.0},
		"multipliers": {"close_damage": 1.20, "close_radius": 1.15},
		"gain_multipliers": {"shield": 2.0, "max_health": 1.5, "projectile_damage_percent": 0.75, "damage": 0.75, "damage_flat": 0.75},
		"upgrade_bias": {"close_slash": 1.80, "pulse_field": 1.80, "guard_blade": 1.50, "giant_echo": 1.35, "clear_barrier": 1.25, "graze_barrier": 1.25},
		"route_bias": {"close": 2, "bulk": 1, "agile": 1},
		"tag_bias": ["shielded", "close_skill"]
	},
	"roaming_arc": {
		"name": "游走电弧",
		"summary": "更快、更小，适合连锁、回旋和追踪弹道持续游走。",
		"effects": ["当前移速 +15%", "玩家体积 -12%", "连锁、回旋和追踪伤害 x1.15", "获得移速 +100%、投射物 +100%、穿透 +100%", "获得最大生命 -50%"],
		"gain_summary": "移速/投射物/穿透 x2，最大生命 x0.5",
		"clear_summary": "连锁、回旋、追踪、多投射和穿透",
		"initial_stats": {"move_speed_multiplier": 1.15, "player_size_bonus": -0.12},
		"multipliers": {"chain_orbit_homing_damage": 1.15},
		"gain_multipliers": {"move_speed": 2.0, "projectile_count": 2.0, "pierce": 2.0, "max_health": 0.5, "player_size_reduction": 1.5},
		"upgrade_bias": {"chain_spark": 1.55, "orbit_blade": 1.80, "homing_shards": 1.55, "motion_focus": 1.40, "reflow_shards": 1.35, "light_frame": 1.25},
		"route_bias": {"agile": 3, "chain": 3, "pierce": 1},
		"tag_bias": ["fast_move", "small_body", "chain_skill"]
	},
	"heavy_bomber": {
		"name": "重弹爆破",
		"summary": "牺牲一点射击频率，提前推向爆裂范围和高单发。",
		"effects": ["爆裂范围 +20", "重压弹芯和过载爆发伤害 x1.15", "射击间隔 +8%", "获得爆裂范围 +100%、穿透 +100%、投射物伤害 +35%", "获得移速 -50%"],
		"gain_summary": "爆裂范围/穿透 x2，投射物伤害收益 x1.35，移速收益 x0.5",
		"clear_summary": "爆裂范围、裂片爆破和穿透",
		"initial_stats": {"explosion_radius": 20.0, "fire_interval_multiplier": 1.08},
		"multipliers": {"heavy_overload_damage": 1.15},
		"gain_multipliers": {"explosion_radius": 2.0, "pierce": 2.0, "move_speed": 0.5, "projectile_damage_percent": 1.35},
		"upgrade_bias": {"blast_core": 1.65, "shatter_blast": 1.80, "heavy_shot": 1.60, "overload_burst": 1.40, "compressed_core": 1.25, "piercing_rounds": 1.25},
		"route_bias": {"blast": 3, "bulk": 2, "pierce": 2},
		"tag_bias": ["blast", "heavy_hit"]
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
