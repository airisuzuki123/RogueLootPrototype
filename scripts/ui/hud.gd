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
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var inventory_recommendation_label: Label
var current_inventory_label: Label
var selected_inventory_label: Label
var inventory_summary_label: Label
var inventory_equip_button: Button
var inventory_salvage_button: Button
var inventory_items: Array = []
var selected_inventory_index: int = -1
var inventory_filter_slot_id: String = "all"
var inventory_filter_buttons: Dictionary = {}
var equipped_items: Dictionary = {}
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
	hint_label.text = "WASD 移动 | 自动攻击 | 拾取掉落 | B 背包 | 升级时选择强化"
	hint_label.position = Vector2(16, 690)
	root.add_child(hint_label)

	_build_inventory_panel(root)

	equipment_choice_panel = PanelContainer.new()
	equipment_choice_panel.visible = false
	equipment_choice_panel.position = Vector2(320, 150)
	equipment_choice_panel.custom_minimum_size = Vector2(640, 380)
	root.add_child(equipment_choice_panel)

	var equipment_choice_list := VBoxContainer.new()
	equipment_choice_list.add_theme_constant_override("separation", 10)
	equipment_choice_panel.add_child(equipment_choice_list)

	var equipment_title := Label.new()
	equipment_title.text = "发现装备"
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
	equipment_delta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipment_choice_list.add_child(equipment_delta_label)

	var equipment_button_row := HBoxContainer.new()
	equipment_button_row.add_theme_constant_override("separation", 12)
	equipment_choice_list.add_child(equipment_button_row)

	equip_button = Button.new()
	equip_button.text = "装备新品"
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
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.inventory_open_changed.connect(_on_inventory_open_changed)
	GameManager.upgrade_choices_requested.connect(_on_upgrade_choices_requested)
	GameManager.run_ended.connect(_on_run_ended)

func _refresh_all() -> void:
	_on_gold_changed(GameManager.gold)
	_on_enemy_killed(GameManager.kills)
	_on_experience_changed(GameManager.experience, GameManager.experience_to_next_level, GameManager.level)
	_on_health_changed(GameManager.player_health, GameManager.player_max_health)
	_on_equipment_changed(GameManager.equipped_items)
	_on_loot_message_changed(GameManager.latest_loot_message)
	_on_inventory_changed(GameManager.get_inventory_items())

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event.keycode == KEY_B:
		GameManager.toggle_inventory_open()
	elif key_event.keycode == KEY_ESCAPE and GameManager.is_inventory_open:
		GameManager.set_inventory_open(false)

func _on_gold_changed(total: int) -> void:
	gold_label.text = "金币：%d" % total

func _on_enemy_killed(total: int) -> void:
	kills_label.text = "击杀：%d" % total

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "生命：%d / %d" % [current, maximum]

func _on_experience_changed(current: int, required: int, level: int) -> void:
	experience_label.text = "等级 %d  经验：%d / %d" % [level, current, required]

func _on_equipment_changed(new_equipped_items: Dictionary) -> void:
	equipped_items = new_equipped_items.duplicate(true)
	equipment_label.text = EquipmentFactory.describe_loadout(equipped_items)
	_refresh_inventory_panel()

func _on_loot_message_changed(message: String) -> void:
	loot_message_label.text = message

func _on_inventory_changed(items: Array) -> void:
	inventory_items = items.duplicate(true)
	if selected_inventory_index >= inventory_items.size():
		selected_inventory_index = inventory_items.size() - 1
	if selected_inventory_index < 0 and not inventory_items.is_empty():
		selected_inventory_index = 0
	_refresh_inventory_panel()

func _on_inventory_open_changed(is_open: bool) -> void:
	inventory_panel.visible = is_open
	if is_open and selected_inventory_index < 0 and not inventory_items.is_empty():
		selected_inventory_index = 0
	_refresh_inventory_panel()

func _on_equipment_choice_requested(candidate: Dictionary, current: Dictionary, salvage_value: int) -> void:
	current_weapon_label.text = "当前\n%s" % EquipmentFactory.describe_with_score(current)
	candidate_weapon_label.text = "新装备\n%s" % EquipmentFactory.describe_with_score(candidate)
	equipment_delta_label.text = EquipmentFactory.get_comparison_summary(candidate, current)
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
	inventory_panel.visible = false
	game_over_label.visible = true
	game_over_label.text = "本局结束\n击杀：%d\n金币：%d" % [kills, gold]

func _build_inventory_panel(root: Control) -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.visible = false
	inventory_panel.position = Vector2(200, 70)
	inventory_panel.custom_minimum_size = Vector2(880, 560)
	root.add_child(inventory_panel)

	var panel_root := VBoxContainer.new()
	panel_root.add_theme_constant_override("separation", 10)
	inventory_panel.add_child(panel_root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	panel_root.add_child(title_row)

	var title := Label.new()
	title.text = "背包"
	title.custom_minimum_size = Vector2(740, 28)
	title_row.add_child(title)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(86, 32)
	close_button.pressed.connect(_on_inventory_close_pressed)
	title_row.add_child(close_button)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	panel_root.add_child(filter_row)
	_add_inventory_filter_button(filter_row, "all", "全部")
	for slot in EquipmentFactory.EQUIPMENT_SLOTS:
		_add_inventory_filter_button(filter_row, str(slot["id"]), str(slot["label"]))

	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 14)
	panel_root.add_child(content_row)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(320, 430)
	content_row.add_child(list_scroll)

	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 6)
	list_scroll.add_child(inventory_list)

	var detail_column := VBoxContainer.new()
	detail_column.custom_minimum_size = Vector2(500, 430)
	detail_column.add_theme_constant_override("separation", 10)
	content_row.add_child(detail_column)

	inventory_recommendation_label = Label.new()
	inventory_recommendation_label.custom_minimum_size = Vector2(500, 34)
	inventory_recommendation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_recommendation_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45, 1.0))
	detail_column.add_child(inventory_recommendation_label)

	var comparison_row := HBoxContainer.new()
	comparison_row.add_theme_constant_override("separation", 12)
	detail_column.add_child(comparison_row)

	current_inventory_label = Label.new()
	current_inventory_label.custom_minimum_size = Vector2(240, 205)
	current_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_row.add_child(current_inventory_label)

	selected_inventory_label = Label.new()
	selected_inventory_label.custom_minimum_size = Vector2(240, 205)
	selected_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_row.add_child(selected_inventory_label)

	inventory_summary_label = Label.new()
	inventory_summary_label.custom_minimum_size = Vector2(500, 110)
	inventory_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_column.add_child(inventory_summary_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	detail_column.add_child(button_row)

	inventory_equip_button = Button.new()
	inventory_equip_button.text = "装备"
	inventory_equip_button.custom_minimum_size = Vector2(120, 44)
	inventory_equip_button.pressed.connect(_on_inventory_equip_pressed)
	button_row.add_child(inventory_equip_button)

	inventory_salvage_button = Button.new()
	inventory_salvage_button.custom_minimum_size = Vector2(180, 44)
	inventory_salvage_button.pressed.connect(_on_inventory_salvage_pressed)
	button_row.add_child(inventory_salvage_button)

func _refresh_inventory_panel() -> void:
	if inventory_list == null:
		return
	_ensure_selected_inventory_item_visible()
	_refresh_inventory_filter_buttons()
	for child in inventory_list.get_children():
		child.queue_free()
	var visible_indices := _get_visible_inventory_indices()
	for index in visible_indices:
		var equipment: Dictionary = inventory_items[index]
		var button := Button.new()
		button.text = _get_inventory_item_button_text(equipment, index == selected_inventory_index)
		button.custom_minimum_size = Vector2(300, 64)
		var rarity_color: Color = equipment.get("color", Color.WHITE)
		button.add_theme_color_override("font_color", rarity_color)
		button.add_theme_color_override("font_hover_color", rarity_color.lightened(0.16))
		button.add_theme_color_override("font_pressed_color", rarity_color.lightened(0.24))
		button.pressed.connect(_on_inventory_item_pressed.bind(index))
		inventory_list.add_child(button)
	_refresh_inventory_detail()

func _refresh_inventory_detail() -> void:
	var has_selection := selected_inventory_index >= 0 and selected_inventory_index < inventory_items.size() and _is_equipment_visible(inventory_items[selected_inventory_index])
	inventory_equip_button.disabled = not has_selection
	inventory_salvage_button.disabled = not has_selection
	if not has_selection:
		inventory_recommendation_label.text = "背包为空" if inventory_items.is_empty() else "当前筛选无装备"
		current_inventory_label.text = "当前装备\n%s" % EquipmentFactory.describe_loadout(equipped_items)
		selected_inventory_label.text = "选中\n无"
		inventory_summary_label.text = "拾取到的装备会自动放入背包。"
		inventory_salvage_button.text = "分解"
		return
	var equipment: Dictionary = inventory_items[selected_inventory_index]
	var current_equipment := _get_current_equipment_for(equipment)
	var slot_label := EquipmentFactory.get_slot_label(str(equipment.get("slot", "weapon")))
	inventory_recommendation_label.text = EquipmentFactory.get_recommendation_text(equipment, current_equipment)
	current_inventory_label.text = "当前%s\n%s" % [slot_label, EquipmentFactory.describe_with_score(current_equipment)]
	selected_inventory_label.text = "选中\n%s" % EquipmentFactory.describe_with_score(equipment)
	inventory_summary_label.text = "变化\n%s" % EquipmentFactory.get_comparison_summary(equipment, current_equipment)
	inventory_salvage_button.text = "分解 +%d 金币" % EquipmentFactory.get_salvage_value(equipment)

func _get_inventory_item_button_text(equipment: Dictionary, is_selected: bool) -> String:
	var prefix := ">" if is_selected else " "
	var slot_label := EquipmentFactory.get_slot_label(str(equipment.get("slot", "weapon")))
	var form_name := EquipmentFactory.get_form_name(equipment).replace("法杖", "")
	var score_delta := EquipmentFactory.get_score_delta_label(equipment, _get_current_equipment_for(equipment))
	return "%s %s  [%s/%s]\n%s | 等级 %d | 评分 %d (%s)" % [
		prefix,
		str(equipment.get("name", "未知装备")),
		slot_label,
		form_name,
		str(equipment.get("rarity", "普通")),
		int(equipment.get("level", 1)),
		EquipmentFactory.get_score(equipment),
		score_delta
	]

func _on_inventory_item_pressed(index: int) -> void:
	selected_inventory_index = index
	_refresh_inventory_panel()

func _on_inventory_equip_pressed() -> void:
	GameManager.equip_inventory_equipment(selected_inventory_index)

func _on_inventory_salvage_pressed() -> void:
	GameManager.salvage_inventory_equipment(selected_inventory_index)

func _on_inventory_close_pressed() -> void:
	GameManager.set_inventory_open(false)

func _add_inventory_filter_button(parent: Control, slot_id: String, label: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(78, 32)
	button.pressed.connect(_on_inventory_filter_pressed.bind(slot_id))
	parent.add_child(button)
	inventory_filter_buttons[slot_id] = button

func _on_inventory_filter_pressed(slot_id: String) -> void:
	inventory_filter_slot_id = slot_id
	_ensure_selected_inventory_item_visible()
	_refresh_inventory_panel()

func _refresh_inventory_filter_buttons() -> void:
	for slot_id in inventory_filter_buttons.keys():
		var button: Button = inventory_filter_buttons[slot_id]
		button.disabled = str(slot_id) == inventory_filter_slot_id

func _ensure_selected_inventory_item_visible() -> void:
	var selection_visible := selected_inventory_index >= 0 and selected_inventory_index < inventory_items.size()
	if selection_visible:
		selection_visible = _is_equipment_visible(inventory_items[selected_inventory_index])
	if selection_visible:
		return
	selected_inventory_index = -1
	for index in _get_visible_inventory_indices():
		selected_inventory_index = index
		return

func _get_visible_inventory_indices() -> Array:
	var indices := []
	for index in range(inventory_items.size()):
		if _is_equipment_visible(inventory_items[index]):
			indices.append(index)
	return indices

func _is_equipment_visible(equipment: Dictionary) -> bool:
	if inventory_filter_slot_id == "all":
		return true
	return str(equipment.get("slot", "weapon")) == inventory_filter_slot_id

func _get_current_equipment_for(equipment: Dictionary) -> Dictionary:
	var slot_id := str(equipment.get("slot", "weapon"))
	return equipped_items.get(slot_id, {})
