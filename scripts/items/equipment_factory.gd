class_name EquipmentFactory
extends RefCounted

const RARITIES := [
	{"name": "普通", "color": Color(0.8, 0.8, 0.8), "weight": 68, "affixes": 1, "power": 1.0, "salvage_base": 1},
	{"name": "魔法", "color": Color(0.35, 0.55, 1.0), "weight": 25, "affixes": 2, "power": 1.25, "salvage_base": 3},
	{"name": "稀有", "color": Color(1.0, 0.85, 0.2), "weight": 7, "affixes": 3, "power": 1.6, "salvage_base": 6}
]

const EQUIPMENT_SLOTS := [
	{"id": "weapon", "label": "武器", "base_name": "法杖", "weight": 42},
	{"id": "helmet", "label": "头盔", "base_name": "头盔", "weight": 12},
	{"id": "armor", "label": "护甲", "base_name": "战甲", "weight": 16},
	{"id": "boots", "label": "鞋子", "base_name": "战靴", "weight": 12},
	{"id": "necklace", "label": "项链", "base_name": "项链", "weight": 9},
	{"id": "ring", "label": "戒指", "base_name": "戒指", "weight": 9}
]

const AFFIXES := [
	{"id": "damage", "label": "伤害", "min": 3, "max": 8},
	{"id": "max_health", "label": "最大生命", "min": 10, "max": 25},
	{"id": "attack_speed", "label": "攻击速度", "min": 6, "max": 14},
	{"id": "move_speed", "label": "移动速度", "min": 12, "max": 24},
	{"id": "critical_chance", "label": "暴击率", "min": 4, "max": 9},
	{"id": "projectile_count", "label": "额外投射物", "min": 1, "max": 1, "level_scale": false},
	{"id": "pierce", "label": "穿透", "min": 1, "max": 1, "level_scale": false},
	{"id": "explosion_radius", "label": "爆裂范围", "min": 18, "max": 32},
	{"id": "life_steal", "label": "吸血", "min": 3, "max": 7},
	{"id": "gold_bonus", "label": "金币获取", "min": 8, "max": 18}
]

const SLOT_AFFIXES := {
	"weapon": ["damage", "attack_speed", "critical_chance", "projectile_count", "pierce", "explosion_radius", "life_steal"],
	"helmet": ["max_health", "critical_chance", "life_steal"],
	"armor": ["max_health", "move_speed", "gold_bonus"],
	"boots": ["move_speed", "attack_speed", "gold_bonus"],
	"necklace": ["critical_chance", "life_steal", "explosion_radius", "gold_bonus"],
	"ring": ["attack_speed", "projectile_count", "pierce", "gold_bonus"]
}

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

static func roll_equipment(enemy_level: int = 1) -> Dictionary:
	var slot := _roll_equipment_slot()
	return _roll_equipment_for_slot(str(slot["id"]), enemy_level)

static func roll_weapon(enemy_level: int = 1) -> Dictionary:
	return _roll_equipment_for_slot("weapon", enemy_level)

static func _roll_equipment_for_slot(slot_id: String, enemy_level: int = 1) -> Dictionary:
	var rarity := _roll_rarity()
	var slot := _get_slot_template(slot_id)
	var is_weapon := slot_id == "weapon"
	var form := _roll_weapon_form() if is_weapon else {}
	var affix_count: int = rarity["affixes"]
	var affix_pool := _get_affix_pool_for_slot(slot_id)
	affix_pool.shuffle()
	var affixes: Array = []
	var score := int(form.get("score", 0)) if is_weapon else 8
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
	var equipment_name := "%s%s" % [rarity["name"], slot["base_name"]]
	if is_weapon:
		equipment_name = "%s%s" % [rarity["name"], form["name"]]
	var equipment := {
		"name": equipment_name,
		"slot": slot_id,
		"slot_label": slot["label"],
		"level": enemy_level,
		"form": form,
		"rarity": rarity["name"],
		"color": rarity["color"],
		"affixes": affixes,
		"score": score
	}
	equipment["salvage_value"] = get_salvage_value(equipment)
	return equipment

static func describe(equipment: Dictionary) -> String:
	if equipment.is_empty():
		return "装备：无"
	var lines := ["%s (%s)" % [equipment["name"], equipment["rarity"]]]
	lines.append("类型：%s" % get_slot_label(str(equipment.get("slot", "weapon"))))
	lines.append("等级：%d" % int(equipment.get("level", 1)))
	var form: Dictionary = equipment.get("form", {})
	if not form.is_empty():
		lines.append(str(form["description"]))
	for affix in equipment["affixes"]:
		var prefix := "+"
		if affix["id"] in ["attack_speed", "critical_chance", "life_steal", "gold_bonus"]:
			lines.append("%s%d%% %s" % [prefix, affix["value"], affix["label"]])
		elif affix["id"] == "projectile_count":
			lines.append("%s%d %s" % [prefix, affix["value"], affix["label"]])
		else:
			lines.append("%s%d %s" % [prefix, affix["value"], affix["label"]])
	return "\n".join(lines)

static func describe_with_score(equipment: Dictionary) -> String:
	if equipment.is_empty():
		return "装备：无\n评分：0"
	return "%s\n评分：%d" % [describe(equipment), get_score(equipment)]

static func describe_loadout(equipped_items: Dictionary) -> String:
	var lines := []
	for slot in EQUIPMENT_SLOTS:
		var slot_id := str(slot["id"])
		var equipment: Dictionary = equipped_items.get(slot_id, {})
		if equipment.is_empty():
			lines.append("%s：无" % slot["label"])
		else:
			lines.append("%s：%s 评分 %d" % [slot["label"], equipment["name"], get_score(equipment)])
	return "\n".join(lines)

static func describe_loadout_summary(equipped_items: Dictionary) -> String:
	var total_score := 0
	var profile := {
		"damage": 0,
		"max_health": 0,
		"attack_speed": 0,
		"move_speed": 0,
		"critical_chance": 0,
		"projectile_count": 0,
		"pierce": 0,
		"explosion_radius": 0,
		"life_steal": 0,
		"gold_bonus": 0
	}
	var weapon_form := "无"
	var weapon_multiplier := 1.0
	for slot in EQUIPMENT_SLOTS:
		var slot_id := str(slot["id"])
		var equipment: Dictionary = equipped_items.get(slot_id, {})
		if equipment.is_empty():
			continue
		total_score += get_score(equipment)
		var item_profile := _build_combat_profile(equipment)
		if slot_id == "weapon":
			weapon_form = str(item_profile["form_name"])
			weapon_multiplier = float(item_profile["damage_multiplier"])
		for key in profile.keys():
			profile[key] = int(profile[key]) + int(item_profile[key])
	var lines := [
		"构筑总览",
		"总评分：%d" % total_score,
		"武器形态：%s" % weapon_form
	]
	var multiplier_delta := int(round((weapon_multiplier - 1.0) * 100.0))
	if multiplier_delta != 0:
		var sign := "+" if multiplier_delta > 0 else ""
		lines.append("伤害倍率：%s%d%%" % [sign, multiplier_delta])
	_add_summary_value(lines, "伤害", int(profile["damage"]), "")
	_add_summary_value(lines, "最大生命", int(profile["max_health"]), "")
	_add_summary_value(lines, "攻击速度", int(profile["attack_speed"]), "%")
	_add_summary_value(lines, "移动速度", int(profile["move_speed"]), "")
	_add_summary_value(lines, "暴击率", int(profile["critical_chance"]), "%")
	_add_summary_value(lines, "吸血", int(profile["life_steal"]), "%")
	_add_summary_value(lines, "金币获取", int(profile["gold_bonus"]), "%")
	_add_summary_value(lines, "投射物", int(profile["projectile_count"]), "")
	_add_summary_value(lines, "穿透", int(profile["pierce"]), "")
	_add_summary_value(lines, "爆裂范围", int(profile["explosion_radius"]), "")
	return "\n".join(lines)

static func get_score(equipment: Dictionary) -> int:
	return int(equipment.get("score", 0))

static func get_score_delta_value(candidate: Dictionary, current: Dictionary) -> int:
	return get_score(candidate) - get_score(current)

static func get_score_delta_label(candidate: Dictionary, current: Dictionary) -> String:
	var delta: int = get_score_delta_value(candidate, current)
	if current.is_empty():
		return "+%d" % get_score(candidate)
	if delta > 0:
		return "+%d" % delta
	return "%d" % delta

static func get_salvage_value(equipment: Dictionary) -> int:
	if equipment.is_empty():
		return 0
	var stored_value := int(equipment.get("salvage_value", 0))
	if stored_value > 0:
		return stored_value
	var rarity_base := _get_rarity_salvage_base(str(equipment.get("rarity", "")))
	var score_value := int(ceil(float(get_score(equipment)) / 12.0))
	return clampi(rarity_base + score_value, 1, 30)

static func get_rarity_rank(equipment: Dictionary) -> int:
	var rarity_name := str(equipment.get("rarity", ""))
	for index in range(RARITIES.size()):
		if str(RARITIES[index]["name"]) == rarity_name:
			return index
	return 0

static func get_slot_label(slot_id: String) -> String:
	for slot in EQUIPMENT_SLOTS:
		if str(slot["id"]) == slot_id:
			return str(slot["label"])
	return "装备"

static func should_sort_before(left: Dictionary, right: Dictionary) -> bool:
	var left_rarity := get_rarity_rank(left)
	var right_rarity := get_rarity_rank(right)
	if left_rarity != right_rarity:
		return left_rarity > right_rarity
	var left_level := int(left.get("level", 1))
	var right_level := int(right.get("level", 1))
	if left_level != right_level:
		return left_level > right_level
	var left_score := get_score(left)
	var right_score := get_score(right)
	if left_score != right_score:
		return left_score > right_score
	return str(left.get("name", "")) < str(right.get("name", ""))

static func get_score_delta_text(candidate: Dictionary, current: Dictionary) -> String:
	var delta: int = get_score_delta_value(candidate, current)
	if current.is_empty():
		return "评分变化：+%d" % get_score(candidate)
	if delta >= 0:
		return "评分变化：+%d" % delta
	return "评分变化：%d" % delta

static func get_form_name(equipment: Dictionary) -> String:
	if str(equipment.get("slot", "weapon")) != "weapon":
		return get_slot_label(str(equipment.get("slot", "")))
	var form: Dictionary = equipment.get("form", {})
	if form.is_empty():
		return "无形态"
	return str(form.get("name", "未知形态"))

static func get_recommendation_text(candidate: Dictionary, current: Dictionary) -> String:
	if candidate.is_empty():
		return "未选择装备"
	var score_delta: int = get_score_delta_value(candidate, current)
	var candidate_profile: Dictionary = _build_combat_profile(candidate)
	var current_profile: Dictionary = _build_combat_profile(current)
	var primary_change: String = _get_primary_change(candidate_profile, current_profile)
	var change_suffix := ""
	if not primary_change.is_empty():
		change_suffix = "，%s" % primary_change
	if current.is_empty():
		return "推荐装备：当前槽位为空%s" % change_suffix
	if score_delta >= 15:
		return "推荐装备：评分 %s%s" % [get_score_delta_label(candidate, current), change_suffix]
	if score_delta >= 0:
		return "可考虑：评分 %s%s" % [get_score_delta_label(candidate, current), change_suffix]
	if not primary_change.is_empty():
		return "构筑取向：评分 %s，但%s" % [get_score_delta_label(candidate, current), primary_change]
	return "整体较弱：评分 %s" % get_score_delta_label(candidate, current)

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
	_add_number_delta(lines, "吸血", int(candidate_profile["life_steal"]), int(current_profile["life_steal"]), "%")
	_add_number_delta(lines, "金币获取", int(candidate_profile["gold_bonus"]), int(current_profile["gold_bonus"]), "%")
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

static func _roll_equipment_slot() -> Dictionary:
	var total_weight := 0
	for slot in EQUIPMENT_SLOTS:
		total_weight += int(slot["weight"])
	var roll := randi_range(1, total_weight)
	var cursor := 0
	for slot in EQUIPMENT_SLOTS:
		cursor += int(slot["weight"])
		if roll <= cursor:
			return slot
	return EQUIPMENT_SLOTS[0]

static func _get_slot_template(slot_id: String) -> Dictionary:
	for slot in EQUIPMENT_SLOTS:
		if str(slot["id"]) == slot_id:
			return slot
	return EQUIPMENT_SLOTS[0]

static func _get_affix_pool_for_slot(slot_id: String) -> Array:
	var allowed_ids: Array = SLOT_AFFIXES.get(slot_id, SLOT_AFFIXES["weapon"])
	var pool: Array = []
	for affix in AFFIXES:
		if allowed_ids.has(str(affix["id"])):
			pool.append(affix.duplicate(true))
	return pool

static func _get_rarity_salvage_base(rarity_name: String) -> int:
	for rarity in RARITIES:
		if str(rarity["name"]) == rarity_name:
			return int(rarity.get("salvage_base", 1))
	return 1

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
		"life_steal":
			return value * 6
		"gold_bonus":
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
		"life_steal": 0,
		"gold_bonus": 0,
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
			"life_steal":
				profile["life_steal"] = int(profile["life_steal"]) + value
			"gold_bonus":
				profile["gold_bonus"] = int(profile["gold_bonus"]) + value
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

static func _add_summary_value(lines: Array, label: String, value: int, suffix: String) -> void:
	if value == 0:
		return
	lines.append("%s：+%d%s" % [label, value, suffix])

static func _get_primary_change(candidate_profile: Dictionary, current_profile: Dictionary) -> String:
	var projectile_delta := int(candidate_profile["projectile_count"]) - int(current_profile["projectile_count"])
	if projectile_delta > 0:
		return "投射物 +%d" % projectile_delta
	var pierce_delta := int(candidate_profile["pierce"]) - int(current_profile["pierce"])
	if pierce_delta > 0:
		return "穿透 +%d" % pierce_delta
	var explosion_delta := int(candidate_profile["explosion_radius"]) - int(current_profile["explosion_radius"])
	if explosion_delta > 0:
		return "爆裂范围 +%d" % explosion_delta
	var damage_delta := int(candidate_profile["damage"]) - int(current_profile["damage"])
	if damage_delta > 0:
		return "伤害 +%d" % damage_delta
	var critical_delta := int(candidate_profile["critical_chance"]) - int(current_profile["critical_chance"])
	if critical_delta > 0:
		return "暴击率 +%d%%" % critical_delta
	var life_steal_delta := int(candidate_profile["life_steal"]) - int(current_profile["life_steal"])
	if life_steal_delta > 0:
		return "吸血 +%d%%" % life_steal_delta
	var attack_speed_delta := int(candidate_profile["attack_speed"]) - int(current_profile["attack_speed"])
	if attack_speed_delta > 0:
		return "攻击速度 +%d%%" % attack_speed_delta
	var gold_bonus_delta := int(candidate_profile["gold_bonus"]) - int(current_profile["gold_bonus"])
	if gold_bonus_delta > 0:
		return "金币获取 +%d%%" % gold_bonus_delta
	var health_delta := int(candidate_profile["max_health"]) - int(current_profile["max_health"])
	if health_delta > 0:
		return "最大生命 +%d" % health_delta
	var move_speed_delta := int(candidate_profile["move_speed"]) - int(current_profile["move_speed"])
	if move_speed_delta > 0:
		return "移动速度 +%d" % move_speed_delta
	var multiplier_delta := int(round((float(candidate_profile["damage_multiplier"]) - float(current_profile["damage_multiplier"])) * 100.0))
	if multiplier_delta != 0:
		var sign := "+" if multiplier_delta > 0 else ""
		return "伤害倍率 %s%d%%" % [sign, multiplier_delta]
	var candidate_form := str(candidate_profile["form_name"])
	var current_form := str(current_profile["form_name"])
	if candidate_form != current_form:
		return "形态改变"
	return ""
