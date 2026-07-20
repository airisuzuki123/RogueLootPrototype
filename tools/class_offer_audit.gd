extends SceneTree

const SkillCatalog := preload("res://scripts/items/skill_catalog.gd")
const CharacterClassCatalog := preload("res://scripts/items/character_class_catalog.gd")

const REPORT_PATH := "res://docs/class-offer-audit.md"
const TOP_COUNT := 8
const DIVERSITY_TOP_COUNT := 8
const MIN_ROUTE_VARIETY := 3
const MIN_GROUP_CLEAR_TOP_COUNT := 2
const GROUP_CLEAR_UPGRADE_IDS := {
	"multishot": true,
	"piercing_rounds": true,
	"blast_core": true,
	"chain_spark": true,
	"orbit_blade": true,
	"homing_shards": true,
	"close_slash": true,
	"pulse_field": true,
	"channel_beam": true,
	"shatter_blast": true,
	"pierce_amp": true,
	"conduit_coil": true,
	"guard_blade": true,
	"overload_burst": true,
	"reflow_shards": true
}

var current_scenario: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	var report := _build_report()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法写入职业出货审计报告：%s" % REPORT_PATH)
		quit(1)
		return
	file.store_string(report)
	file.close()
	if failures.is_empty():
		print("已生成职业出货审计报告：%s" % REPORT_PATH)
		quit()
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _build_report() -> String:
	failures.clear()
	var lines: Array[String] = []
	lines.append("# 阶段 5.5 职业出货审计报告")
	lines.append("")
	lines.append("本报告由 `tools/class_offer_audit.gd` 生成，用于检查初始职业对升级三选一和关间商店技能权重的开局偏向。")
	lines.append("")
	lines.append("## 审计口径")
	lines.append("")
	lines.append("- 每个职业只模拟选择职业后的开局状态，不模拟后续升级、商店购买或装备。")
	lines.append("- 职业路线偏向会提高相关路线分数，职业标签偏向会参与标签命中和技能权重。")
	lines.append("- 检查高权重候选中是否保留至少 %d 个清群入口，并至少覆盖 %d 类路线，避免职业开局只剩单一路线。" % [MIN_GROUP_CLEAR_TOP_COUNT, MIN_ROUTE_VARIETY])
	lines.append("- 报告只展示内部审计数据；游戏内 UI 不显示路线名、标签名或权重规则。")
	lines.append("")
	lines.append("## 结论摘要")
	lines.append("")
	var scenarios := _build_class_scenarios()
	for scenario in scenarios:
		current_scenario = scenario
		lines.append(_summarize_scenario(scenario))
	lines.append("")
	lines.append("## 职业明细")
	lines.append("")
	for scenario in scenarios:
		current_scenario = scenario
		_append_scenario_detail(lines, scenario)
	while not lines.is_empty() and str(lines[-1]).is_empty():
		lines.pop_back()
	return "\n".join(lines) + "\n"

func _build_class_scenarios() -> Array[Dictionary]:
	var scenarios: Array[Dictionary] = []
	for class_data in CharacterClassCatalog.get_class_list():
		var initial_stats: Dictionary = class_data.get("initial_stats", {})
		var move_speed := int(round(260.0 * float(initial_stats.get("move_speed_multiplier", 1.0))))
		var player_size_bonus := int(round(float(initial_stats.get("player_size_bonus", 0.0)) * 100.0))
		var attack_interval := 0.45 * float(initial_stats.get("fire_interval_multiplier", 1.0))
		var explosion_radius := int(round(float(initial_stats.get("explosion_radius", 0.0))))
		var shield := int(initial_stats.get("shield", 0))
		scenarios.append({
			"id": str(class_data.get("id", "")),
			"title": str(class_data.get("name", "未知职业")),
			"class_data": class_data.duplicate(true),
			"health": 100,
			"max_health": 100,
			"summary": {
				"move_speed": move_speed,
				"player_size_bonus": player_size_bonus,
				"attack_interval": attack_interval,
				"projectiles": 1,
				"pierce": 0,
				"explosion_radius": explosion_radius,
				"shield": shield,
				"upgrade_stacks": {}
			}
		})
	return scenarios

func _summarize_scenario(scenario: Dictionary) -> String:
	var upgrade_rows := _build_upgrade_weights(false)
	var shop_rows := _build_upgrade_weights(true)
	var audit := _evaluate_offer_health(upgrade_rows, shop_rows)
	var passed := bool(audit.get("passed", false))
	if not passed:
		failures.append("%s：职业出货清群或路线覆盖不足，升级清群 %d / 商店清群 %d / 升级路线 %d / 商店路线 %d" % [
			str(scenario.get("title", "")),
			int(audit.get("upgrade_group_clear_count", 0)),
			int(audit.get("shop_group_clear_count", 0)),
			int(audit.get("upgrade_route_count", 0)),
			int(audit.get("shop_route_count", 0))
		])
	return "- %s：%s；升级前五为 %s；商店前五为 %s；清群候选 升级 %d / 商店 %d；路线覆盖 升级 %d / 商店 %d；路线分数 %s；主动标签 `%s`。" % [
		str(scenario.get("title", "")),
		"通过" if passed else "失败",
		_format_top_titles(_top_weight_rows(upgrade_rows, 5)),
		_format_top_titles(_top_weight_rows(shop_rows, 5)),
		int(audit.get("upgrade_group_clear_count", 0)),
		int(audit.get("shop_group_clear_count", 0)),
		int(audit.get("upgrade_route_count", 0)),
		int(audit.get("shop_route_count", 0)),
		_format_route_scores(_get_active_build_route_scores()),
		"`, `".join(_get_active_skill_tags().keys())
	]

func _append_scenario_detail(lines: Array[String], scenario: Dictionary) -> void:
	var class_data: Dictionary = scenario.get("class_data", {})
	var upgrade_rows := _build_upgrade_weights(false)
	var shop_rows := _build_upgrade_weights(true)
	var audit := _evaluate_offer_health(upgrade_rows, shop_rows)
	lines.append("### %s" % str(scenario.get("title", "")))
	lines.append("")
	lines.append("- 玩家可见效果：%s" % "；".join(class_data.get("effects", [])))
	lines.append("- 玩家可见清群入口：%s" % str(class_data.get("clear_summary", "")))
	lines.append("- 审计结果：%s，清群候选 升级 %d / 商店 %d，路线覆盖 升级 %d / 商店 %d" % [
		"通过" if bool(audit.get("passed", false)) else "失败",
		int(audit.get("upgrade_group_clear_count", 0)),
		int(audit.get("shop_group_clear_count", 0)),
		int(audit.get("upgrade_route_count", 0)),
		int(audit.get("shop_route_count", 0))
	])
	lines.append("- 路线分数：%s" % _format_route_scores(_get_active_build_route_scores()))
	lines.append("- 主动标签：`%s`" % "`, `".join(_get_active_skill_tags().keys()))
	lines.append("")
	lines.append("升级权重前 %d：" % TOP_COUNT)
	lines.append("")
	lines.append("| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 | 清群 |")
	lines.append("|---|---:|---|---|---|---|---|")
	for row in _top_weight_rows(upgrade_rows, TOP_COUNT):
		lines.append(_format_weight_row(row))
	lines.append("")
	lines.append("商店权重前 %d：" % TOP_COUNT)
	lines.append("")
	lines.append("| 技能 | 权重 | 稀有度 | 路线 | 标签命中 | 冲突命中 | 清群 |")
	lines.append("|---|---:|---|---|---|---|---|")
	for row in _top_weight_rows(shop_rows, TOP_COUNT):
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
			"conflict_matches": _get_conflict_tag_matches(upgrade_id),
			"group_clear": GROUP_CLEAR_UPGRADE_IDS.has(upgrade_id)
		})
	return rows

func _evaluate_offer_health(upgrade_rows: Array[Dictionary], shop_rows: Array[Dictionary]) -> Dictionary:
	var upgrade_top := _top_weight_rows(upgrade_rows, DIVERSITY_TOP_COUNT)
	var shop_top := _top_weight_rows(shop_rows, DIVERSITY_TOP_COUNT)
	var upgrade_group_clear_count := _count_group_clear_rows(upgrade_top)
	var shop_group_clear_count := _count_group_clear_rows(shop_top)
	var upgrade_route_count := _count_unique_routes(upgrade_top)
	var shop_route_count := _count_unique_routes(shop_top)
	var class_data: Dictionary = current_scenario.get("class_data", {})
	var clear_summary := str(class_data.get("clear_summary", ""))
	var passed := (
		not clear_summary.is_empty()
		and upgrade_group_clear_count >= MIN_GROUP_CLEAR_TOP_COUNT
		and shop_group_clear_count >= MIN_GROUP_CLEAR_TOP_COUNT
		and upgrade_route_count >= MIN_ROUTE_VARIETY
		and shop_route_count >= MIN_ROUTE_VARIETY
	)
	return {
		"passed": passed,
		"upgrade_group_clear_count": upgrade_group_clear_count,
		"shop_group_clear_count": shop_group_clear_count,
		"upgrade_route_count": upgrade_route_count,
		"shop_route_count": shop_route_count
	}

func _count_group_clear_rows(rows: Array[Dictionary]) -> int:
	var count := 0
	for row in rows:
		if bool(row.get("group_clear", false)):
			count += 1
	return count

func _count_unique_routes(rows: Array[Dictionary]) -> int:
	var route_ids := {}
	for row in rows:
		for route_id in row.get("routes", []):
			route_ids[str(route_id)] = true
	return route_ids.size()

func _apply_skill_momentum_weight(base_weight: int, upgrade_id: String) -> int:
	var weighted_base := base_weight
	if _get_upgrade_stack_count(upgrade_id) > 0 and not SkillCatalog.get_upgrade_tag_list(upgrade_id, "engine_tags").is_empty():
		weighted_base = maxi(weighted_base, SkillCatalog.SKILL_ENGINE_REPEAT_BASE_WEIGHT)
	var weighted := _apply_repeat_skill_weight(weighted_base, upgrade_id)
	weighted = _apply_synergy_skill_weight(weighted, upgrade_id)
	weighted = _apply_tag_skill_weight(weighted, upgrade_id)
	return weighted

func _apply_repeat_skill_weight(base_weight: int, upgrade_id: String) -> int:
	var current_stack := _get_upgrade_stack_count(upgrade_id)
	if current_stack <= 0:
		return maxi(1, base_weight)
	var multiplier := minf(SkillCatalog.SKILL_REPEAT_WEIGHT_CAP, 1.0 + float(current_stack) * SkillCatalog.SKILL_REPEAT_WEIGHT_PER_STACK)
	return maxi(1, int(round(float(base_weight) * multiplier)))

func _apply_synergy_skill_weight(base_weight: int, upgrade_id: String) -> int:
	var source_stack_total := 0
	for source_id in SkillCatalog.get_upgrade_synergy_sources(upgrade_id):
		source_stack_total += _get_upgrade_stack_count(str(source_id))
	if source_stack_total <= 0:
		return maxi(1, base_weight)
	var multiplier := minf(SkillCatalog.SKILL_SYNERGY_WEIGHT_CAP, 1.0 + float(source_stack_total) * SkillCatalog.SKILL_SYNERGY_WEIGHT_PER_SOURCE_STACK)
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
		weighted *= minf(SkillCatalog.SKILL_TAG_SOURCE_WEIGHT_CAP, 1.0 + float(source_matches) * SkillCatalog.SKILL_TAG_SOURCE_WEIGHT_PER_MATCH)
	for route_id in SkillCatalog.get_upgrade_route_tags(upgrade_id):
		var route_score := int(route_scores.get(str(route_id), 0))
		if route_score > 0:
			weighted *= minf(SkillCatalog.SKILL_TAG_ROUTE_WEIGHT_CAP, 1.0 + float(route_score) * SkillCatalog.SKILL_TAG_ROUTE_WEIGHT_PER_STACK)
	var engine_tags := SkillCatalog.get_upgrade_tag_list(upgrade_id, "engine_tags")
	if not engine_tags.is_empty() and _get_upgrade_stack_count(upgrade_id) <= 0 and source_matches > 0:
		weighted *= SkillCatalog.SKILL_ENGINE_FIRST_PICK_WEIGHT
	for tag in SkillCatalog.get_upgrade_tag_list(upgrade_id, "conflict_tags"):
		if active_tags.has(str(tag)):
			weighted *= SkillCatalog.SKILL_TAG_CONFLICT_WEIGHT
	weighted = _apply_class_skill_weight(weighted, upgrade_id)
	return maxi(1, int(round(weighted)))

func _apply_class_skill_weight(base_weight: float, upgrade_id: String) -> float:
	var class_data: Dictionary = current_scenario.get("class_data", {})
	if class_data.is_empty() or upgrade_id.is_empty():
		return base_weight
	var weighted := base_weight
	var upgrade_bias: Dictionary = class_data.get("upgrade_bias", {})
	if upgrade_bias.has(upgrade_id):
		weighted *= clampf(float(upgrade_bias.get(upgrade_id, 1.0)), 0.50, 2.00)
	var route_bias: Dictionary = class_data.get("route_bias", {})
	for route_id in SkillCatalog.get_upgrade_route_tags(upgrade_id):
		var bias := int(route_bias.get(str(route_id), 0))
		if bias > 0:
			weighted *= minf(1.60, 1.0 + float(bias) * 0.16)
	var tag_bias: Array = class_data.get("tag_bias", [])
	for tag_key in ["effect_tags", "source_tags", "engine_tags"]:
		for tag in SkillCatalog.get_upgrade_tag_list(upgrade_id, tag_key):
			if tag_bias.has(str(tag)):
				weighted *= 1.18
	return weighted

func _get_active_skill_tags() -> Dictionary:
	var active_tags := {}
	var summary: Dictionary = current_scenario.get("summary", {})
	var class_data: Dictionary = current_scenario.get("class_data", {})
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
	if int(summary.get("movement_focus_tier", 0)) > 0:
		active_tags["moving"] = true
	if int(summary.get("stationary_focus_tier", 0)) > 0:
		active_tags["stationary"] = true
	for tag in class_data.get("tag_bias", []):
		active_tags[str(tag)] = true
	return active_tags

func _get_active_build_route_scores() -> Dictionary:
	var route_scores := {}
	var summary: Dictionary = current_scenario.get("summary", {})
	var class_data: Dictionary = current_scenario.get("class_data", {})
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		route_scores[route_id] = 0
	var upgrade_stacks: Dictionary = summary.get("upgrade_stacks", {})
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		var score := 0
		for upgrade_id in SkillCatalog.get_route_signature_upgrades(route_id):
			score += int(upgrade_stacks.get(str(upgrade_id), 0))
		route_scores[route_id] = score
	var route_bias: Dictionary = class_data.get("route_bias", {})
	for route_id in route_bias.keys():
		route_scores[str(route_id)] = int(route_scores.get(str(route_id), 0)) + int(route_bias.get(route_id, 0))
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
	return "| %s | %d | %s | %s | %s | %s | %s |" % [
		str(row.get("title", "")),
		int(row.get("weight", 0)),
		str(row.get("rarity", "")),
		", ".join(row.get("routes", [])),
		", ".join(row.get("source_matches", [])),
		", ".join(row.get("conflict_matches", [])),
		"是" if bool(row.get("group_clear", false)) else "否"
	]

func _format_top_titles(rows: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for row in rows:
		parts.append("%s(%d)" % [str(row.get("title", "")), int(row.get("weight", 0))])
	return "、".join(parts)

func _format_route_scores(route_scores: Dictionary) -> String:
	var parts: Array[String] = []
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		parts.append("%s %d" % [str(route_id), int(route_scores.get(route_id, 0))])
	return " / ".join(parts)
