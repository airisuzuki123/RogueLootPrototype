extends SceneTree

const SkillCatalog := preload("res://scripts/items/skill_catalog.gd")
const CharacterClassCatalog := preload("res://scripts/items/character_class_catalog.gd")

const REPORT_PATH := "res://docs/class-progression-audit.md"
const TOP_COUNT := 8
const FIRST_PICK_BRANCHES := 3
const MIN_ROUTE_VARIETY := 3
const MIN_GROUP_CLEAR_COUNT := 2
const MAX_TOP_WEIGHT_SHARE := 0.30
const MIN_OPENING_CLEAR_PROBABILITY := 0.55
var current_scenario: Dictionary = {}

func _initialize() -> void:
	var report := _build_report()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法写入职业连续选择审计报告：%s" % REPORT_PATH)
		quit(1)
		return
	file.store_string(report)
	file.close()
	print("已生成职业连续选择审计报告：%s" % REPORT_PATH)
	quit()

func _build_report() -> String:
	var lines: Array[String] = []
	lines.append("# 阶段 5.5 职业连续选择审计报告")
	lines.append("")
	lines.append("本报告模拟每个职业开局后最可能出现的前三个首选方向，并继续计算第二次选择后的候选集中度。它用于发现前两关出货是否快速塌缩，不代表玩家必然拿到对应技能。")
	lines.append("")
	lines.append("## 审计口径")
	lines.append("")
	lines.append("- 使用与 GameManager 相同的稀有度、重复、协同、标签、冲突和职业权重公式。")
	lines.append("- 对开局权重最高的 %d 个首选分别建立分支，再选择该分支下权重最高的第二张技能。" % FIRST_PICK_BRANCHES)
	lines.append("- 只把 `%s` 计为正式构筑路线；辅助标签不计入路线覆盖。" % "`, `".join(SkillCatalog.BUILD_ROUTE_ORDER))
	lines.append("- 前 %d 名中至少保留 %d 个清群入口、覆盖 %d 条正式路线；第一名权重占前 %d 名总权重超过 %d%% 时记为集中度警告。" % [TOP_COUNT, MIN_GROUP_CLEAR_COUNT, MIN_ROUTE_VARIETY, TOP_COUNT, int(MAX_TOP_WEIGHT_SHARE * 100.0)])
	lines.append("- 开局三选一的前两个路线槽至少出现一张清群技能的估算概率不得低于 %d%%。" % int(MIN_OPENING_CLEAR_PROBABILITY * 100.0))
	lines.append("")
	lines.append("## 结论摘要")
	lines.append("")
	var class_results: Array[Dictionary] = []
	for class_data in CharacterClassCatalog.get_class_list():
		var result := _audit_class(class_data)
		class_results.append(result)
		lines.append("- %s：%s；开局 %s；风险分支 %d/%d；最高集中度 %d%%。" % [
			str(result.get("name", "")),
			"通过" if bool(result.get("passed", false)) else "需关注",
			"%s；开局清群概率至少 %d%%" % [_format_health(result.get("initial_health", {})), int(round(float(result.get("opening_clear_probability", 0.0)) * 100.0))],
			int(result.get("warning_count", 0)),
			int(result.get("branches", []).size()),
			int(round(float(result.get("max_top_share", 0.0)) * 100.0))
		])
	lines.append("")
	lines.append("## 职业明细")
	lines.append("")
	for result in class_results:
		lines.append("### %s" % str(result.get("name", "")))
		lines.append("")
		lines.append("- 开局候选：%s" % _format_top_titles(result.get("initial_rows", []), 5))
		lines.append("- 开局健康度：%s" % _format_health(result.get("initial_health", {})))
		lines.append("- 开局路线槽位：%s；前两个槽位至少出现一张清群技能的估算概率为 %d%%" % [
			str(result.get("opening_route_text", "")),
			int(round(float(result.get("opening_clear_probability", 0.0)) * 100.0))
		])
		lines.append("")
		lines.append("| 首选分支 | 第二次首选 | 第二次选择前候选 | 两次选择后健康度 | 判断 |")
		lines.append("|---|---|---|---|---|")
		for branch in result.get("branches", []):
			lines.append("| %s | %s | %s | %s | %s |" % [
				str(branch.get("first_title", "")),
				str(branch.get("second_title", "")),
				_format_top_titles(branch.get("after_first_rows", []), 4),
				_format_health(branch.get("after_second_health", {})),
				"通过" if bool(branch.get("passed", false)) else "需关注"
			])
		lines.append("")
		var warnings: Array = result.get("warnings", [])
		var opening_probability := float(result.get("opening_clear_probability", 0.0))
		if warnings.is_empty() and opening_probability >= MIN_OPENING_CLEAR_PROBABILITY:
			lines.append("结论：前三个首选分支在两次选择后仍保留足够清群入口与路线宽度。")
		else:
			var risk_parts: Array[String] = []
			if opening_probability < MIN_OPENING_CLEAR_PROBABILITY:
				risk_parts.append("开局清群概率 %d%% 低于下限" % int(round(opening_probability * 100.0)))
			risk_parts.append_array(warnings)
			lines.append("风险：%s。" % "；".join(risk_parts))
		lines.append("")
	while not lines.is_empty() and str(lines[-1]).is_empty():
		lines.pop_back()
	return "\n".join(lines) + "\n"

func _audit_class(class_data: Dictionary) -> Dictionary:
	var base_scenario := _build_scenario(class_data)
	current_scenario = base_scenario
	var all_initial_rows := _build_upgrade_weights()
	var initial_rows := _top_weight_rows(all_initial_rows, TOP_COUNT)
	var initial_health := _evaluate_rows(initial_rows)
	var opening_audit := _evaluate_opening_route_slots(all_initial_rows)
	var opening_clear_probability := float(opening_audit.get("clear_probability", 0.0))
	var first_pick_rows := initial_rows.slice(0, mini(FIRST_PICK_BRANCHES, initial_rows.size()))
	var branches: Array[Dictionary] = []
	var warnings: Array[String] = []
	var max_top_share := float(initial_health.get("top_share", 0.0))
	for first_pick in first_pick_rows:
		var after_first := base_scenario.duplicate(true)
		_apply_choice(after_first, str(first_pick.get("id", "")))
		current_scenario = after_first
		var after_first_rows := _top_weight_rows(_build_upgrade_weights(), TOP_COUNT)
		var second_pick: Dictionary = after_first_rows[0] if not after_first_rows.is_empty() else {}
		var after_second := after_first.duplicate(true)
		_apply_choice(after_second, str(second_pick.get("id", "")))
		current_scenario = after_second
		var after_second_rows := _top_weight_rows(_build_upgrade_weights(), TOP_COUNT)
		var after_second_health := _evaluate_rows(after_second_rows)
		max_top_share = maxf(max_top_share, float(after_second_health.get("top_share", 0.0)))
		var passed := _health_passed(after_second_health)
		if not passed:
			warnings.append("首选%s后走向%s，%s" % [
				str(first_pick.get("title", "")),
				str(second_pick.get("title", "")),
				_format_health(after_second_health)
			])
		branches.append({
			"first_title": str(first_pick.get("title", "")),
			"second_title": str(second_pick.get("title", "")),
			"after_first_rows": after_first_rows,
			"after_second_health": after_second_health,
			"passed": passed
		})
	return {
		"name": str(class_data.get("name", "")),
		"passed": warnings.is_empty() and opening_clear_probability >= MIN_OPENING_CLEAR_PROBABILITY,
		"initial_rows": initial_rows,
		"initial_health": initial_health,
		"branches": branches,
		"warnings": warnings,
		"warning_count": warnings.size(),
		"max_top_share": max_top_share,
		"opening_clear_probability": opening_clear_probability,
		"opening_route_text": str(opening_audit.get("route_text", ""))
	}

func _evaluate_opening_route_slots(rows: Array[Dictionary]) -> Dictionary:
	var primary_route := _get_primary_route()
	var branch_routes := _get_possible_branch_routes(primary_route)
	var primary_clear_share := _get_route_clear_weight_share(rows, primary_route)
	var minimum_probability := 1.0
	if branch_routes.is_empty():
		minimum_probability = primary_clear_share
	for branch_route in branch_routes:
		var branch_clear_share := _get_route_clear_weight_share(rows, branch_route)
		var probability := 1.0 - (1.0 - primary_clear_share) * (1.0 - branch_clear_share)
		minimum_probability = minf(minimum_probability, probability)
	return {
		"clear_probability": clampf(minimum_probability, 0.0, 1.0),
		"route_text": "%s + %s" % [primary_route, "/".join(branch_routes)]
	}

func _get_primary_route() -> String:
	var scores := _get_active_build_route_scores()
	var best_route := ""
	var best_score := 0
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		var score := int(scores.get(route_id, 0))
		if score > best_score:
			best_score = score
			best_route = route_id
	return best_route

func _get_possible_branch_routes(primary_route: String) -> Array[String]:
	var scores := _get_active_build_route_scores()
	var candidates: Array[String] = []
	var best_score := -1
	for route_value in SkillCatalog.get_route_synergy_ids(primary_route):
		var route_id := str(route_value)
		if route_id == primary_route or not SkillCatalog.BUILD_ROUTE_DEFINITIONS.has(route_id):
			continue
		var score := int(scores.get(route_id, 0))
		if score > best_score:
			best_score = score
			candidates.clear()
		if score == best_score:
			candidates.append(route_id)
	return candidates

func _get_route_clear_weight_share(rows: Array[Dictionary], route_id: String) -> float:
	if route_id.is_empty():
		return 0.0
	var route_upgrade_ids: Array = SkillCatalog.BUILD_ROUTE_DEFINITIONS.get(route_id, {}).get("upgrades", [])
	var total_weight := 0
	var clear_weight := 0
	for row in rows:
		if not route_upgrade_ids.has(str(row.get("id", ""))):
			continue
		var weight := int(row.get("weight", 0))
		if bool(row.get("group_clear", false)):
			weight = maxi(1, int(round(float(weight) * SkillCatalog.OPENING_GROUP_CLEAR_WEIGHT)))
		total_weight += weight
		if bool(row.get("group_clear", false)):
			clear_weight += weight
	return float(clear_weight) / float(total_weight) if total_weight > 0 else 0.0

func _build_scenario(class_data: Dictionary) -> Dictionary:
	var initial_stats: Dictionary = class_data.get("initial_stats", {})
	return {
		"class_data": class_data.duplicate(true),
		"summary": {
			"move_speed": 260.0 * float(initial_stats.get("move_speed_multiplier", 1.0)),
			"player_size_bonus": float(initial_stats.get("player_size_bonus", 0.0)),
			"attack_interval": 0.45 * float(initial_stats.get("fire_interval_multiplier", 1.0)),
			"projectiles": 1,
			"pierce": 0,
			"explosion_radius": float(initial_stats.get("explosion_radius", 0.0)),
			"shield": int(initial_stats.get("shield", 0)),
			"max_health": 100,
			"health": 100,
			"upgrade_stacks": {}
		}
	}

func _apply_choice(scenario: Dictionary, upgrade_id: String) -> void:
	if upgrade_id.is_empty():
		return
	var summary: Dictionary = scenario.get("summary", {})
	var stacks: Dictionary = summary.get("upgrade_stacks", {})
	stacks[upgrade_id] = int(stacks.get(upgrade_id, 0)) + 1
	summary["upgrade_stacks"] = stacks
	match upgrade_id:
		"damage":
			summary["attack_interval"] = float(summary.get("attack_interval", 0.45)) * 1.10
		"attack_speed":
			summary["attack_interval"] = float(summary.get("attack_interval", 0.45)) * 0.75
		"move_speed":
			summary["move_speed"] = float(summary.get("move_speed", 260.0)) + _scale_gain(scenario, "move_speed", 70.0)
			summary["player_size_bonus"] = float(summary.get("player_size_bonus", 0.0)) + _scale_gain(scenario, "player_size_bonus", 0.05)
		"max_health":
			summary["max_health"] = int(summary.get("max_health", 100)) + int(round(_scale_gain(scenario, "max_health", 30.0)))
			summary["move_speed"] = maxf(80.0, float(summary.get("move_speed", 260.0)) * 0.95)
		"recovery_training":
			summary["max_health"] = int(summary.get("max_health", 100)) + int(round(_scale_gain(scenario, "max_health", 25.0)))
			summary["move_speed"] = maxf(80.0, float(summary.get("move_speed", 260.0)) * 0.95)
		"multishot":
			summary["projectiles"] = int(summary.get("projectiles", 1)) + maxi(1, int(round(_scale_gain(scenario, "projectile_count", 1.0))))
			summary["player_size_bonus"] = float(summary.get("player_size_bonus", 0.0)) + _scale_gain(scenario, "player_size_bonus", 0.30)
			summary["move_speed"] = maxf(80.0, float(summary.get("move_speed", 260.0)) * 0.80)
		"light_frame":
			summary["player_size_bonus"] = maxf(-0.40, float(summary.get("player_size_bonus", 0.0)) - _scale_gain(scenario, "player_size_reduction", 0.12))
			summary["move_speed"] = float(summary.get("move_speed", 260.0)) + _scale_gain(scenario, "move_speed", 70.0)
		"piercing_rounds", "pierce_amp":
			summary["pierce"] = int(summary.get("pierce", 0)) + maxi(1, int(round(_scale_gain(scenario, "pierce", 1.0))))
		"blast_core":
			summary["explosion_radius"] = float(summary.get("explosion_radius", 0.0)) + _scale_gain(scenario, "explosion_radius", 40.0)
			summary["player_size_bonus"] = float(summary.get("player_size_bonus", 0.0)) + _scale_gain(scenario, "player_size_bonus", 0.20)
			summary["attack_interval"] = float(summary.get("attack_interval", 0.45)) * 1.15
		"graze_barrier":
			summary["shield"] = int(round(_scale_gain(scenario, "shield", 22.0)))
		"clear_barrier":
			summary["shield"] = int(round(_scale_gain(scenario, "shield", 16.0)))
		"homing_shards":
			summary["move_speed"] = maxf(80.0, float(summary.get("move_speed", 260.0)) * 0.88)
		"heavy_shot":
			summary["player_size_bonus"] = float(summary.get("player_size_bonus", 0.0)) + _scale_gain(scenario, "player_size_bonus", 0.15)
			summary["attack_interval"] = float(summary.get("attack_interval", 0.45)) * 1.10
		"channel_beam":
			summary["move_speed"] = maxf(80.0, float(summary.get("move_speed", 260.0)) * 0.90)
		"shatter_blast":
			summary["explosion_radius"] = float(summary.get("explosion_radius", 0.0)) + _scale_gain(scenario, "explosion_radius", 16.0)
		"reflow_shards":
			summary["attack_interval"] = float(summary.get("attack_interval", 0.45)) * 0.90
		"compressed_core":
			summary["projectiles"] = maxi(1, int(summary.get("projectiles", 1)) - 1)
			summary["attack_interval"] = float(summary.get("attack_interval", 0.45)) * 1.15
		"guard_blade":
			summary["shield"] = int(round(_scale_gain(scenario, "shield", 20.0)))
		"giant_echo":
			summary["shield"] = int(round(_scale_gain(scenario, "shield", 18.0)))
		"blood_pact":
			summary["health"] = maxi(1, int(summary.get("health", 100)) - 22)
		"crimson_leech":
			summary["health"] = maxi(1, int(summary.get("health", 100)) - 15)
	scenario["summary"] = summary

func _scale_gain(scenario: Dictionary, key: String, base_value: float) -> float:
	var class_data: Dictionary = scenario.get("class_data", {})
	var gains: Dictionary = class_data.get("gain_multipliers", {})
	return base_value * maxf(0.0, float(gains.get(key, 1.0)))

func _build_upgrade_weights() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for upgrade in SkillCatalog.get_upgrade_pool():
		var upgrade_id := str(upgrade.get("id", ""))
		if upgrade_id in ["heal", "strong_heal"]:
			continue
		var base_weight := SkillCatalog.get_skill_rarity_weight(SkillCatalog.get_upgrade_rarity(upgrade_id))
		rows.append({
			"id": upgrade_id,
			"title": SkillCatalog.get_upgrade_title(upgrade_id, upgrade_id),
			"weight": _apply_skill_momentum_weight(base_weight, upgrade_id),
			"routes": SkillCatalog.get_upgrade_route_tags(upgrade_id),
			"group_clear": SkillCatalog.is_group_clear_upgrade(upgrade_id)
		})
	return rows

func _apply_skill_momentum_weight(base_weight: int, upgrade_id: String) -> int:
	var weighted_base := base_weight
	if _get_upgrade_stack_count(upgrade_id) > 0 and not SkillCatalog.get_upgrade_tag_list(upgrade_id, "engine_tags").is_empty():
		weighted_base = maxi(weighted_base, SkillCatalog.SKILL_ENGINE_REPEAT_BASE_WEIGHT)
	var current_stack := _get_upgrade_stack_count(upgrade_id)
	var weighted := maxi(1, weighted_base)
	if current_stack > 0:
		var repeat_multiplier := minf(SkillCatalog.SKILL_REPEAT_WEIGHT_CAP, 1.0 + float(current_stack) * SkillCatalog.SKILL_REPEAT_WEIGHT_PER_STACK)
		weighted = maxi(1, int(round(float(weighted) * repeat_multiplier)))
	var source_stack_total := 0
	for source_id in SkillCatalog.get_upgrade_synergy_sources(upgrade_id):
		source_stack_total += _get_upgrade_stack_count(str(source_id))
	if source_stack_total > 0:
		var synergy_multiplier := minf(SkillCatalog.SKILL_SYNERGY_WEIGHT_CAP, 1.0 + float(source_stack_total) * SkillCatalog.SKILL_SYNERGY_WEIGHT_PER_SOURCE_STACK)
		weighted = maxi(1, int(round(float(weighted) * synergy_multiplier)))
	return _apply_tag_skill_weight(weighted, upgrade_id)

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
	return maxi(1, int(round(_apply_class_skill_weight(weighted, upgrade_id))))

func _apply_class_skill_weight(base_weight: float, upgrade_id: String) -> float:
	var class_data: Dictionary = current_scenario.get("class_data", {})
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
	var stacks: Dictionary = summary.get("upgrade_stacks", {})
	for upgrade_id in stacks.keys():
		if int(stacks.get(upgrade_id, 0)) <= 0:
			continue
		for tag_key in ["effect_tags", "engine_tags"]:
			for tag in SkillCatalog.get_upgrade_tag_list(str(upgrade_id), tag_key):
				active_tags[str(tag)] = true
	var player_size_bonus := float(summary.get("player_size_bonus", 0.0))
	if player_size_bonus >= 0.20:
		active_tags["large_body"] = true
	elif player_size_bonus <= -0.10:
		active_tags["small_body"] = true
	var move_speed := float(summary.get("move_speed", 260.0))
	if move_speed >= 315.0:
		active_tags["fast_move"] = true
	elif move_speed <= 220.0:
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
	if float(summary.get("explosion_radius", 0.0)) >= 40.0:
		active_tags["blast"] = true
	if int(summary.get("shield", 0)) > 0:
		active_tags["shielded"] = true
	var max_health := int(summary.get("max_health", 100))
	var health := int(summary.get("health", 100))
	if max_health > 0 and health <= int(round(float(max_health) * 0.40)):
		active_tags["low_life"] = true
	if max_health >= 130:
		active_tags["high_health"] = true
	var class_data: Dictionary = current_scenario.get("class_data", {})
	for tag in class_data.get("tag_bias", []):
		active_tags[str(tag)] = true
	return active_tags

func _get_active_build_route_scores() -> Dictionary:
	var scores := {}
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		scores[route_id] = 0
	var summary: Dictionary = current_scenario.get("summary", {})
	var stacks: Dictionary = summary.get("upgrade_stacks", {})
	for route_id in SkillCatalog.BUILD_ROUTE_ORDER:
		for upgrade_id in SkillCatalog.get_route_signature_upgrades(route_id):
			scores[route_id] = int(scores.get(route_id, 0)) + int(stacks.get(str(upgrade_id), 0))
	var class_data: Dictionary = current_scenario.get("class_data", {})
	var route_bias: Dictionary = class_data.get("route_bias", {})
	for route_id in route_bias.keys():
		scores[str(route_id)] = int(scores.get(str(route_id), 0)) + int(route_bias.get(route_id, 0))
	if float(summary.get("move_speed", 0.0)) > 300.0:
		scores["agile"] = int(scores.get("agile", 0)) + 1
	if float(summary.get("player_size_bonus", 0.0)) < 0.0:
		scores["agile"] = int(scores.get("agile", 0)) + 1
	return scores

func _get_upgrade_stack_count(upgrade_id: String) -> int:
	var summary: Dictionary = current_scenario.get("summary", {})
	var stacks: Dictionary = summary.get("upgrade_stacks", {})
	return int(stacks.get(upgrade_id, 0))

func _top_weight_rows(rows: Array[Dictionary], count: int) -> Array[Dictionary]:
	var sorted := rows.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("weight", 0)) == int(b.get("weight", 0)):
			return str(a.get("id", "")) < str(b.get("id", ""))
		return int(a.get("weight", 0)) > int(b.get("weight", 0))
	)
	return sorted.slice(0, mini(count, sorted.size()))

func _evaluate_rows(rows: Array[Dictionary]) -> Dictionary:
	var route_ids := {}
	var group_clear_count := 0
	var total_weight := 0
	for row in rows:
		total_weight += int(row.get("weight", 0))
		if bool(row.get("group_clear", false)):
			group_clear_count += 1
		for route_id in row.get("routes", []):
			var normalized_route_id := str(route_id)
			if SkillCatalog.BUILD_ROUTE_ORDER.has(normalized_route_id):
				route_ids[normalized_route_id] = true
	var top_weight := int(rows[0].get("weight", 0)) if not rows.is_empty() else 0
	return {
		"group_clear_count": group_clear_count,
		"route_count": route_ids.size(),
		"top_share": float(top_weight) / float(total_weight) if total_weight > 0 else 0.0
	}

func _health_passed(health: Dictionary) -> bool:
	return (
		int(health.get("group_clear_count", 0)) >= MIN_GROUP_CLEAR_COUNT
		and int(health.get("route_count", 0)) >= MIN_ROUTE_VARIETY
		and float(health.get("top_share", 0.0)) <= MAX_TOP_WEIGHT_SHARE
	)

func _format_health(health: Dictionary) -> String:
	return "清群 %d / 路线 %d / 首位占比 %d%%" % [
		int(health.get("group_clear_count", 0)),
		int(health.get("route_count", 0)),
		int(round(float(health.get("top_share", 0.0)) * 100.0))
	]

func _format_top_titles(rows: Array, count: int) -> String:
	var parts: Array[String] = []
	for row in rows.slice(0, mini(count, rows.size())):
		parts.append("%s(%d)" % [str(row.get("title", "")), int(row.get("weight", 0))])
	return "、".join(parts)
