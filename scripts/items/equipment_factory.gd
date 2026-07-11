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
	{"id": "attack_speed", "label": "攻击速度", "min": 6, "max": 14}
]

static func roll_weapon(enemy_level: int = 1) -> Dictionary:
	var rarity := _roll_rarity()
	var affix_count: int = rarity["affixes"]
	var affix_pool := AFFIXES.duplicate(true)
	affix_pool.shuffle()
	var affixes: Array = []
	var score := 0
	for index in range(min(affix_count, affix_pool.size())):
		var template: Dictionary = affix_pool[index]
		var value := randi_range(template["min"], template["max"]) + enemy_level
		value = int(round(float(value) * rarity["power"]))
		affixes.append({
			"id": template["id"],
			"label": template["label"],
			"value": value
		})
		score += _score_affix(template["id"], value)
	return {
		"name": "%s法杖" % rarity["name"],
		"slot": "weapon",
		"rarity": rarity["name"],
		"color": rarity["color"],
		"affixes": affixes,
		"score": score
	}

static func describe(equipment: Dictionary) -> String:
	if equipment.is_empty():
		return "武器：无"
	var lines := ["%s (%s)" % [equipment["name"], equipment["rarity"]]]
	for affix in equipment["affixes"]:
		var prefix := "+"
		if affix["id"] == "attack_speed":
			lines.append("%s%d%% %s" % [prefix, affix["value"], affix["label"]])
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

static func _score_affix(affix_id: String, value: int) -> int:
	match affix_id:
		"damage":
			return value * 4
		"max_health":
			return value
		"attack_speed":
			return value * 3
	return value
