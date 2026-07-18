extends SceneTree

const SkillCatalog := preload("res://scripts/items/skill_catalog.gd")

const SKILL_REPEAT_WEIGHT_PER_STACK: float = 0.45
const SKILL_REPEAT_WEIGHT_CAP: float = 2.80
const SKILL_SYNERGY_WEIGHT_PER_SOURCE_STACK: float = 0.32
const SKILL_SYNERGY_WEIGHT_CAP: float = 2.25
const SKILL_TAG_SOURCE_WEIGHT_PER_MATCH: float = 0.34
const SKILL_TAG_SOURCE_WEIGHT_CAP: float = 2.60
const SKILL_TAG_ROUTE_WEIGHT_PER_STACK: float = 0.10
const SKILL_TAG_ROUTE_WEIGHT_CAP: float = 1.70
const SKILL_TAG_CONFLICT_WEIGHT: float = 0.48
const SKILL_ENGINE_FIRST_PICK_WEIGHT: float = 1.35

const REPORT_PATH := "res://docs/skill-offer-audit.md"
const TOP_COUNT := 10

var current_scenario: Dictionary = {}

func _initialize() -> void:
	var report := _build_report()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法写入出货审计报告：%s" % REPORT_PATH)
		quit(1)
		return
	file.store_string(report)
	file.close()
	print("已生成出货审计报告：%s" % REPORT_PATH)
	quit()

func _build_report() -> String:
	var lines: Array[String] = []
	lines.append("# 阶段 5 出货规则抽样报告")
	lines.append("")
	lines.append("本报告由 `tools/skill_offer_audit.gd` 生成，用于体检当前升级三选一和关间商店技能权重。")
	lines.append("")
	lines.append("## 权重公式")
	lines.append("")
	lines.append("- 基础权重来自技能稀有度。")
	lines.append("- 已拥有同技能：每层 x%.2f，上限 x%.2f。" % [1.0 + SKILL_REPEAT_WEIGHT_PER_STACK, SKILL_REPEAT_WEIGHT_CAP])
	lines.append("- 直接协同来源：每层 x%.2f，上限 x%.2f。" % [1.0 + SKILL_SYNERGY_WEIGHT_PER_SOURCE_STACK, SKILL_SYNERGY_WEIGHT_CAP])
	lines.append("- 标签读取命中：每个命中标签 x%.2f，上限 x%.2f。" % [1.0 + SKILL_TAG_SOURCE_WEIGHT_PER_MATCH, SKILL_TAG_SOURCE_WEIGHT_CAP])
	lines.append("- 已成型路线：每路线层 x%.2f，上限 x%.2f。" % [1.0 + SKILL_TAG_ROUTE_WEIGHT_PER_STACK, SKILL_TAG_ROUTE_WEIGHT_CAP])
	lines.append("- 首次核心引擎且命中读取条件：x%.2f。" % SKILL_ENGINE_FIRST_PICK_WEIGHT)
	lines.append("- 冲突标签命中：每个冲突标签 x%.2f。" % SKILL_TAG_CONFLICT_WEIGHT)
	lines.append("")
	lines.append("## 结论摘要")
	lines.append("")
	var summaries: Array[String] = []
	for scenario in _build_scenarios():
		current_scenario = scenario
		summaries.append(_summarize_scenario(scenario))
	lines.append_array(summaries)
	lines.append("")
	lines.append("## 场景明细")
	lines.append("")
	for scenario in _build_scenarios():
		current_scenario = scenario
		_append_scenario_detail(lines, scenario)
	while not lines.is_empty() and str(lines[-1]).is_empty():
		lines.pop_back()
	return "\n".join(lines) + "\n"

func _build_scenarios() -> Array[Dictionary]:
	return [
		{
			"id": "starter",
			"title": "无构筑开局",
			"health": 100,
			"max_health": 100,
			"summary": {"move_speed": 260, "player_size_bonus": 0, "attack_interval": 0.45, "projectiles": 1, "pierce": 0, "explosion_radius": 0, "shield": 0, "upgrade_stacks": {}}
		},
		{
			"id": "bulk_slow",
			"title": "体积迟缓",
			"health": 120,
			"max_health": 145,
			"summary": {"move_speed": 175, "player_size_bonus": 85, "attack_interval": 0.56, "projectiles": 3, "pierce": 0, "explosion_radius": 70, "shield": 18, "upgrade_stacks": {"multishot": 2, "mass_resonance": 1, "slow_resonance": 1, "heavy_shot": 1}}
		},
		{
			"id": "agile_light",
			"title": "轻装疾行",
			"health": 82,
			"max_health": 100,
			"summary": {"move_speed": 410, "player_size_bonus": -24, "attack_interval": 0.33, "projectiles": 1, "pierce": 0, "explosion_radius": 0, "shield": 0, "movement_focus_tier": 6, "upgrade_stacks": {"light_frame": 2, "light_resonance": 1, "haste_resonance": 1, "motion_focus": 1}}
		},
		{
			"id": "blast_heavy",
			"title": "爆裂重弹",
			"health": 110,
			"max_health": 130,
			"summary": {"move_speed": 215, "player_size_bonus": 55, "attack_interval": 0.62, "projectiles": 1, "pierce": 0, "explosion_radius": 120, "shield": 0, "upgrade_stacks": {"blast_core": 1, "shatter_blast": 1, "heavy_shot": 2, "compressed_core": 1, "overload_burst": 1}}
		},
		{
			"id": "chain_mobile",
			"title": "连锁追踪",
			"health": 90,
			"max_health": 100,
			"summary": {"move_speed": 330, "player_size_bonus": -5, "attack_interval": 0.30, "projectiles": 2, "pierce": 1, "explosion_radius": 0, "shield": 0, "movement_focus_tier": 5, "upgrade_stacks": {"chain_spark": 2, "homing_shards": 1, "orbit_blade": 1, "rapid_resonance": 1, "conduit_coil": 1}}
		},
		{
			"id": "close_guard",
			"title": "近身护盾",
			"health": 118,
			"max_health": 140,
			"summary": {"move_speed": 235, "player_size_bonus": 45, "attack_interval": 0.50, "projectiles": 2, "pierce": 0, "explosion_radius": 24, "shield": 22, "upgrade_stacks": {"close_slash": 2, "pulse_field": 1, "guard_blade": 1, "giant_echo": 1}}
		},
		{
			"id": "blood_low",
			"title": "血潮低血",
			"health": 42,
			"max_health": 150,
			"summary": {"move_speed": 230, "player_size_bonus": 10, "attack_interval": 0.46, "projectiles": 1, "pierce": 0, "explosion_radius": 0, "shield": 0, "upgrade_stacks": {"blood_pact": 2, "crimson_leech": 1, "max_health": 1}}
		}
	]

func _summarize_scenario(scenario: Dictionary) -> String:
	var upgrade_weights := _build_upgrade_weights(false)
	var top_upgrades := _top_weight_rows(upgrade_weights, 5)
	var route_summary := _route_weight_summary(upgrade_weights)
	var active_tags := _get_active_skill_tags()
	return "- %s：升级前五为 %s；路线权重为 %s；主动标签 %s。" % [
		str(scenario.get("title", "")),
		_format_top_titles(top_upgrades),
		route_summary,
		", ".join(active_tags.keys())
	]

func _append_scenario_detail(lines: Array[String], scenario: Dictionary) -> void:
	lines.append("### %s" % str(scenario.get("title", "")))
	lines.append("")
	lines.append("- 主动标签：`%s`" % "`, `".join(_get_active_skill_tags().keys()))
	lines.append("- 路线分数：%s" % _format_route_scores(_get_active_build_route_scores()))
	lines.append("")
	lines.append("升级权重前 %d：" % TOP_COUNT)
	lines.append("")
	lines.append("| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |")
	lines.append("|---|---:|---|---|---|---|")
	for row in _top_weight_rows(_build_upgrade_weights(false), TOP_COUNT):
		lines.append(_format_weight_row(row))
	lines.append("")
	lines.append("商店权重前 %d：" % TOP_COUNT)
	lines.append("")
	lines.append("| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 |")
	lines.append("|---|---:|---|---|---|---|")
	for row in _top_weight_rows(_build_upgrade_weights(true), TOP_COUNT):
		lines.append(_format_weight_row(row))
	lines.append("")

func _build_upgrade_weights(use_shop_weight: bool) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for upgrade in SkillCatalog.get_upgrade_pool():
		var upgrade_id := str(upgrade.get("id", ""))
		if upgrade_id in ["heal", "strong_heal"]:
			continue
		var rarity := SkillCatalog.get_upgrade_rarity(upgrade_id)
		var base_weight := SkillCatalog.get_shop_rarity_weight(rarity) if use_shop_weight else SkillCatalog.get_skill_rarity_weight(rarity)
		var weight := _apply_skill_momentum_weight(base_weight, upgrade_id)
		rows.append({
			"id": upgrade_id,
			"title": SkillCatalog.get_upgrade_title(upgrade_id, upgrade_id),
			"rarity": rarity,
			"weight": weight,
			"routes": SkillCatalog.get_upgrade_route_tags(upgrade_id),
			"source_matches": _get_source_tag_matches(upgrade_id),
			"conflict_matches": _get_conflict_tag_matches(upgrade_id)
		})
	return rows

func _apply_skill_momentum_weight(base_weight: int, upgrade_id: String) -> int:
	var weighted := _apply_repeat_skill_weight(base_weight, upgrade_id)
	weighted = _apply_synergy_skill_weight(weighted, upgrade_id)
	weighted = _apply_tag_skill_weight(weighted, upgrade_id)
	return weighted

func _apply_repeat_skill_weight(base_weight: int, upgrade_id: String) -> int:
	var current_stack := _get_upgrade_stack_count(upgrade_id)
	if current_stack <= 0:
		return maxi(1, base_weight)
	var multiplier := minf(SKILL_REPEAT_WEIGHT_CAP, 1.0 + float(current_stack) * SKILL_REPEAT_WEIGHT_PER_STACK)
	return maxi(1, int(round(float(base_weight) * multiplier)))

func _apply_synergy_skill_weight(base_weight: int, upgrade_id: String) -> int:
	var source_stack_total := 0
	for source_id in SkillCatalog.get_upgrade_synergy_sources(upgrade_id):
		source_stack_total += _get_upgrade_stack_count(str(source_id))
	if source_stack_total <= 0:
		return maxi(1, base_weight)
	var multiplier := minf(SKILL_SYNERGY_WEIGHT_CAP, 1.0 + float(source_stack_total) * SKILL_SYNERGY_WEIGHT_PER_SOURCE_STACK)
	return maxi(1, int(round(float(base_weight) * multiplier)))

func _apply_tag_skill_weight(base_weight: int, upgrade_id: String) -> int:
	var active_tags := _get_active_skill_tags()
	var route_scores := _get_active_build_route_scores()
	var weighted := float(maxi(1, base_weight))
	var source_matches := 0
	for tag in SkillCatalog.get_upgrade_tag_list(upgrade_id, "source_tags"):
		if active_tags.has(str(tag)):
			source_matches += 1
	if source_matches > 0:
		weighted *= minf(SKILL_TAG_SOURCE_WEIGHT_CAP, 1.0 + float(source_matches) * SKILL_TAG_SOURCE_WEIGHT_PER_MATCH)
	for route_id in SkillCatalog.get_upgrade_route_tags(upgrade_id):
		var route_score := int(route_scores.get(str(route_id), 0))
		if route_score > 0:
			weighted *= minf(SKILL_TAG_ROUTE_WEIGHT_CAP, 1.0 + float(route_score) * SKILL_TAG_ROUTE_WEIGHT_PER_STACK)
	var engine_tags := SkillCatalog.get_upgrade_tag_list(upgrade_id, "engine_tags")
	if not engine_tags.is_empty() and _get_upgrade_stack_count(upgrade_id) <= 0 and source_matches > 0:
		weighted *= SKILL_ENGINE_FIRST_PICK_WEIGHT
	for tag in SkillCatalog.get_upgrade_tag_list(upgrade_id, "conflict_tags"):
		if active_tags.has(str(tag)):
			weighted *= SKILL_TAG_CONFLICT_WEIGHT
	return maxi(1, int(round(weighted)))

func _get_active_skill_tags() -> Dictionary:
	var active_tags := {}
	var summary: Dictionary = current_scenario.get("summary", {})
	var upgrade_stacks: Dictionary = summary.get("upgrade_stacks", {})
	for upgrade_id in upgrade_stacks.keys():
		if int(upgrade_stacks.get(upgrade_id, 0)) <= 0:
			continue
		for tag_key in ["effect_tags", "engine_tags"]:
			for tag in SkillCatalog.get_upgrade_tag_list(str(upgrade_id), tag_key):
				active_tags[str(tag)] = true
	var player_size_bonus := int(summary.get("player_size_bonus", 0))
	if player_size_bonus >= 20:
		active_tags["large_body"] = true
	elif player_size_bonus <= -10:
		active_tags["small_body"] = true
	var move_speed := int(summary.get("move_speed", 260))
	if move_speed >= 315:
		active_tags["fast_move"] = true
	elif move_speed <= 220:
		active_tags["slow_move"] = true
	var attack_interval := float(summary.get("attack_interval", 0.45))
	if attack_interval <= 0.34:
		active_tags["fast_attack"] = true
	elif attack_interval >= 0.52:
		active_tags["slow_attack"] = true
	if int(summary.get("projectiles", 1)) >= 3:
		active_tags["multi_projectile"] = true
	if int(summary.get("pierce", 0)) > 0:
		active_tags["pierce"] = true
	if int(summary.get("explosion_radius", 0)) >= 40:
		active_tags["blast"] = true
	if int(summary.get("shield", 0)) > 0:
		active_tags["shielded"] = true
	if int(current_scenario.get("max_health", 100)) > 0 and int(current_scenario.get("health", 100)) <= int(round(float(current_scenario.get("max_health", 100)) * 0.40)):
		active_tags["low_life"] = true
	if int(current_scenario.get("max_health", 100)) >= 130:
		active_tags["high_health"] = true
	if int(summary.get("movement_focus_tier", 0)) > 0:
		active_tags["moving"] = true
	if int(summary.get("stationary_focus_tier", 0)) > 0:
		active_tags["stationary"] = true
	return active_tags

func _get_active_build_route_scores() -> Dictionary:
	var route_scores := {}
	var summary: Dictionary = current_scenario.get("summary", {})
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		route_scores[route_id] = 0
	var upgrade_stacks: Dictionary = summary.get("upgrade_stacks", {})
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		var score := 0
		for upgrade_id in SkillCatalog.get_route_signature_upgrades(route_id):
			score += int(upgrade_stacks.get(str(upgrade_id), 0))
		route_scores[route_id] = score
	match str(summary.get("weapon_form", "")):
		"piercing":
			route_scores["pierce"] = int(route_scores.get("pierce", 0)) + 1
		"burst":
			route_scores["blast"] = int(route_scores.get("blast", 0)) + 1
		"scatter":
			route_scores["bulk"] = int(route_scores.get("bulk", 0)) + 1
		"focused":
			route_scores["pierce"] = int(route_scores.get("pierce", 0)) + 1
	if int(summary.get("move_speed", 0)) > 300:
		route_scores["agile"] = int(route_scores.get("agile", 0)) + 1
	if int(summary.get("player_size_bonus", 0)) < 0:
		route_scores["agile"] = int(route_scores.get("agile", 0)) + 1
	return route_scores

func _get_upgrade_stack_count(upgrade_id: String) -> int:
	var summary: Dictionary = current_scenario.get("summary", {})
	var upgrade_stacks: Dictionary = summary.get("upgrade_stacks", {})
	return int(upgrade_stacks.get(upgrade_id, 0))

func _get_source_tag_matches(upgrade_id: String) -> Array[String]:
	var active_tags := _get_active_skill_tags()
	var matches: Array[String] = []
	for tag in SkillCatalog.get_upgrade_tag_list(upgrade_id, "source_tags"):
		if active_tags.has(str(tag)):
			matches.append(str(tag))
	return matches

func _get_conflict_tag_matches(upgrade_id: String) -> Array[String]:
	var active_tags := _get_active_skill_tags()
	var matches: Array[String] = []
	for tag in SkillCatalog.get_upgrade_tag_list(upgrade_id, "conflict_tags"):
		if active_tags.has(str(tag)):
			matches.append(str(tag))
	return matches

func _top_weight_rows(rows: Array[Dictionary], count: int) -> Array[Dictionary]:
	var sorted := rows.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("weight", 0)) == int(b.get("weight", 0)):
			return str(a.get("id", "")) < str(b.get("id", ""))
		return int(a.get("weight", 0)) > int(b.get("weight", 0))
	)
	return sorted.slice(0, mini(count, sorted.size()))

func _format_weight_row(row: Dictionary) -> String:
	return "| %s | %d | %s | %s | %s | %s |" % [
		str(row.get("title", "")),
		int(row.get("weight", 0)),
		str(row.get("rarity", "")),
		", ".join(row.get("routes", [])),
		", ".join(row.get("source_matches", [])),
		", ".join(row.get("conflict_matches", []))
	]

func _format_top_titles(rows: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for row in rows:
		parts.append("%s(%d)" % [str(row.get("title", "")), int(row.get("weight", 0))])
	return "、".join(parts)

func _route_weight_summary(rows: Array[Dictionary]) -> String:
	var totals := {}
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		totals[route_id] = 0
	for row in rows:
		for route_id in row.get("routes", []):
			totals[str(route_id)] = int(totals.get(str(route_id), 0)) + int(row.get("weight", 0))
	return _format_route_scores(totals)

func _format_route_scores(route_scores: Dictionary) -> String:
	var parts: Array[String] = []
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		parts.append("%s %d" % [str(route_id), int(route_scores.get(route_id, 0))])
	return " / ".join(parts)
