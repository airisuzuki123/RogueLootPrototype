extends RefCounted

const SKILL_RARITY_ORDER := ["green", "blue", "purple", "gold"]
const SKILL_RARITY_DEFINITIONS := {
	"green": {"label": "绿色", "weight": 48, "shop_weight": 43},
	"blue": {"label": "蓝色", "weight": 34, "shop_weight": 35},
	"purple": {"label": "紫色", "weight": 18, "shop_weight": 20},
	"gold": {"label": "金色", "weight": 4, "shop_weight": 6}
}

const SKILL_REPEAT_WEIGHT_PER_STACK: float = 0.24
const SKILL_REPEAT_WEIGHT_CAP: float = 1.85
const SKILL_SYNERGY_WEIGHT_PER_SOURCE_STACK: float = 0.18
const SKILL_SYNERGY_WEIGHT_CAP: float = 1.70
const SKILL_TAG_SOURCE_WEIGHT_PER_MATCH: float = 0.18
const SKILL_TAG_SOURCE_WEIGHT_CAP: float = 1.75
const SKILL_TAG_ROUTE_WEIGHT_PER_STACK: float = 0.06
const SKILL_TAG_ROUTE_WEIGHT_CAP: float = 1.40
const SKILL_TAG_CONFLICT_WEIGHT: float = 0.70
const SKILL_ENGINE_FIRST_PICK_WEIGHT: float = 1.18
const SKILL_ENGINE_REPEAT_BASE_WEIGHT: int = 8

const BUILD_ROUTE_ORDER := ["bulk", "agile", "pierce", "blast", "chain", "close"]
const BUILD_ROUTE_DEFINITIONS := {
	"bulk": {
		"upgrades": ["multishot", "mass_resonance", "slow_resonance", "giant_echo", "still_focus", "heavy_shot", "compressed_core", "blast_core", "anchor_discharge"],
		"shop_offers": ["shop_multishot_skill", "shop_mass_resonance_skill", "shop_slow_resonance_skill", "shop_giant_echo_skill", "shop_still_focus_skill", "shop_heavy_skill", "shop_compressed_core_skill", "shop_blast_skill", "shop_anchor_discharge_skill"]
	},
	"agile": {
		"upgrades": ["light_frame", "light_resonance", "haste_resonance", "motion_focus", "light_edge", "attack_speed", "orbit_blade", "momentum_cache"],
		"shop_offers": ["shop_light_frame_skill", "shop_light_resonance_skill", "shop_haste_resonance_skill", "shop_motion_focus_skill", "shop_light_edge_skill", "shop_attack_speed_skill", "shop_orbit_skill", "shop_momentum_cache_skill"]
	},
	"pierce": {
		"upgrades": ["piercing_rounds", "pierce_amp", "light_edge", "damage", "attack_speed", "multishot"],
		"shop_offers": ["shop_pierce_skill", "shop_pierce_amp_skill", "shop_light_edge_skill", "shop_damage_skill", "shop_attack_speed_skill", "shop_multishot_skill"]
	},
	"blast": {
		"upgrades": ["blast_core", "shatter_blast", "overload_burst", "heavy_shot", "compressed_core", "damage"],
		"shop_offers": ["shop_blast_skill", "shop_shatter_blast_skill", "shop_overload_skill", "shop_heavy_skill", "shop_compressed_core_skill", "shop_damage_skill"]
	},
	"chain": {
		"upgrades": ["chain_spark", "homing_shards", "conduit_coil", "channel_beam", "reflow_shards", "attack_speed", "rapid_resonance"],
		"shop_offers": ["shop_chain_skill", "shop_homing_skill", "shop_conduit_coil_skill", "shop_channel_beam_skill", "shop_reflow_shards_skill", "shop_attack_speed_skill", "shop_rapid_resonance_skill"]
	},
	"close": {
		"upgrades": ["close_slash", "pulse_field", "guard_blade", "giant_echo", "blood_pact", "crimson_leech", "elite_reactor", "last_stand_matrix", "graze_barrier", "clear_barrier", "move_speed"],
		"shop_offers": ["shop_close_slash_skill", "shop_pulse_field_skill", "shop_guard_blade_skill", "shop_giant_echo_skill", "shop_blood_pact_skill", "shop_crimson_leech_skill", "shop_elite_reactor_skill", "shop_last_stand_matrix_skill"]
	}
}

const ROUTE_SIGNATURE_UPGRADES := {
	"bulk": ["multishot", "mass_resonance", "slow_resonance", "giant_echo", "still_focus", "heavy_shot", "compressed_core", "blast_core", "anchor_discharge"],
	"agile": ["light_frame", "light_resonance", "haste_resonance", "motion_focus", "light_edge", "momentum_cache"],
	"pierce": ["piercing_rounds", "pierce_amp"],
	"blast": ["blast_core", "shatter_blast", "overload_burst", "heavy_shot", "compressed_core"],
	"chain": ["chain_spark", "homing_shards", "conduit_coil", "channel_beam", "rapid_resonance", "reflow_shards"],
	"close": ["close_slash", "pulse_field", "guard_blade", "giant_echo", "blood_pact", "crimson_leech", "elite_reactor", "last_stand_matrix"]
}

const ROUTE_SYNERGY_DEFINITIONS := {
	"bulk": ["blast", "close", "pierce"],
	"agile": ["chain", "close", "pierce"],
	"pierce": ["blast", "bulk", "chain"],
	"blast": ["bulk", "pierce", "chain"],
	"chain": ["pierce", "blast"],
	"close": ["bulk", "agile", "chain"]
}

const UPGRADE_SYNERGY_SOURCES := {
	"mass_resonance": ["multishot", "blast_core", "heavy_shot", "move_speed"],
	"slow_resonance": ["multishot", "homing_shards", "channel_beam", "max_health", "recovery_training"],
	"light_resonance": ["light_frame"],
	"haste_resonance": ["light_frame", "move_speed"],
	"motion_focus": ["light_frame", "move_speed", "haste_resonance"],
	"rapid_resonance": ["attack_speed", "chain_spark", "orbit_blade", "homing_shards", "channel_beam"],
	"pierce_amp": ["piercing_rounds", "form_piercing"],
	"shatter_blast": ["blast_core", "form_burst", "heavy_shot", "overload_burst"],
	"conduit_coil": ["chain_spark", "homing_shards", "orbit_blade", "channel_beam"],
	"guard_blade": ["close_slash", "pulse_field"],
	"blood_pact": ["max_health", "recovery_training", "guard_blade"],
	"still_focus": ["heavy_shot", "channel_beam"],
	"giant_echo": ["multishot", "blast_core", "heavy_shot", "close_slash", "pulse_field", "guard_blade"],
	"light_edge": ["light_frame", "light_resonance", "haste_resonance", "motion_focus"],
	"compressed_core": ["damage", "heavy_shot", "blast_core", "overload_burst"],
	"reflow_shards": ["motion_focus", "rapid_resonance", "chain_spark", "orbit_blade", "homing_shards"],
	"crimson_leech": ["blood_pact", "max_health", "recovery_training"],
	"elite_reactor": ["guard_blade", "clear_barrier", "giant_echo"],
	"last_stand_matrix": ["blood_pact", "crimson_leech", "max_health", "recovery_training"],
	"momentum_cache": ["motion_focus", "haste_resonance", "reflow_shards"],
	"anchor_discharge": ["still_focus", "channel_beam", "heavy_shot"]
}

const UPGRADE_TAGS := {
	"damage": {"effect_tags": ["slow_attack"], "conflict_tags": ["fast_attack"], "route_tags": ["projectile"]},
	"attack_speed": {"effect_tags": ["fast_attack"], "conflict_tags": ["slow_attack"], "route_tags": ["utility"]},
	"move_speed": {"effect_tags": ["fast_move", "large_body"], "conflict_tags": ["small_body"], "route_tags": ["mobility"]},
	"max_health": {"effect_tags": ["slow_move", "high_health"], "conflict_tags": ["fast_move"]},
	"recovery_training": {"effect_tags": ["slow_move", "high_health"], "conflict_tags": ["fast_move"]},
	"multishot": {"effect_tags": ["large_body", "slow_move", "multi_projectile"], "conflict_tags": ["small_body", "fast_move"]},
	"mass_resonance": {"source_tags": ["large_body"]},
	"light_frame": {"effect_tags": ["small_body", "fast_move"], "conflict_tags": ["large_body", "slow_move"]},
	"light_resonance": {"source_tags": ["small_body"], "conflict_tags": ["large_body"]},
	"slow_resonance": {"source_tags": ["slow_move"], "conflict_tags": ["fast_move"]},
	"haste_resonance": {"source_tags": ["fast_move"], "conflict_tags": ["slow_move"]},
	"rapid_resonance": {"source_tags": ["fast_attack"], "conflict_tags": ["slow_attack"]},
	"blood_pact": {"effect_tags": ["low_life"], "source_tags": ["low_life", "high_health", "blood_risk"], "conflict_tags": ["shielded"]},
	"still_focus": {"effect_tags": ["stationary"], "source_tags": ["slow_attack"], "conflict_tags": ["moving"]},
	"motion_focus": {"effect_tags": ["moving"], "source_tags": ["fast_move"], "conflict_tags": ["stationary"]},
	"piercing_rounds": {"effect_tags": ["pierce"], "conflict_tags": ["heavy_hit"]},
	"blast_core": {"effect_tags": ["blast", "large_body", "slow_attack"], "conflict_tags": ["fast_attack", "small_body"]},
	"graze_barrier": {"effect_tags": ["shielded"], "route_tags": ["survival"]},
	"clear_barrier": {"effect_tags": ["shielded"], "route_tags": ["survival"]},
	"chain_spark": {"effect_tags": ["chain_skill"], "source_tags": ["fast_attack"], "conflict_tags": ["slow_attack"]},
	"orbit_blade": {"effect_tags": ["chain_skill"], "source_tags": ["fast_move", "fast_attack"]},
	"overload_burst": {"effect_tags": ["blast", "heavy_hit"], "source_tags": ["slow_attack", "blast"], "conflict_tags": ["fast_attack"]},
	"homing_shards": {"effect_tags": ["chain_skill", "slow_move"], "source_tags": ["fast_attack"], "conflict_tags": ["fast_move"]},
	"heavy_shot": {"effect_tags": ["heavy_hit", "large_body", "slow_attack"], "conflict_tags": ["fast_attack", "small_body"]},
	"close_slash": {"effect_tags": ["close_skill"], "source_tags": ["shielded", "large_body"]},
	"pulse_field": {"effect_tags": ["close_skill"], "source_tags": ["shielded", "large_body"]},
	"channel_beam": {"effect_tags": ["chain_skill", "stationary", "slow_move"], "source_tags": ["stationary"], "conflict_tags": ["fast_move"]},
	"shatter_blast": {"source_tags": ["blast"]},
	"pierce_amp": {"source_tags": ["pierce"]},
	"conduit_coil": {"source_tags": ["chain_skill", "stationary"]},
	"guard_blade": {"effect_tags": ["shielded"], "source_tags": ["close_skill", "large_body"]},
	"giant_echo": {"effect_tags": ["shielded"], "source_tags": ["shielded", "close_skill"], "conflict_tags": ["small_body"], "engine_tags": ["bulk_close"]},
	"light_edge": {"source_tags": ["small_body", "fast_move"], "conflict_tags": ["large_body", "slow_move"], "engine_tags": ["agile_crit"]},
	"compressed_core": {"effect_tags": ["heavy_hit", "slow_attack"], "source_tags": ["slow_attack", "blast"], "conflict_tags": ["fast_attack", "multi_projectile"], "engine_tags": ["heavy_blast"]},
	"reflow_shards": {"effect_tags": ["fast_attack"], "source_tags": ["moving", "chain_skill", "fast_attack"], "conflict_tags": ["stationary", "slow_attack"], "engine_tags": ["agile_chain"]},
	"crimson_leech": {"effect_tags": ["low_life"], "source_tags": ["low_life", "high_health", "blood_risk"], "conflict_tags": ["shielded"], "engine_tags": ["blood_risk"]},
	"elite_reactor": {"source_tags": ["shielded", "close_skill"], "route_tags": ["close"], "engine_tags": ["elite_trigger"]},
	"last_stand_matrix": {"source_tags": ["low_life", "blood_risk"], "route_tags": ["close"], "conflict_tags": ["shielded"], "engine_tags": ["low_life_trigger"]},
	"momentum_cache": {"source_tags": ["moving", "fast_move"], "route_tags": ["agile"], "conflict_tags": ["stationary"], "engine_tags": ["movement_trigger"]},
	"anchor_discharge": {"source_tags": ["stationary", "slow_attack"], "route_tags": ["bulk"], "conflict_tags": ["moving"], "engine_tags": ["stationary_trigger"]}
}

const UPGRADE_DEFINITIONS := {
	"damage": {
		"title": "强击弹体",
		"description": "投射物伤害 +25%，射击间隔 +10%",
		"preview": "投射物伤害 +25%，射击间隔 +10%",
		"rarity": "green"
	},
	"attack_speed": {
		"title": "急速施放",
		"description": "射击间隔 -25%，投射物伤害 -10%",
		"preview": "射击间隔 -25%，投射物伤害 -10%",
		"rarity": "green"
	},
	"move_speed": {
		"title": "迅捷步伐",
		"description": "移动速度 +70，玩家体积 +5%（最高 +240%）",
		"preview": "移动速度 +70，玩家体积 +5%（最高 +240%）",
		"rarity": "green"
	},
	"max_health": {
		"title": "生命强化",
		"description": "最大生命 +30，并回复 30 生命，当前移速 -5%（最低 80）",
		"preview": "最大生命 +30，并回复 30 生命，当前移速 -5%（最低 80）",
		"rarity": "green"
	},
	"heal": {
		"title": "喘息之机",
		"description": "回复 40 生命",
		"preview": "回复 40 生命",
		"rarity": "green"
	},
	"strong_heal": {
		"title": "紧急治疗",
		"description": "回复 70 生命",
		"preview": "回复 70 生命",
		"rarity": "green"
	},
	"recovery_training": {
		"title": "复苏训练",
		"description": "最大生命 +25，并回复 60 生命，当前移速 -5%（最低 80）",
		"preview": "最大生命 +25，并回复 60 生命，当前移速 -5%（最低 80）",
		"rarity": "green"
	},
	"multishot": {
		"title": "分裂射击",
		"description": "投射物 +1，玩家体积 +30%（最高 +240%），当前移速 -25%（最低 80）",
		"preview": "投射物 +1，玩家体积 +30%（最高 +240%），当前移速 -25%（最低 80）",
		"rarity": "purple"
	},
	"mass_resonance": {
		"title": "体积共鸣",
		"description": "玩家体积每 +10%，投射物伤害 +16%",
		"preview": "玩家体积每 +10%，投射物伤害 +16%",
		"rarity": "blue"
	},
	"light_frame": {
		"title": "轻装骨架",
		"description": "玩家体积 -12%（最低 -40%），移动速度 +70，投射物伤害 -10%",
		"preview": "玩家体积 -12%（最低 -40%），移动速度 +70，投射物伤害 -10%",
		"rarity": "green"
	},
	"light_resonance": {
		"title": "轻盈共鸣",
		"description": "玩家体积每低于 100% 10%，投射物伤害 +8%、暴击率 +10%",
		"preview": "玩家体积每低于 100% 10%，投射物伤害 +8%、暴击率 +10%",
		"rarity": "blue"
	},
	"slow_resonance": {
		"title": "迟缓共鸣",
		"description": "当前移速每低于初始值 10%，投射物伤害 +18%",
		"preview": "当前移速每低于初始值 10%，投射物伤害 +18%",
		"rarity": "blue"
	},
	"haste_resonance": {
		"title": "疾行共鸣",
		"description": "当前移速每高于初始值 10%，投射物伤害 +10%、暴击率 +8%",
		"preview": "当前移速每高于初始值 10%，投射物伤害 +10%、暴击率 +8%",
		"rarity": "blue"
	},
	"rapid_resonance": {
		"title": "速射共鸣",
		"description": "射击间隔每低于初始值 10%，连锁、回旋、追踪和过载伤害 +22%",
		"preview": "射击间隔每低于初始值 10%，连锁、回旋、追踪和过载伤害 +22%",
		"rarity": "purple"
	},
	"blood_pact": {
		"title": "血潮契约",
		"description": "当前生命 -22（最低 1）；生命每损失 10%，投射物伤害 +16%、暴击率 +10%",
		"preview": "当前生命 -22（最低 1）；生命每损失 10%，投射物伤害 +16%、暴击率 +10%",
		"rarity": "purple"
	},
	"still_focus": {
		"title": "静立聚焦",
		"description": "静止每 0.7 秒暴击率 +10%，最多 12 层专注",
		"preview": "静止每 0.7 秒暴击率 +10%，最多 12 层专注",
		"rarity": "blue"
	},
	"motion_focus": {
		"title": "游走聚焦",
		"description": "移动每 0.6 秒游走伤害 +8%、暴击率 +5%，最多 10 层游走",
		"preview": "移动每 0.6 秒游走伤害 +8%、暴击率 +5%，最多 10 层游走",
		"rarity": "blue"
	},
	"piercing_rounds": {
		"title": "穿透弹芯",
		"description": "投射物穿透 +1，投射物伤害 -10%",
		"preview": "穿透 +1，投射物伤害 -10%",
		"rarity": "green"
	},
	"blast_core": {
		"title": "爆裂核心",
		"description": "爆裂范围 +40，玩家体积 +20%（最高 +240%），射击间隔 +15%",
		"preview": "爆裂范围 +40、玩家体积 +20%（最高 +240%）、射击间隔 +15%",
		"rarity": "purple"
	},
	"graze_barrier": {
		"title": "折光护盾",
		"description": "护盾 +22，持续 4 秒",
		"preview": "护盾 +22，持续 4 秒",
		"rarity": "green"
	},
	"clear_barrier": {
		"title": "清弹屏障",
		"description": "立即清除敌弹，护盾 +16，持续 3.5 秒",
		"preview": "立即清除敌弹，护盾 +16，持续 3.5 秒",
		"rarity": "green"
	},
	"chain_spark": {
		"title": "连锁电弧",
		"description": "连锁弹 +1，单枚伤害 115%，投射物伤害 -12%",
		"preview": "连锁弹 +1，单枚伤害 115%，投射物伤害 -12%",
		"rarity": "purple"
	},
	"orbit_blade": {
		"title": "回旋刃",
		"description": "两侧回旋弹各 +1，单枚伤害 105%",
		"preview": "两侧回旋弹各 +1，单枚伤害 105%",
		"rarity": "purple"
	},
	"overload_burst": {
		"title": "过载爆发",
		"description": "每 4 次攻击释放 8 枚爆裂弹，单枚伤害 250%",
		"preview": "每 4 次攻击释放 8 枚爆裂弹，单枚伤害 250%",
		"rarity": "gold"
	},
	"homing_shards": {
		"title": "寻迹碎片",
		"description": "追踪碎片 +1，单枚伤害 115%，当前移速 -12%（最低 80）",
		"preview": "追踪碎片 +1，单枚伤害 115%，当前移速 -12%（最低 80）",
		"rarity": "purple"
	},
	"heavy_shot": {
		"title": "重压弹芯",
		"description": "投射物伤害 +20%；每 3 次攻击发射 1 枚 220% 重弹，击退 +45%，玩家体积 +15%（最高 +240%），射击间隔 +10%",
		"preview": "投射物伤害 +20%、玩家体积 +15%（最高 +240%）、射击间隔 +10%；每 3 次攻击发射 1 枚 220% 重弹，击退 +45%",
		"rarity": "purple"
	},
	"close_slash": {
		"title": "近身刀环",
		"description": "每 1.18 秒造成 120% 近身斩击",
		"preview": "每 1.18 秒造成 120% 近身斩击",
		"rarity": "purple"
	},
	"pulse_field": {
		"title": "脉冲场",
		"description": "每 2.25 秒造成 100% 脉冲",
		"preview": "每 2.25 秒造成 100% 脉冲",
		"rarity": "purple"
	},
	"channel_beam": {
		"title": "引导光束",
		"description": "每 0.32 秒对 330 范围内最近敌人造成 85% 伤害，当前移速 -10%（最低 80）",
		"preview": "每 0.32 秒对 330 范围内最近敌人造成 85% 伤害，当前移速 -10%（最低 80）",
		"rarity": "purple"
	},
	"shatter_blast": {
		"title": "裂片爆破",
		"description": "爆裂伤害 +55%，爆裂范围 +16",
		"preview": "爆裂伤害 +55%，爆裂范围 +16",
		"rarity": "blue"
	},
	"pierce_amp": {
		"title": "贯穿增幅",
		"description": "穿透 +1，投射物伤害 +55%",
		"preview": "穿透 +1，投射物伤害 +55%",
		"rarity": "blue"
	},
	"conduit_coil": {
		"title": "超导线圈",
		"description": "光束伤害 +150%，连锁弹和追踪碎片伤害 +75%，光束间隔 -0.03 秒",
		"preview": "光束伤害 +150%，连锁/追踪伤害 +75%，光束间隔 -0.03 秒",
		"rarity": "gold"
	},
	"guard_blade": {
		"title": "护身锋刃",
		"description": "近身刀环和脉冲场伤害 +55%，护盾 +20",
		"preview": "近身刀环和脉冲场伤害 +55%，护盾 +20",
		"rarity": "blue"
	},
	"giant_echo": {
		"title": "巨体回响",
		"description": "玩家体积每 +10%，近身刀环和脉冲场伤害 +20%；护盾 +18，持续 4 秒",
		"preview": "玩家体积每 +10%，近身伤害 +20%；护盾 +18，持续 4 秒",
		"rarity": "blue"
	},
	"light_edge": {
		"title": "轻锋协议",
		"description": "玩家体积每低于 100% 10%，暴击伤害 +25%",
		"preview": "玩家体积每低于 100% 10%，暴击伤害 +25%",
		"rarity": "blue"
	},
	"compressed_core": {
		"title": "压缩弹芯",
		"description": "投射物 -1（最低 1），投射物伤害 x2.50，射击间隔 +15%",
		"preview": "投射物 -1（最低 1），投射物伤害 x2.50，射击间隔 +15%",
		"rarity": "gold"
	},
	"reflow_shards": {
		"title": "碎片回流",
		"description": "射击间隔 -10%；游走层数使连锁、回旋和追踪伤害 +12%，最多 10 层",
		"preview": "射击间隔 -10%；游走层数使连锁、回旋和追踪伤害 +12%，最多 10 层",
		"rarity": "purple"
	},
	"crimson_leech": {
		"title": "血怒汲取",
		"description": "当前生命 -15（最低 1）；生命低于 35% 时投射物伤害 +60%、吸血 +8%",
		"preview": "当前生命 -15（最低 1）；生命低于 35% 时投射物伤害 +60%、吸血 +8%",
		"rarity": "purple"
	},
	"elite_reactor": {
		"title": "破阵反应",
		"description": "击败精英或 Boss 时清除敌弹，护盾 +18，持续 4 秒",
		"preview": "击败精英或 Boss 时清除敌弹，护盾 +18，持续 4 秒",
		"rarity": "blue"
	},
	"last_stand_matrix": {
		"title": "背水矩阵",
		"description": "每关首次生命低于 35% 时清除敌弹，护盾 +26，持续 4 秒",
		"preview": "每关首次生命低于 35% 时清除敌弹，护盾 +26，持续 4 秒",
		"rarity": "blue"
	},
	"momentum_cache": {
		"title": "疾行缓存",
		"description": "游走达到 8 层时护盾 +10，持续 2.5 秒；冷却 9 秒",
		"preview": "游走达到 8 层时护盾 +10，持续 2.5 秒；冷却 9 秒",
		"rarity": "blue"
	},
	"anchor_discharge": {
		"title": "锚定释放",
		"description": "静立达到 6 层时清除敌弹，护盾 +8，持续 2.5 秒；冷却 12 秒",
		"preview": "静立达到 6 层时清除敌弹，护盾 +8，持续 2.5 秒；冷却 12 秒",
		"rarity": "blue"
	},
	"form_focused": {
		"title": "聚能强化",
		"description": "当前武器为聚能法杖：投射物伤害 +8",
		"preview": "投射物伤害 +8",
		"rarity": "blue"
	},
	"form_scatter": {
		"title": "散射强化",
		"description": "当前武器为散射法杖：每次攻击投射物 +1",
		"preview": "每次攻击投射物 +1",
		"rarity": "blue"
	},
	"form_piercing": {
		"title": "穿透强化",
		"description": "当前武器为穿透法杖：投射物穿透 +1",
		"preview": "投射物穿透 +1",
		"rarity": "blue"
	},
	"form_burst": {
		"title": "爆裂强化",
		"description": "当前武器为爆裂法杖：爆裂范围 +14",
		"preview": "爆裂范围 +14",
		"rarity": "blue"
	}
}

const UPGRADE_ORDER := [
	"damage", "attack_speed", "move_speed", "max_health", "heal", "strong_heal", "recovery_training",
	"multishot", "mass_resonance", "light_frame", "light_resonance", "slow_resonance", "haste_resonance",
	"rapid_resonance", "blood_pact", "still_focus", "motion_focus", "piercing_rounds", "blast_core",
	"graze_barrier", "clear_barrier", "chain_spark", "orbit_blade", "overload_burst", "homing_shards",
	"heavy_shot", "close_slash", "pulse_field", "channel_beam", "shatter_blast", "pierce_amp",
	"conduit_coil", "guard_blade", "giant_echo", "light_edge", "compressed_core", "reflow_shards",
	"crimson_leech", "elite_reactor", "last_stand_matrix", "momentum_cache", "anchor_discharge"
]

const SHOP_SKILL_OFFERS := {
	"shop_damage_skill": {"title": "强击弹体", "reward_upgrade_id": "damage", "base_cost": 16, "stage_cost": 2},
	"shop_attack_speed_skill": {"title": "急速施放", "reward_upgrade_id": "attack_speed", "base_cost": 18, "stage_cost": 2},
	"shop_multishot_skill": {"title": "分裂射击", "reward_upgrade_id": "multishot", "base_cost": 22, "stage_cost": 3},
	"shop_mass_resonance_skill": {"title": "体积共鸣", "reward_upgrade_id": "mass_resonance", "base_cost": 22, "stage_cost": 3},
	"shop_light_frame_skill": {"title": "轻装骨架", "reward_upgrade_id": "light_frame", "base_cost": 20, "stage_cost": 3},
	"shop_light_resonance_skill": {"title": "轻盈共鸣", "reward_upgrade_id": "light_resonance", "base_cost": 22, "stage_cost": 3},
	"shop_slow_resonance_skill": {"title": "迟缓共鸣", "reward_upgrade_id": "slow_resonance", "base_cost": 22, "stage_cost": 3},
	"shop_haste_resonance_skill": {"title": "疾行共鸣", "reward_upgrade_id": "haste_resonance", "base_cost": 22, "stage_cost": 3},
	"shop_rapid_resonance_skill": {"title": "速射共鸣", "reward_upgrade_id": "rapid_resonance", "base_cost": 22, "stage_cost": 3},
	"shop_blood_pact_skill": {"title": "血潮契约", "reward_upgrade_id": "blood_pact", "base_cost": 18, "stage_cost": 3},
	"shop_still_focus_skill": {"title": "静立聚焦", "reward_upgrade_id": "still_focus", "base_cost": 20, "stage_cost": 3},
	"shop_motion_focus_skill": {"title": "游走聚焦", "reward_upgrade_id": "motion_focus", "base_cost": 20, "stage_cost": 3},
	"shop_pierce_skill": {"title": "穿透弹芯", "reward_upgrade_id": "piercing_rounds", "base_cost": 20, "stage_cost": 3},
	"shop_blast_skill": {"title": "爆裂核心", "reward_upgrade_id": "blast_core", "base_cost": 24, "stage_cost": 3},
	"shop_chain_skill": {"title": "连锁电弧", "reward_upgrade_id": "chain_spark", "base_cost": 24, "stage_cost": 3},
	"shop_orbit_skill": {"title": "回旋刃", "reward_upgrade_id": "orbit_blade", "base_cost": 22, "stage_cost": 3},
	"shop_overload_skill": {"title": "过载爆发", "reward_upgrade_id": "overload_burst", "base_cost": 28, "stage_cost": 3},
	"shop_homing_skill": {"title": "寻迹碎片", "reward_upgrade_id": "homing_shards", "base_cost": 24, "stage_cost": 3},
	"shop_heavy_skill": {"title": "重压弹芯", "reward_upgrade_id": "heavy_shot", "base_cost": 26, "stage_cost": 3},
	"shop_close_slash_skill": {"title": "近身刀环", "reward_upgrade_id": "close_slash", "base_cost": 24, "stage_cost": 3},
	"shop_pulse_field_skill": {"title": "脉冲场", "reward_upgrade_id": "pulse_field", "base_cost": 25, "stage_cost": 3},
	"shop_channel_beam_skill": {"title": "引导光束", "reward_upgrade_id": "channel_beam", "base_cost": 28, "stage_cost": 3},
	"shop_shatter_blast_skill": {"title": "裂片爆破", "reward_upgrade_id": "shatter_blast", "base_cost": 25, "stage_cost": 3},
	"shop_pierce_amp_skill": {"title": "贯穿增幅", "reward_upgrade_id": "pierce_amp", "base_cost": 24, "stage_cost": 3},
	"shop_conduit_coil_skill": {"title": "超导线圈", "reward_upgrade_id": "conduit_coil", "base_cost": 26, "stage_cost": 3},
	"shop_guard_blade_skill": {"title": "护身锋刃", "reward_upgrade_id": "guard_blade", "base_cost": 24, "stage_cost": 3},
	"shop_giant_echo_skill": {"title": "巨体回响", "reward_upgrade_id": "giant_echo", "base_cost": 25, "stage_cost": 3},
	"shop_light_edge_skill": {"title": "轻锋协议", "reward_upgrade_id": "light_edge", "base_cost": 24, "stage_cost": 3},
	"shop_compressed_core_skill": {"title": "压缩弹芯", "reward_upgrade_id": "compressed_core", "base_cost": 30, "stage_cost": 4},
	"shop_reflow_shards_skill": {"title": "碎片回流", "reward_upgrade_id": "reflow_shards", "base_cost": 25, "stage_cost": 3},
	"shop_crimson_leech_skill": {"title": "血怒汲取", "reward_upgrade_id": "crimson_leech", "base_cost": 24, "stage_cost": 3},
	"shop_elite_reactor_skill": {"title": "破阵反应", "reward_upgrade_id": "elite_reactor", "base_cost": 22, "stage_cost": 3},
	"shop_last_stand_matrix_skill": {"title": "背水矩阵", "reward_upgrade_id": "last_stand_matrix", "base_cost": 22, "stage_cost": 3},
	"shop_momentum_cache_skill": {"title": "疾行缓存", "reward_upgrade_id": "momentum_cache", "base_cost": 22, "stage_cost": 3},
	"shop_anchor_discharge_skill": {"title": "锚定释放", "reward_upgrade_id": "anchor_discharge", "base_cost": 22, "stage_cost": 3}
}

const UPGRADE_VALUES := {
	"damage": {"projectile_damage_percent": 0.25, "fire_interval_multiplier": 1.10},
	"attack_speed": {"fire_interval_multiplier": 0.75, "projectile_damage_penalty": 0.10},
	"move_speed": {"move_speed_bonus": 70.0, "player_size_bonus": 0.05},
	"max_health": {"max_health_bonus": 30, "heal": 30, "move_speed_multiplier": 0.95},
	"heal": {"heal": 40},
	"strong_heal": {"heal": 70},
	"recovery_training": {"max_health_bonus": 25, "heal": 60, "move_speed_multiplier": 0.95},
	"multishot": {"projectile_count_bonus": 1, "player_size_bonus": 0.30, "move_speed_multiplier": 0.75},
	"mass_resonance": {"damage_per_10_percent": 0.16},
	"light_frame": {"player_size_reduction": 0.12, "move_speed_bonus": 70.0, "projectile_damage_penalty": 0.10},
	"light_resonance": {"damage_per_10_percent": 0.08, "crit_per_10_percent": 10},
	"slow_resonance": {"damage_per_10_percent": 0.18},
	"haste_resonance": {"damage_per_10_percent": 0.10, "crit_per_10_percent": 8},
	"rapid_resonance": {"skill_damage_per_10_percent": 0.22},
	"blood_pact": {"health_cost": 22, "damage_per_10_percent": 0.16, "crit_per_10_percent": 10},
	"still_focus": {"interval": 0.70, "crit_per_tier": 10, "max_tier": 12},
	"motion_focus": {"interval": 0.60, "damage_per_tier": 0.08, "crit_per_tier": 5, "max_tier": 10},
	"piercing_rounds": {"pierce_bonus": 1, "projectile_damage_penalty": 0.10},
	"blast_core": {"explosion_radius": 40.0, "player_size_bonus": 0.20, "fire_interval_multiplier": 1.15},
	"graze_barrier": {"shield": 22, "shield_duration": 4.0},
	"clear_barrier": {"shield": 16, "shield_duration": 3.5},
	"chain_spark": {"projectile_damage_penalty": 0.12, "base_damage_multiplier": 1.15, "damage_per_extra_stack": 0.20, "lifetime_bonus": 0.08},
	"orbit_blade": {"base_damage_multiplier": 1.05, "damage_per_extra_stack": 0.18, "lifetime_bonus": 0.08},
	"overload_burst": {"base_projectiles": 6, "projectiles_per_stack": 2, "base_damage_multiplier": 2.50, "damage_per_extra_stack": 0.25},
	"homing_shards": {"move_speed_multiplier": 0.88, "base_damage_multiplier": 1.15, "damage_per_extra_stack": 0.20, "base_tracking": 4.8, "tracking_per_stack": 0.85},
	"heavy_shot": {"projectile_damage_percent": 0.20, "player_size_bonus": 0.15, "fire_interval_multiplier": 1.10, "damage_multiplier": 2.20, "damage_per_extra_stack": 0.25, "knockback_bonus": 0.45},
	"close_slash": {"base_radius": 72.0, "radius_per_stack": 22.0, "base_cooldown": 1.18, "cooldown_reduction": 0.12, "min_cooldown": 0.22, "base_damage_multiplier": 1.20, "damage_per_extra_stack": 0.25},
	"pulse_field": {"base_radius": 96.0, "radius_per_stack": 24.0, "base_cooldown": 2.25, "cooldown_reduction": 0.18, "min_cooldown": 0.55, "base_damage_multiplier": 1.00, "damage_per_extra_stack": 0.20},
	"channel_beam": {"base_range": 330.0, "range_per_stack": 28.0, "base_interval": 0.32, "interval_reduction": 0.035, "base_damage_multiplier": 0.85, "damage_per_extra_stack": 0.18, "move_speed_multiplier": 0.90},
	"shatter_blast": {"explosion_damage_per_stack": 0.55, "explosion_radius": 16.0},
	"pierce_amp": {"pierce_bonus": 1, "damage_per_stack": 0.55},
	"conduit_coil": {"beam_damage_per_stack": 1.50, "chain_damage_per_stack": 0.75, "beam_interval_reduction": 0.03},
	"guard_blade": {"close_damage_per_stack": 0.55, "base_shield": 16, "shield_per_stack": 4, "shield_duration": 4.0},
	"giant_echo": {"close_damage_per_10_percent": 0.20, "shield": 18, "shield_duration": 4.0},
	"light_edge": {"crit_damage_per_10_percent": 0.25},
	"compressed_core": {"projectile_count_penalty": 1, "damage_multiplier": 2.50, "fire_interval_multiplier": 1.15},
	"reflow_shards": {"fire_interval_multiplier": 0.90, "skill_damage_per_movement_tier": 0.12},
	"crimson_leech": {"health_cost": 15, "low_life_threshold": 0.35, "low_life_damage_bonus": 0.60, "low_life_life_steal": 8},
	"elite_reactor": {"shield_per_stack": 18, "shield_duration": 4.0},
	"last_stand_matrix": {"threshold": 0.35, "shield_per_stack": 26, "shield_duration": 4.0},
	"momentum_cache": {"required_movement_tier": 8, "shield_per_stack": 10, "shield_duration": 2.5, "cooldown": 9.0},
	"anchor_discharge": {"required_stationary_tier": 6, "shield_per_stack": 8, "shield_duration": 2.5, "cooldown": 12.0},
	"form_burst": {"explosion_radius": 14.0}
}

static func get_upgrade(upgrade_id: String) -> Dictionary:
	if not UPGRADE_DEFINITIONS.has(upgrade_id):
		return {}
	var data: Dictionary = UPGRADE_DEFINITIONS[upgrade_id].duplicate(true)
	data["id"] = upgrade_id
	return data

static func get_upgrade_pool() -> Array[Dictionary]:
	return get_upgrade_pool_for_ids(UPGRADE_ORDER)

static func get_upgrade_pool_for_ids(upgrade_ids: Array) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for upgrade_id in upgrade_ids:
		var upgrade := get_upgrade(str(upgrade_id))
		if not upgrade.is_empty():
			pool.append(upgrade)
	return pool

static func get_upgrade_pool_for_route(route_id: String) -> Array[Dictionary]:
	if route_id.is_empty() or not BUILD_ROUTE_DEFINITIONS.has(route_id):
		return []
	return get_upgrade_pool_for_ids(BUILD_ROUTE_DEFINITIONS[route_id].get("upgrades", []))

static func get_upgrade_title(upgrade_id: String, fallback: String = "强化") -> String:
	var upgrade := get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return fallback
	return str(upgrade.get("title", fallback))

static func get_upgrade_rarity(upgrade_id: String) -> String:
	var upgrade := get_upgrade(upgrade_id)
	return str(upgrade.get("rarity", "green")) if not upgrade.is_empty() else "green"

static func get_upgrade_preview(upgrade_id: String) -> String:
	var upgrade := get_upgrade(upgrade_id)
	return str(upgrade.get("preview", "")) if not upgrade.is_empty() else ""

static func get_upgrade_value(upgrade_id: String, key: String, fallback) -> Variant:
	var values: Dictionary = UPGRADE_VALUES.get(upgrade_id, {})
	return values.get(key, fallback)

static func get_upgrade_tags(upgrade_id: String) -> Dictionary:
	var tags: Dictionary = UPGRADE_TAGS.get(upgrade_id, {})
	return tags.duplicate(true)

static func get_upgrade_tag_list(upgrade_id: String, key: String) -> Array:
	var tags: Dictionary = UPGRADE_TAGS.get(upgrade_id, {})
	return tags.get(key, [])

static func get_upgrade_route_tags(upgrade_id: String) -> Array:
	var tags: Array = get_upgrade_tag_list(upgrade_id, "route_tags")
	if not tags.is_empty():
		return tags
	var inferred_tags: Array[String] = []
	for route_id in BUILD_ROUTE_ORDER:
		var route_definition: Dictionary = BUILD_ROUTE_DEFINITIONS.get(route_id, {})
		if route_definition.get("upgrades", []).has(upgrade_id):
			inferred_tags.append(route_id)
	return inferred_tags

static func get_skill_rarity_label(rarity: String) -> String:
	var definition: Dictionary = SKILL_RARITY_DEFINITIONS.get(rarity, SKILL_RARITY_DEFINITIONS["green"])
	return str(definition.get("label", "绿色"))

static func get_skill_rarity_weight(rarity: String) -> int:
	var definition: Dictionary = SKILL_RARITY_DEFINITIONS.get(rarity, SKILL_RARITY_DEFINITIONS["green"])
	return maxi(1, int(definition.get("weight", 1)))

static func get_shop_rarity_weight(rarity: String) -> int:
	var definition: Dictionary = SKILL_RARITY_DEFINITIONS.get(rarity, SKILL_RARITY_DEFINITIONS["green"])
	return maxi(1, int(definition.get("shop_weight", 1)))

static func get_route_offer_ids(route_id: String) -> Array:
	if route_id.is_empty() or not BUILD_ROUTE_DEFINITIONS.has(route_id):
		return []
	return BUILD_ROUTE_DEFINITIONS[route_id].get("shop_offers", [])

static func get_route_signature_upgrades(route_id: String) -> Array:
	return ROUTE_SIGNATURE_UPGRADES.get(route_id, [])

static func get_route_synergy_ids(route_id: String) -> Array:
	return ROUTE_SYNERGY_DEFINITIONS.get(route_id, [])

static func get_upgrade_synergy_sources(upgrade_id: String) -> Array:
	return UPGRADE_SYNERGY_SOURCES.get(upgrade_id, [])

static func get_shop_skill_offers(completed_stage: int, offer_ids: Array = []) -> Array[Dictionary]:
	var ids := offer_ids
	if ids.is_empty():
		ids = SHOP_SKILL_OFFERS.keys()
	var offers: Array[Dictionary] = []
	for offer_id in ids:
		var offer := get_shop_skill_offer(str(offer_id), completed_stage)
		if not offer.is_empty():
			offers.append(offer)
	return offers

static func get_shop_skill_offer(offer_id: String, completed_stage: int) -> Dictionary:
	if not SHOP_SKILL_OFFERS.has(offer_id):
		return {}
	var template: Dictionary = SHOP_SKILL_OFFERS[offer_id].duplicate(true)
	var upgrade_id := str(template.get("reward_upgrade_id", ""))
	var upgrade := get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return {}
	template["id"] = offer_id
	template["title"] = str(template.get("title", upgrade.get("title", "技能")))
	template["description"] = str(upgrade.get("description", ""))
	template["cost"] = int(template.get("base_cost", 0)) + completed_stage * int(template.get("stage_cost", 0))
	template["reward_upgrade_title"] = str(template.get("title", upgrade.get("title", "技能")))
	template.erase("base_cost")
	template.erase("stage_cost")
	return template
