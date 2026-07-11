extends CanvasLayer

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

var gold_label: Label
var kills_label: Label
var health_label: Label
var experience_label: Label
var equipment_label: Label
var loot_message_label: Label
var hint_label: Label
var equipment_choice_panel: PanelContainer
var current_weapon_label: Label
var candidate_weapon_label: Label
var equipment_delta_label: Label
var equip_button: Button
var salvage_button: Button
var upgrade_panel: PanelContainer
var upgrade_list: VBoxContainer
var game_over_label: Label

func _ready() -> void:
	layer = 10
	_build_ui()
	_connect_signals()
	_refresh_all()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var stats := VBoxContainer.new()
	stats.position = Vector2(16, 16)
	stats.custom_minimum_size = Vector2(260, 120)
	root.add_child(stats)

	health_label = Label.new()
	stats.add_child(health_label)

	experience_label = Label.new()
	stats.add_child(experience_label)

	gold_label = Label.new()
	stats.add_child(gold_label)

	kills_label = Label.new()
	stats.add_child(kills_label)

	equipment_label = Label.new()
	equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_child(equipment_label)

	loot_message_label = Label.new()
	stats.add_child(loot_message_label)

	hint_label = Label.new()
	hint_label.text = "WASD 移动 | 自动攻击 | 拾取掉落 | 升级时选择强化"
	hint_label.position = Vector2(16, 690)
	root.add_child(hint_label)

	equipment_choice_panel = PanelContainer.new()
	equipment_choice_panel.visible = false
	equipment_choice_panel.position = Vector2(320, 150)
	equipment_choice_panel.custom_minimum_size = Vector2(640, 310)
	root.add_child(equipment_choice_panel)

	var equipment_choice_list := VBoxContainer.new()
	equipment_choice_list.add_theme_constant_override("separation", 10)
	equipment_choice_panel.add_child(equipment_choice_list)

	var equipment_title := Label.new()
	equipment_title.text = "发现武器"
	equipment_choice_list.add_child(equipment_title)

	var comparison_row := HBoxContainer.new()
	comparison_row.add_theme_constant_override("separation", 18)
	equipment_choice_list.add_child(comparison_row)

	current_weapon_label = Label.new()
	current_weapon_label.custom_minimum_size = Vector2(300, 150)
	current_weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_row.add_child(current_weapon_label)

	candidate_weapon_label = Label.new()
	candidate_weapon_label.custom_minimum_size = Vector2(300, 150)
	candidate_weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_row.add_child(candidate_weapon_label)

	equipment_delta_label = Label.new()
	equipment_choice_list.add_child(equipment_delta_label)

	var equipment_button_row := HBoxContainer.new()
	equipment_button_row.add_theme_constant_override("separation", 12)
	equipment_choice_list.add_child(equipment_button_row)

	equip_button = Button.new()
	equip_button.text = "装备新武器"
	equip_button.custom_minimum_size = Vector2(180, 44)
	equip_button.pressed.connect(_on_equip_button_pressed)
	equipment_button_row.add_child(equip_button)

	salvage_button = Button.new()
	salvage_button.custom_minimum_size = Vector2(220, 44)
	salvage_button.pressed.connect(_on_salvage_button_pressed)
	equipment_button_row.add_child(salvage_button)

	upgrade_panel = PanelContainer.new()
	upgrade_panel.visible = false
	upgrade_panel.position = Vector2(390, 150)
	upgrade_panel.custom_minimum_size = Vector2(500, 260)
	root.add_child(upgrade_panel)

	upgrade_list = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 10)
	upgrade_panel.add_child(upgrade_list)

	var title := Label.new()
	title.text = "升级：选择一个强化"
	upgrade_list.add_child(title)

	game_over_label = Label.new()
	game_over_label.visible = false
	game_over_label.position = Vector2(440, 320)
	root.add_child(game_over_label)

func _connect_signals() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.enemy_killed.connect(_on_enemy_killed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.experience_changed.connect(_on_experience_changed)
	GameManager.equipment_changed.connect(_on_equipment_changed)
	GameManager.loot_message_changed.connect(_on_loot_message_changed)
	GameManager.equipment_choice_requested.connect(_on_equipment_choice_requested)
	GameManager.upgrade_choices_requested.connect(_on_upgrade_choices_requested)
	GameManager.run_ended.connect(_on_run_ended)

func _refresh_all() -> void:
	_on_gold_changed(GameManager.gold)
	_on_enemy_killed(GameManager.kills)
	_on_experience_changed(GameManager.experience, GameManager.experience_to_next_level, GameManager.level)
	_on_health_changed(GameManager.player_health, GameManager.player_max_health)
	_on_equipment_changed(GameManager.equipped_weapon)
	_on_loot_message_changed(GameManager.latest_loot_message)

func _on_gold_changed(total: int) -> void:
	gold_label.text = "金币：%d" % total

func _on_enemy_killed(total: int) -> void:
	kills_label.text = "击杀：%d" % total

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "生命：%d / %d" % [current, maximum]

func _on_experience_changed(current: int, required: int, level: int) -> void:
	experience_label.text = "等级 %d  经验：%d / %d" % [level, current, required]

func _on_equipment_changed(equipment: Dictionary) -> void:
	equipment_label.text = EquipmentFactory.describe(equipment)

func _on_loot_message_changed(message: String) -> void:
	loot_message_label.text = message

func _on_equipment_choice_requested(candidate: Dictionary, current: Dictionary, salvage_value: int) -> void:
	current_weapon_label.text = "当前\n%s" % EquipmentFactory.describe_with_score(current)
	candidate_weapon_label.text = "新武器\n%s" % EquipmentFactory.describe_with_score(candidate)
	equipment_delta_label.text = EquipmentFactory.get_score_delta_text(candidate, current)
	salvage_button.text = "保留当前，分解 +%d 金币" % salvage_value
	equipment_choice_panel.visible = true

func _on_equip_button_pressed() -> void:
	equipment_choice_panel.visible = false
	GameManager.equip_pending_equipment()

func _on_salvage_button_pressed() -> void:
	equipment_choice_panel.visible = false
	GameManager.salvage_pending_equipment()

func _on_upgrade_choices_requested(choices: Array) -> void:
	for child in upgrade_list.get_children():
		if child is Button:
			child.queue_free()
	for index in range(choices.size()):
		var choice: Dictionary = choices[index]
		var button := Button.new()
		button.text = "%s\n%s" % [choice["title"], choice["description"]]
		button.custom_minimum_size = Vector2(460, 52)
		button.pressed.connect(_on_upgrade_button_pressed.bind(index))
		upgrade_list.add_child(button)
	upgrade_panel.visible = true

func _on_upgrade_button_pressed(index: int) -> void:
	upgrade_panel.visible = false
	GameManager.apply_upgrade(index)

func _on_run_ended(kills: int, gold: int) -> void:
	game_over_label.visible = true
	game_over_label.text = "本局结束\n击杀：%d\n金币：%d" % [kills, gold]
