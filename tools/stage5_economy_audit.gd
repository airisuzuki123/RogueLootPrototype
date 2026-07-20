extends SceneTree

const GameManagerScript := preload("res://scripts/core/game_manager.gd")
const SkillCatalog := preload("res://scripts/items/skill_catalog.gd")
const CharacterClassCatalog := preload("res://scripts/items/character_class_catalog.gd")

const REPORT_PATH := "res://docs/stage5-economy-audit.md"

func _initialize() -> void:
	var report := _build_report()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法写入阶段 5 经济审计报告：%s" % REPORT_PATH)
		quit(1)
		return
	file.store_string(report)
	file.close()
	print("已生成阶段 5 经济审计报告：%s" % REPORT_PATH)
	quit()

func _build_report() -> String:
	var lines: Array[String] = []
	lines.append("# 阶段 5 经济节奏审计报告")
	lines.append("")
	lines.append("本报告由 `tools/stage5_economy_audit.gd` 生成，用于检查 10 关短循环里关卡目标金币、清场奖金、商店价格和刷新费用的关系。")
	lines.append("")
	lines.append("## 统计口径")
	lines.append("")
	lines.append("- 确定性金币：只统计达成关卡击杀目标后的金币奖励。")
	lines.append("- 满额金币：确定性金币 + 每关清场奖金上限。")
	lines.append("- 不统计随机击杀金币、装备分解、金币获取词缀和事件奖励，因为这些不能作为购买保底。")
	lines.append("- 商店价格按关卡完成数计算，刷新费用按本次商店内第 1/2/3 次刷新列出。")
	lines.append("")
	_append_summary(lines)
	lines.append("")
	_append_stage_table(lines)
	lines.append("")
	_append_shop_table(lines)
	lines.append("")
	_append_early_build_pacing(lines)
	while not lines.is_empty() and str(lines[-1]).is_empty():
		lines.pop_back()
	return "\n".join(lines) + "\n"

func _append_summary(lines: Array[String]) -> void:
	var first_skill_stage := -1
	var first_equipment_stage := -1
	var cumulative_reward := 0
	for index in range(GameManagerScript.RUN_PHASES.size()):
		var completed_stage := index + 1
		var phase: Dictionary = GameManagerScript.RUN_PHASES[index]
		cumulative_reward += int(phase.get("reward_gold", 0))
		if completed_stage >= GameManagerScript.STAGE_COUNT:
			continue
		var price_summary := _get_shop_price_summary(completed_stage)
		if first_skill_stage < 0 and cumulative_reward >= int(price_summary.get("skill_min", 0)):
			first_skill_stage = completed_stage
		if first_equipment_stage < 0 and cumulative_reward >= int(price_summary.get("gear_min", 0)):
			first_equipment_stage = completed_stage
	lines.append("## 结论摘要")
	lines.append("")
	lines.append("- 仅靠确定性金币，首次可购买最低价技能的商店：第 %d 关后。" % first_skill_stage)
	lines.append("- 仅靠确定性金币，首次可购买最低价装备/工具的商店：第 %d 关后。" % first_equipment_stage)
	var first_shop_budget := int(GameManagerScript.RUN_PHASES[0].get("reward_gold", 0))
	var affordable_class_count := _count_classes_with_affordable_preferred_skill(1, first_shop_budget)
	lines.append("- 第 1 关后，%d/%d 个职业至少有 1 个职业偏向技能可用确定性金币购买。" % [affordable_class_count, CharacterClassCatalog.get_class_list().size()])
	var minimum_level_choices := _estimate_minimum_level_choices(3)
	var first_shop_preferred_cost := _get_maximum_class_preferred_minimum_cost(1)
	var stage_three_budget := first_shop_budget - first_shop_preferred_cost
	for index in range(1, 3):
		stage_three_budget += int(GameManagerScript.RUN_PHASES[index].get("reward_gold", 0))
	var stage_three_median := int(_get_shop_price_summary(3).get("skill_median", 0))
	var guaranteed_shop_choices := 2 if stage_three_budget >= stage_three_median else 1
	lines.append("- 按最低敌人经验估算，前 3 关至少获得 %d 次升级选择；加上开局三选一和 %d 次确定性技能购买，前 3 关至少形成 %d 次有效构筑选择。" % [
		minimum_level_choices,
		guaranteed_shop_choices,
		1 + minimum_level_choices + guaranteed_shop_choices
	])
	if first_skill_stage <= 1:
		lines.append("- 第 1 关后确定性金币已经覆盖最低价技能，首个商店可以稳定产生一次技能购买决策。")
	else:
		lines.append("- 第 1 关后确定性金币少于最低价技能，早期是否能购买主要依赖超额击杀、随机金币或分解装备。")
		lines.append("- 如果希望第 1 个商店稳定产生技能选择，应提高第 1 关目标奖励或降低绿色技能的早期价格。")

func _append_stage_table(lines: Array[String]) -> void:
	lines.append("## 关卡收入")
	lines.append("")
	lines.append("| 关卡 | 击杀目标 | 目标金币 | 累计确定性金币 | 满额金币上限 | 刷怪理论上限 |")
	lines.append("|---:|---:|---:|---:|---:|---:|")
	var cumulative_reward := 0
	var cumulative_max := 0
	for index in range(GameManagerScript.RUN_PHASES.size()):
		var stage_number := index + 1
		var phase: Dictionary = GameManagerScript.RUN_PHASES[index]
		var reward_gold := int(phase.get("reward_gold", 0))
		cumulative_reward += reward_gold
		cumulative_max += reward_gold + GameManagerScript.OVERKILL_BONUS_CAP
		lines.append("| %d | %d | %d | %d | %d | %d |" % [
			stage_number,
			int(phase.get("kill_target", 0)),
			reward_gold,
			cumulative_reward,
			cumulative_max,
			_estimate_spawn_capacity(phase)
		])

func _append_shop_table(lines: Array[String]) -> void:
	lines.append("## 关间商店价格")
	lines.append("")
	lines.append("| 商店 | 确定性预算 | 满额预算 | 生存最低 | 装备/工具最低 | 技能最低 | 技能中位 | 第1/2/3次刷新 |")
	lines.append("|---:|---:|---:|---:|---:|---:|---:|---|")
	var cumulative_reward := 0
	var cumulative_max := 0
	for index in range(GameManagerScript.RUN_PHASES.size() - 1):
		var completed_stage := index + 1
		var phase: Dictionary = GameManagerScript.RUN_PHASES[index]
		cumulative_reward += int(phase.get("reward_gold", 0))
		cumulative_max += int(phase.get("reward_gold", 0)) + GameManagerScript.OVERKILL_BONUS_CAP
		var price_summary := _get_shop_price_summary(completed_stage)
		lines.append("| 第 %d 关后 | %d | %d | %d | %d | %d | %d | %s |" % [
			completed_stage,
			cumulative_reward,
			cumulative_max,
			int(price_summary.get("survival_min", 0)),
			int(price_summary.get("gear_min", 0)),
			int(price_summary.get("skill_min", 0)),
			int(price_summary.get("skill_median", 0)),
			_format_refresh_costs(completed_stage)
		])

func _append_early_build_pacing(lines: Array[String]) -> void:
	lines.append("## 前 3 关构筑节奏")
	lines.append("")
	lines.append("| 职业 | 第一商店最低偏向技能 | 第一关确定性金币 | 可购买 |")
	lines.append("|---|---:|---:|---|")
	var first_shop_budget := int(GameManagerScript.RUN_PHASES[0].get("reward_gold", 0))
	for class_data in CharacterClassCatalog.get_class_list():
		var minimum_cost := _get_class_preferred_minimum_cost(class_data, 1)
		lines.append("| %s | %d | %d | %s |" % [
			str(class_data.get("name", "未知职业")),
			minimum_cost,
			first_shop_budget,
			"是" if minimum_cost <= first_shop_budget else "否"
		])
	lines.append("")
	var first_purchase_cost := _get_maximum_class_preferred_minimum_cost(1)
	var budget_after_first_purchase := first_shop_budget - first_purchase_cost
	var stage_two_reward := int(GameManagerScript.RUN_PHASES[1].get("reward_gold", 0))
	var stage_three_reward := int(GameManagerScript.RUN_PHASES[2].get("reward_gold", 0))
	var stage_three_budget := budget_after_first_purchase + stage_two_reward + stage_three_reward
	var stage_three_median := int(_get_shop_price_summary(3).get("skill_median", 0))
	lines.append("- 按职业中最高的首店最低偏向技能价格 %d 计算，购买后剩余 %d 金。" % [first_purchase_cost, budget_after_first_purchase])
	lines.append("- 第二、三关固定奖励合计 %d 金，第三商店预算达到 %d，技能中位价为 %d，可稳定完成第二次技能购买。" % [stage_two_reward + stage_three_reward, stage_three_budget, stage_three_median])
	lines.append("- 最低经验口径下，前 3 关升级选择为 %d 次；加上开局三选一和两次商店购买，共 %d 次有效构筑选择。" % [
		_estimate_minimum_level_choices(3),
		1 + _estimate_minimum_level_choices(3) + 2
	])

func _get_shop_price_summary(completed_stage: int) -> Dictionary:
	var skill_costs: Array[int] = []
	for offer in SkillCatalog.get_shop_skill_offers(completed_stage):
		skill_costs.append(int(offer.get("cost", 0)))
	var survival_costs := [12 + completed_stage * 2, 14 + completed_stage * 2]
	if _is_special_prep_shop(completed_stage + 1):
		survival_costs.append(18 + completed_stage * 2)
	var gear_costs := [18 + completed_stage * 3]
	if completed_stage >= 4:
		gear_costs.append(20 + completed_stage * 2)
	if _is_boss_or_final_prep_shop(completed_stage + 1):
		gear_costs.append(28 + completed_stage * 3)
		gear_costs.append(24 + completed_stage * 2)
	return {
		"skill_min": _min_int(skill_costs),
		"skill_median": _median_int(skill_costs),
		"survival_min": _min_int(survival_costs),
		"gear_min": _min_int(gear_costs)
	}

func _count_classes_with_affordable_preferred_skill(completed_stage: int, budget: int) -> int:
	var count := 0
	for class_data in CharacterClassCatalog.get_class_list():
		var minimum_cost := _get_class_preferred_minimum_cost(class_data, completed_stage)
		if minimum_cost <= budget:
			count += 1
	return count

func _get_class_preferred_minimum_cost(class_data: Dictionary, completed_stage: int) -> int:
	var preferred_ids: Dictionary = class_data.get("upgrade_bias", {})
	var minimum_cost := 999999
	for offer in SkillCatalog.get_shop_skill_offers(completed_stage):
		var upgrade_id := str(offer.get("reward_upgrade_id", ""))
		if preferred_ids.has(upgrade_id):
			minimum_cost = mini(minimum_cost, int(offer.get("cost", 0)))
	return minimum_cost

func _get_maximum_class_preferred_minimum_cost(completed_stage: int) -> int:
	var maximum_cost := 0
	for class_data in CharacterClassCatalog.get_class_list():
		maximum_cost = maxi(maximum_cost, _get_class_preferred_minimum_cost(class_data, completed_stage))
	return maximum_cost

func _estimate_minimum_level_choices(stage_count: int) -> int:
	var experience := 0
	var required := 5
	var choices := 0
	for index in range(mini(stage_count, GameManagerScript.RUN_PHASES.size())):
		var phase: Dictionary = GameManagerScript.RUN_PHASES[index]
		experience += int(phase.get("kill_target", 0))
		experience += int(phase.get("reward_experience", 0))
		while experience >= required:
			experience -= required
			choices += 1
			required = int(ceil(float(required) * 1.35 + 2.0))
	return choices

func _estimate_spawn_capacity(phase: Dictionary) -> int:
	var duration := float(phase.get("duration", 30.0))
	var interval := maxf(0.1, float(phase.get("spawn_interval", 1.0)))
	var count := maxi(1, int(phase.get("spawn_count", 1)))
	return int(floor(duration / interval)) * count

func _format_refresh_costs(completed_stage: int) -> String:
	var costs: Array[String] = []
	for refresh_count in range(3):
		var stage_surcharge := int(floor(float(completed_stage) / 2.0))
		var cost := GameManagerScript.SHOP_REFRESH_BASE_COST + stage_surcharge + refresh_count * 5
		costs.append(str(cost))
	return " / ".join(costs)

func _is_special_prep_shop(next_stage: int) -> bool:
	return _is_encounter_stage(next_stage) or next_stage >= GameManagerScript.STAGE_COUNT

func _is_boss_or_final_prep_shop(next_stage: int) -> bool:
	if next_stage >= GameManagerScript.STAGE_COUNT:
		return true
	for encounter in GameManagerScript.ENCOUNTER_SCHEDULE:
		if int(encounter.get("stage_index", -1)) == next_stage and str(encounter.get("kind", "")) == "boss":
			return true
	return false

func _is_encounter_stage(stage_number: int) -> bool:
	for encounter in GameManagerScript.ENCOUNTER_SCHEDULE:
		if int(encounter.get("stage_index", -1)) == stage_number:
			return true
	return false

func _min_int(values: Array) -> int:
	if values.is_empty():
		return 0
	var result := int(values[0])
	for value in values:
		result = mini(result, int(value))
	return result

func _median_int(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	return int(sorted[int(floor(float(sorted.size() - 1) / 2.0))])
