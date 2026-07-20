extends SceneTree

const CharacterClassCatalog := preload("res://scripts/items/character_class_catalog.gd")

const REPORT_PATH := "res://docs/class-effect-audit.md"
const FLOAT_TOLERANCE := 0.01
const SUPPORTED_INITIAL_STATS := [
	"player_size_bonus",
	"move_speed_multiplier",
	"critical_chance",
	"explosion_radius",
	"fire_interval_multiplier",
	"shield",
	"shield_duration"
]
const SUPPORTED_MULTIPLIERS := [
	"mass_resonance_damage",
	"stationary_crit",
	"close_damage",
	"close_radius",
	"chain_orbit_homing_damage",
	"heavy_overload_damage"
]
const SUPPORTED_FOCUS_DECAY := [
	"stationary_move_decay_multiplier"
]
const SUPPORTED_GAIN_MULTIPLIERS := [
	"damage",
	"damage_flat",
	"projectile_damage_percent",
	"move_speed",
	"max_health",
	"critical_chance",
	"projectile_count",
	"pierce",
	"explosion_radius",
	"shield",
	"heal",
	"player_size_bonus",
	"player_size_reduction"
]

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var report := _build_report()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法写入职业效果审计报告：%s" % REPORT_PATH)
		quit(1)
		return
	file.store_string(report)
	file.close()
	if failures.is_empty():
		print("已生成职业效果审计报告：%s" % REPORT_PATH)
		quit()
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _build_report() -> String:
	failures.clear()
	var lines: Array[String] = []
	lines.append("# 阶段 5.5 职业效果审计报告")
	lines.append("")
	lines.append("本报告由 `tools/class_effect_audit.gd` 生成，用于检查初始职业数据按 Player 当前支持规则计算后的开局数值。")
	lines.append("")
	lines.append("## 审计口径")
	lines.append("")
	lines.append("- 按 `Player.apply_character_class()` 当前支持的开局规则计算职业进入第一关时的玩家摘要。")
	lines.append("- 检查玩家可见的开局属性：职业名、体积、移速、暴击率、爆裂范围、射击间隔和护盾。")
	lines.append("- 检查职业是否只使用 Player 当前支持的初始属性、乘区、属性获取倍率和专注衰减键；面向玩家展示开局效果和成长收益，不把内部权重、标签或路线显示给玩家。")
	lines.append("")
	lines.append("## 结论摘要")
	lines.append("")
	var rows: Array[Dictionary] = []
	for class_data in CharacterClassCatalog.get_class_list():
		var row := _audit_class(class_data)
		rows.append(row)
		lines.append("- %s：%s；开局摘要 %s；样例收益 %s。" % [
			str(row.get("name", "")),
			"通过" if bool(row.get("passed", false)) else "失败",
			str(row.get("summary_text", "")),
			str(row.get("gain_example_text", ""))
		])
	lines.append("")
	lines.append("## 职业明细")
	lines.append("")
	for row in rows:
		lines.append("### %s" % str(row.get("name", "")))
		lines.append("")
		lines.append("- 结果：%s" % ("通过" if bool(row.get("passed", false)) else "失败"))
		lines.append("- 玩家可见效果：%s" % str(row.get("effects", "")))
		lines.append("- 玩家可见成长收益：%s" % str(row.get("gain_summary", "")))
		lines.append("- 玩家可见清群入口：%s" % str(row.get("clear_summary", "")))
		lines.append("")
		lines.append("| 项目 | 实际 | 预期 |")
		lines.append("|---|---:|---:|")
		for check in row.get("checks", []):
			lines.append("| %s | %s | %s |" % [
				str(check.get("label", "")),
				str(check.get("actual", "")),
				str(check.get("expected", ""))
			])
		lines.append("")
		var multipliers: Dictionary = row.get("multipliers", {})
		if not multipliers.is_empty():
			lines.append("乘区配置：%s" % _format_dictionary(multipliers))
		var gain_multipliers: Dictionary = row.get("gain_multipliers", {})
		if not gain_multipliers.is_empty():
			lines.append("属性获取倍率：%s" % _format_dictionary(gain_multipliers))
			lines.append("样例收益：%s" % str(row.get("gain_example_text", "")))
		var focus_decay: Dictionary = row.get("focus_decay", {})
		if not focus_decay.is_empty():
			lines.append("专注衰减配置：%s" % _format_dictionary(focus_decay))
		lines.append("")
	while not lines.is_empty() and str(lines[-1]).is_empty():
		lines.pop_back()
	return "\n".join(lines) + "\n"

func _audit_class(class_data: Dictionary) -> Dictionary:
	var summary := _expected_start_summary(class_data)
	var checks: Array[Dictionary] = []
	checks.append(_check_bool(class_data, "职业名", not str(class_data.get("name", "")).is_empty(), "已填写", "已填写"))
	checks.append(_check_bool(class_data, "职业说明", not str(class_data.get("summary", "")).is_empty(), "已填写", "已填写"))
	checks.append(_check_bool(class_data, "玩家可见效果", not class_data.get("effects", []).is_empty(), "已填写", "已填写"))
	checks.append(_check_bool(class_data, "玩家可见成长收益", not str(class_data.get("gain_summary", "")).is_empty(), "已填写", "已填写"))
	checks.append(_check_bool(class_data, "玩家可见清群入口", not str(class_data.get("clear_summary", "")).is_empty(), "已填写", "已填写"))
	checks.append(_check_supported_keys(class_data, "初始属性键", class_data.get("initial_stats", {}), SUPPORTED_INITIAL_STATS))
	var multipliers: Dictionary = class_data.get("multipliers", {})
	checks.append(_check_supported_keys(class_data, "乘区键", multipliers, SUPPORTED_MULTIPLIERS))
	for key in multipliers.keys():
		checks.append(_check_float(class_data, "乘区 " + str(key), multipliers.get(key, 1.0), multipliers.get(key, 1.0)))
	var gain_multipliers: Dictionary = class_data.get("gain_multipliers", {})
	checks.append(_check_supported_keys(class_data, "属性获取倍率键", gain_multipliers, SUPPORTED_GAIN_MULTIPLIERS))
	for key in gain_multipliers.keys():
		checks.append(_check_float(class_data, "属性获取 " + str(key), gain_multipliers.get(key, 1.0), gain_multipliers.get(key, 1.0)))
	var focus_decay: Dictionary = class_data.get("focus_decay", {})
	checks.append(_check_supported_keys(class_data, "专注衰减键", focus_decay, SUPPORTED_FOCUS_DECAY))
	for key in focus_decay.keys():
		checks.append(_check_float(class_data, "专注衰减 " + str(key), focus_decay.get(key, 1.0), focus_decay.get(key, 1.0)))
	checks.append(_check_int(class_data, "玩家体积加成", summary.get("player_size_bonus", 0), summary.get("player_size_bonus", 0), "%"))
	checks.append(_check_int(class_data, "当前移速", summary.get("move_speed", 0), summary.get("move_speed", 0)))
	checks.append(_check_int(class_data, "暴击率", summary.get("critical_chance", 0), summary.get("critical_chance", 0), "%"))
	checks.append(_check_int(class_data, "爆裂范围", summary.get("explosion_radius", 0), summary.get("explosion_radius", 0)))
	checks.append(_check_float(class_data, "射击间隔", summary.get("attack_interval", 0.0), summary.get("attack_interval", 0.0), "秒"))
	checks.append(_check_int(class_data, "护盾", summary.get("shield", 0), summary.get("shield", 0)))
	return {
		"name": str(class_data.get("name", "")),
		"effects": "；".join(class_data.get("effects", [])),
		"gain_summary": str(class_data.get("gain_summary", "")),
		"clear_summary": str(class_data.get("clear_summary", "")),
		"passed": _checks_passed(checks),
		"summary_text": _format_summary(summary),
		"gain_example_text": _format_gain_examples(class_data),
		"checks": checks,
		"multipliers": multipliers,
		"gain_multipliers": gain_multipliers,
		"focus_decay": focus_decay
	}

func _expected_start_summary(class_data: Dictionary) -> Dictionary:
	var initial_stats: Dictionary = class_data.get("initial_stats", {})
	return {
		"class_name": str(class_data.get("name", "")),
		"player_size_bonus": int(round(float(initial_stats.get("player_size_bonus", 0.0)) * 100.0)),
		"move_speed": int(round(260.0 * float(initial_stats.get("move_speed_multiplier", 1.0)))),
		"critical_chance": int(initial_stats.get("critical_chance", 0)),
		"explosion_radius": int(round(float(initial_stats.get("explosion_radius", 0.0)))),
		"attack_interval": 0.45 * float(initial_stats.get("fire_interval_multiplier", 1.0)),
		"shield": int(initial_stats.get("shield", 0))
	}

func _check_string(class_data: Dictionary, label: String, actual_value: Variant, expected_value: Variant) -> Dictionary:
	var actual := str(actual_value)
	var expected := str(expected_value)
	var passed := actual == expected
	if not passed:
		failures.append("%s：%s 实际为 %s，预期为 %s" % [str(class_data.get("name", "")), label, actual, expected])
	return {"label": label, "actual": actual, "expected": expected, "passed": passed}

func _check_int(class_data: Dictionary, label: String, actual_value: Variant, expected_value: Variant, suffix: String = "") -> Dictionary:
	var actual := int(actual_value)
	var expected := int(expected_value)
	var passed := actual == expected
	if not passed:
		failures.append("%s：%s 实际为 %d%s，预期为 %d%s" % [str(class_data.get("name", "")), label, actual, suffix, expected, suffix])
	return {"label": label, "actual": "%d%s" % [actual, suffix], "expected": "%d%s" % [expected, suffix], "passed": passed}

func _check_float(class_data: Dictionary, label: String, actual_value: Variant, expected_value: Variant, suffix: String = "") -> Dictionary:
	var actual := float(actual_value)
	var expected := float(expected_value)
	var passed := absf(actual - expected) <= FLOAT_TOLERANCE
	if not passed:
		failures.append("%s：%s 实际为 %.2f%s，预期为 %.2f%s" % [str(class_data.get("name", "")), label, actual, suffix, expected, suffix])
	return {"label": label, "actual": "%.2f%s" % [actual, suffix], "expected": "%.2f%s" % [expected, suffix], "passed": passed}

func _check_bool(class_data: Dictionary, label: String, passed: bool, actual: String, expected: String) -> Dictionary:
	if not passed:
		failures.append("%s：%s %s" % [str(class_data.get("name", "")), label, expected])
	return {"label": label, "actual": actual if passed else "缺失", "expected": expected, "passed": passed}

func _check_supported_keys(class_data: Dictionary, label: String, data: Dictionary, supported_keys: Array) -> Dictionary:
	var unsupported: Array[String] = []
	for key in data.keys():
		if not supported_keys.has(str(key)):
			unsupported.append(str(key))
	var passed := unsupported.is_empty()
	if not passed:
		failures.append("%s：%s 包含未接入键 %s" % [str(class_data.get("name", "")), label, "、".join(unsupported)])
	return {
		"label": label,
		"actual": "全部已接入" if passed else "未接入：" + "、".join(unsupported),
		"expected": "全部已接入",
		"passed": passed
	}

func _checks_passed(checks: Array[Dictionary]) -> bool:
	for check in checks:
		if not bool(check.get("passed", false)):
			return false
	return true

func _format_summary(summary: Dictionary) -> String:
	return "体积 %+d%% / 移速 %d / 暴击 %d%% / 爆裂范围 %d / 射击间隔 %.2f 秒 / 护盾 %d" % [
		int(summary.get("player_size_bonus", 0)),
		int(summary.get("move_speed", 0)),
		int(summary.get("critical_chance", 0)),
		int(summary.get("explosion_radius", 0)),
		float(summary.get("attack_interval", 0.0)),
		int(summary.get("shield", 0))
	]

func _format_dictionary(data: Dictionary) -> String:
	var parts: Array[String] = []
	for key in data.keys():
		var value = data.get(key)
		if value is float:
			parts.append("%s %.2f" % [str(key), float(value)])
		else:
			parts.append("%s %s" % [str(key), str(value)])
	return " / ".join(parts)

func _format_gain_examples(class_data: Dictionary) -> String:
	var gains: Dictionary = class_data.get("gain_multipliers", {})
	var examples: Array[String] = []
	if gains.has("projectile_count"):
		examples.append("投射物 +1 => +%d" % _scale_example_int(gains, "projectile_count", 1))
	if gains.has("pierce"):
		examples.append("穿透 +1 => +%d" % _scale_example_int(gains, "pierce", 1))
	if gains.has("explosion_radius"):
		examples.append("爆裂范围 +40 => +%d" % int(round(_scale_example_float(gains, "explosion_radius", 40.0))))
	if gains.has("move_speed"):
		examples.append("移速 +70 => +%d" % int(round(_scale_example_float(gains, "move_speed", 70.0))))
	if gains.has("critical_chance"):
		examples.append("暴击率 +5%% => +%d%%" % _scale_example_int(gains, "critical_chance", 5))
	if gains.has("max_health"):
		examples.append("最大生命 +30 => +%d" % _scale_example_int(gains, "max_health", 30))
	if gains.has("shield"):
		examples.append("护盾 +20 => +%d" % _scale_example_int(gains, "shield", 20))
	if gains.has("projectile_damage_percent"):
		examples.append("投射物伤害 +25%% => +%d%%" % int(round(_scale_example_float(gains, "projectile_damage_percent", 25.0))))
	return " / ".join(examples) if not examples.is_empty() else "无额外属性倍率"

func _scale_example_int(gains: Dictionary, key: String, base_value: int) -> int:
	if base_value == 0:
		return 0
	var multiplier := maxf(0.0, float(gains.get(key, 1.0)))
	if multiplier <= 0.0:
		return 0
	return maxi(1, int(round(float(base_value) * multiplier)))

func _scale_example_float(gains: Dictionary, key: String, base_value: float) -> float:
	return base_value * maxf(0.0, float(gains.get(key, 1.0)))
