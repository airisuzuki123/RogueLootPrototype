extends SceneTree

const GameManagerScript := preload("res://scripts/core/game_manager.gd")
const SkillCatalog := preload("res://scripts/items/skill_catalog.gd")

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
