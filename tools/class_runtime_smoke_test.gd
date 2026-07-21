extends Node

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_bulwark_gunner()
	await _test_steady_marksman()
	await _test_close_blade_guard()
	await _test_roaming_arc()
	await _test_heavy_bomber()
	await _test_main_ui_flow()
	if failures.is_empty():
		print("职业运行时冒烟测试通过：5/5")
		get_tree().quit()
		return
	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _test_bulwark_gunner() -> void:
	var player := await _create_player("bulwark_gunner")
	_check_summary("巨躯炮台", {"class_name": "巨躯炮台", "player_size_bonus": 15, "move_speed": 234})
	player.apply_upgrade("multishot")
	_check_summary("巨躯炮台分裂射击", {"projectiles": 3, "move_speed": 187})
	player.apply_upgrade("piercing_rounds")
	player.apply_upgrade("mass_resonance")
	_check_summary("巨躯炮台三技能", {"pierce": 2, "mass_resonance_stacks": 1})
	player.queue_free()
	await get_tree().process_frame

func _test_steady_marksman() -> void:
	var player := await _create_player("steady_marksman")
	_check_summary("沉稳射手", {"class_name": "沉稳射手", "critical_chance": 5})
	player.apply_upgrade("piercing_rounds")
	_check_summary("沉稳射手穿透弹芯", {"pierce": 2})
	player.apply_upgrade("pierce_amp")
	player.apply_upgrade("still_focus")
	_check_summary("沉稳射手三技能", {"pierce": 4, "still_focus_stacks": 1})
	player.queue_free()
	await get_tree().process_frame

func _test_close_blade_guard() -> void:
	var player := await _create_player("close_blade_guard")
	_check_summary("贴身刃卫", {"class_name": "贴身刃卫", "shield": 20})
	player.apply_upgrade("close_slash")
	player.apply_upgrade("pulse_field")
	player.apply_upgrade("guard_blade")
	_check_summary("贴身刃卫三技能", {"shield": 60, "close_slash_stacks": 1, "pulse_field_stacks": 1})
	player.queue_free()
	await get_tree().process_frame

func _test_roaming_arc() -> void:
	var player := await _create_player("roaming_arc")
	_check_summary("游走电弧", {"class_name": "游走电弧", "player_size_bonus": -12, "move_speed": 299})
	player.apply_upgrade("move_speed")
	_check_summary("游走电弧迅捷步伐", {"move_speed": 439})
	player.apply_upgrade("orbit_blade")
	player.apply_upgrade("chain_spark")
	player.apply_upgrade("motion_focus")
	_check_summary("游走电弧三技能", {"orbit_blade_stacks": 1, "chain_spark_stacks": 1, "motion_focus_stacks": 1})
	player.queue_free()
	await get_tree().process_frame

func _test_heavy_bomber() -> void:
	var player := await _create_player("heavy_bomber")
	_check_summary("重弹爆破", {"class_name": "重弹爆破", "explosion_radius": 20})
	player.apply_upgrade("blast_core")
	_check_summary("重弹爆破爆裂核心", {"explosion_radius": 100})
	player.apply_upgrade("shatter_blast")
	player.apply_upgrade("heavy_shot")
	_check_summary("重弹爆破三技能", {"explosion_radius": 112, "shatter_blast_stacks": 1, "heavy_shot_stacks": 1})
	player.queue_free()
	await get_tree().process_frame

func _test_main_ui_flow() -> void:
	var main := MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud := main.get_node_or_null("HUD")
	if hud == null:
		failures.append("主场景：HUD 未生成")
	else:
		var class_panel = hud.get("class_selection_panel")
		if class_panel == null or not bool(class_panel.visible):
			failures.append("主场景：职业选择面板未显示")
		if not GameManager.choose_character_class("bulwark_gunner"):
			failures.append("主场景：职业选择失败")
		await get_tree().process_frame
		var upgrade_panel = hud.get("upgrade_panel")
		if class_panel == null or bool(class_panel.visible):
			failures.append("主场景：选择职业后职业面板未关闭")
		if upgrade_panel == null or not bool(upgrade_panel.visible):
			failures.append("主场景：选择职业后开局三选一面板未显示")
	main.queue_free()
	await get_tree().process_frame

func _create_player(class_id: String) -> Node:
	GameManager.reset_run()
	var player := PLAYER_SCENE.instantiate()
	get_tree().root.add_child(player)
	await get_tree().process_frame
	GameManager.register_player(player)
	if not GameManager.choose_character_class(class_id):
		failures.append("%s：职业选择失败" % class_id)
	elif not GameManager.is_upgrade_pending or not GameManager.is_opening_upgrade_choice or GameManager.pending_upgrade_choices.size() != 3:
		failures.append("%s：选择职业后未生成开局三选一" % class_id)
	return player

func _check_summary(label: String, expected: Dictionary) -> void:
	var summary: Dictionary = GameManager.player_build_summary
	for key in expected.keys():
		var actual_value = summary.get(key)
		var expected_value = expected.get(key)
		if actual_value != expected_value:
			failures.append("%s：%s 实际为 %s，预期为 %s" % [label, str(key), str(actual_value), str(expected_value)])
