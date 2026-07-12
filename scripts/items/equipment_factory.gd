class_name EquipmentFactory
extends RefCounted

const RARITIES := [
	{"name": "普通", "color": Color(0.8, 0.8, 0.8), "weight": 70, "affixes": 1, "power": 1.0},
	{"name": "魔法", "color": Color(0.35, 0.55, 1.0), "weight": 24, "affixes": 2, "power": 1.25},
	{"name": "稀有", "color": Color(1.0, 0.85, 0.2), "weight": 6, "affixes": 3, "power": 1.6}
]

const AFFIXES := [
	{"id": "damage", "label": "伤害", "min": 3, "max": 8},
	{"id": "max_health", "label": "最大生命", "min": 10, "max": 25},
	{"id": "attack_speed", "label": "攻击速度", "min": 6, "max": 14},
	{"id": "move_speed", "label": "移动速度", "min": 12, "max": 24},
	{"id": "critical_chance", "label": "暴击率", "min": 4, "max": 9},
	{"id": "projectile_count", "label": "额外投射物", "min": 1, "max": 1, "level_scale": false},
	{"id": "pierce", "label": "穿透", "min": 1, "max": 1, "level_scale": false},
	{"id": "explosion_radius", "label": "爆裂范围", "min": 18, "max": 32}
]

const WEAPON_FORMS := [
	{
		"id": "focused",
		"name": "聚能法杖",
		"description": "单发伤害更高",
		"weight": 34,
		"score": 12,
		"damage_multiplier": 1.15
	},
	{
		"id": "scatter",
		"name": "散射法杖",
		"description": "额外发射 2 枚投射物",
		"weight": 28,
		"score": 16,
		"projectile_bonus": 2,
		"damage_multiplier": 0.75,
		"spread_degrees": 16.0
	},
	{
		"id": "piercing",
		"name": "穿透法杖",
		"description": "投射物可额外穿透 1 名敌人",
		"weight": 22,
		"score": 18,
		"pierce": 1,
		"damage_multiplier": 0.9
	},
	{
		"id": "burst",
		"name": "爆裂法杖",
		"description": "命中时造成小范围爆裂伤害",
		"weight": 16,
		"score": 20,
		"damage_multiplier": 0.85,
		"explosion_radius": 72.0,
		"explosion_damage_ratio": 0.45
	}
]

static func roll_weapon(enemy_level: int = 1) -> Dictionary:
	var rarity := _roll_rarity()
	var form := _roll_weapon_form()
	var affix_count: int = rarity["affixes"]
	var affix_pool := AFFIXES.duplicate(true)
	affix_pool.shuffle()
	var affixes: Array = []
	var score := int(form.get("score", 0))
	for index in range(min(affix_count, affix_pool.size())):
		var template: Dictionary = affix_pool[index]
		var value := randi_range(template["min"], template["max"])
		if bool(template.get("level_scale", true)):
			value += enemy_level
		value = int(round(float(value) * rarity["power"]))
		affixes.append({
			"id": template["id"],
			"label": template["label"],
			"value": value
		})
		score += _score_affix(template["id"], value)
	return {
		"name": "%s%s" % [rarity["name"], form["name"]],
		"slot": "weapon",
		"form": form,
		"rarity": rarity["name"],
		"color": rarity["color"],
		"affixes": affixes,
		"score": score
	}

static func describe(equipment: Dictionary) -> String:
	if equipment.is_empty():
		return "武器：无"
	var lines := ["%s (%s)" % [equipment["name"], equipment["rarity"]]]
	var form: Dictionary = equipment.get("form", {})
	if not form.is_empty():
		lines.append(str(form["description"]))
	for affix in equipment["affixes"]:
		var prefix := "+"
		if affix["id"] in ["attack_speed", "critical_chance"]:
			lines.append("%s%d%% %s" % [prefix, affix["value"], affix["label"]])
		elif affix["id"] == "projectile_count":
			lines.append("%s%d %s" % [prefix, affix["value"], affix["label"]])
		else:
			lines.append("%s%d %s" % [prefix, affix["value"], affix["label"]])
	return "\n".join(lines)

static func describe_with_score(equipment: Dictionary) -> String:
	if equipment.is_empty():
		return "武器：无\n评分：0"
	return "%s\n评分：%d" % [describe(equipment), get_score(equipment)]

static func get_score(equipment: Dictionary) -> int:
	return int(equipment.get("score", 0))

static func get_score_delta_text(candidate: Dictionary, current: Dictionary) -> String:
	var delta := get_score(candidate) - get_score(current)
	if current.is_empty():
		return "评分变化：+%d" % get_score(candidate)
	if delta >= 0:
		return "评分变化：+%d" % delta
	return "评分变化：%d" % delta

static func get_comparison_summary(candidate: Dictionary, current: Dictionary) -> String:
	var lines := [get_score_delta_text(candidate, current)]
	var candidate_profile := _build_combat_profile(candidate)
	var current_profile := _build_combat_profile(current)
	_add_form_delta(lines, candidate_profile, current_profile)
	_add_number_delta(lines, "伤害词缀", int(candidate_profile["damage"]), int(current_profile["damage"]), "")
	_add_percent_delta(lines, "伤害倍率", float(candidate_profile["damage_multiplier"]), float(current_profile["damage_multiplier"]))
	_add_number_delta(lines, "投射物", int(candidate_profile["projectile_count"]), int(current_profile["projectile_count"]), "")
	_add_number_delta(lines, "穿透", int(candidate_profile["pierce"]), int(current_profile["pierce"]), "")
	_add_number_delta(lines, "爆裂范围", int(candidate_profile["explosion_radius"]), int(current_profile["explosion_radius"]), "")
	_add_number_delta(lines, "攻击速度", int(candidate_profile["attack_speed"]), int(current_profile["attack_speed"]), "%")
	_add_number_delta(lines, "暴击率", int(candidate_profile["critical_chance"]), int(current_profile["critical_chance"]), "%")
	_add_number_delta(lines, "移动速度", int(candidate_profile["move_speed"]), int(current_profile["move_speed"]), "")
	_add_number_delta(lines, "最大生命", int(candidate_profile["max_health"]), int(current_profile["max_health"]), "")
	if lines.size() == 1:
		lines.append("核心变化：属性接近")
	return "\n".join(lines)

static func _roll_rarity() -> Dictionary:
	var total_weight := 0
	for rarity in RARITIES:
		total_weight += rarity["weight"]
	var roll := randi_range(1, total_weight)
	var cursor := 0
	for rarity in RARITIES:
		cursor += rarity["weight"]
		if roll <= cursor:
			return rarity
	return RARITIES[0]

static func _roll_weapon_form() -> Dictionary:
	var total_weight := 0
	for form in WEAPON_FORMS:
		total_weight += int(form["weight"])
	var roll := randi_range(1, total_weight)
	var cursor := 0
	for form in WEAPON_FORMS:
		cursor += int(form["weight"])
		if roll <= cursor:
			return form.duplicate(true)
	return WEAPON_FORMS[0].duplicate(true)

static func _score_affix(affix_id: String, value: int) -> int:
	match affix_id:
		"damage":
			return value * 4
		"max_health":
			return value
		"attack_speed":
			return value * 3
		"move_speed":
			return value * 2
		"critical_chance":
			return value * 5
		"projectile_count":
			return value * 16
		"pierce":
			return value * 14
		"explosion_radius":
			return value * 2
	return value

static func _build_combat_profile(equipment: Dictionary) -> Dictionary:
	var profile := {
		"form_name": "无",
		"damage": 0,
		"max_health": 0,
		"attack_speed": 0,
		"move_speed": 0,
		"critical_chance": 0,
		"projectile_count": 0,
		"pierce": 0,
		"explosion_radius": 0,
		"damage_multiplier": 1.0
	}
	if equipment.is_empty():
		return profile
	var form: Dictionary = equipment.get("form", {})
	if not form.is_empty():
		profile["form_name"] = str(form.get("name", "未知形态"))
		profile["projectile_count"] = int(form.get("projectile_bonus", 0))
		profile["pierce"] = int(form.get("pierce", 0))
		profile["explosion_radius"] = int(round(float(form.get("explosion_radius", 0.0))))
		profile["damage_multiplier"] = float(form.get("damage_multiplier", 1.0))
	for affix in equipment.get("affixes", []):
		var affix_id := str(affix["id"])
		var value := int(affix["value"])
		match affix_id:
			"damage":
				profile["damage"] = int(profile["damage"]) + value
			"max_health":
				profile["max_health"] = int(profile["max_health"]) + value
			"attack_speed":
				profile["attack_speed"] = int(profile["attack_speed"]) + value
			"move_speed":
				profile["move_speed"] = int(profile["move_speed"]) + value
			"critical_chance":
				profile["critical_chance"] = int(profile["critical_chance"]) + value
			"projectile_count":
				profile["projectile_count"] = int(profile["projectile_count"]) + value
			"pierce":
				profile["pierce"] = int(profile["pierce"]) + value
			"explosion_radius":
				profile["explosion_radius"] = int(profile["explosion_radius"]) + value
	return profile

static func _add_form_delta(lines: Array, candidate_profile: Dictionary, current_profile: Dictionary) -> void:
	var candidate_form := str(candidate_profile["form_name"])
	var current_form := str(current_profile["form_name"])
	if candidate_form == current_form:
		return
	lines.append("形态：%s -> %s" % [current_form, candidate_form])

static func _add_number_delta(lines: Array, label: String, candidate_value: int, current_value: int, suffix: String) -> void:
	var delta := candidate_value - current_value
	if delta == 0:
		return
	var sign := "+" if delta > 0 else ""
	lines.append("%s：%s%d%s" % [label, sign, delta, suffix])

static func _add_percent_delta(lines: Array, label: String, candidate_value: float, current_value: float) -> void:
	var delta := int(round((candidate_value - current_value) * 100.0))
	if delta == 0:
		return
	var sign := "+" if delta > 0 else ""
	lines.append("%s：%s%d%%" % [label, sign, delta])
