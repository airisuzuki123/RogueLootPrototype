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
var inventory_capacity_label: Label
var inventory_list: GridContainer
var equipped_slot_buttons: Dictionary = {}
var salvage_rarity_buttons: Dictionary = {}
var detail_modal_overlay: Control
var detail_modal_panel: PanelContainer
var detail_title_label: Label
var detail_body_label: Label
var detail_comparison_label: Label
var detail_equip_button: Button
var detail_salvage_button: Button
var inventory_items: Array = []
var selected_inventory_index: int = -1
var selected_equipment_source: String = ""
var selected_equipped_slot_id: String = ""
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
		if detail_modal_overlay != null and detail_modal_overlay.visible:
			detail_modal_overlay.visible = false
		else:
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
	if detail_modal_overlay != null and not is_open:
		detail_modal_overlay.visible = false
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
	inventory_panel.position = Vector2(110, 60)
	inventory_panel.custom_minimum_size = Vector2(1060, 600)
	root.add_child(inventory_panel)

	var panel_root := VBoxContainer.new()
	panel_root.add_theme_constant_override("separation", 12)
	inventory_panel.add_child(panel_root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	panel_root.add_child(title_row)

	var title := Label.new()
	title.text = "背包"
	title.custom_minimum_size = Vector2(120, 28)
	title_row.add_child(title)

	inventory_capacity_label = Label.new()
	inventory_capacity_label.custom_minimum_size = Vector2(160, 28)
	title_row.add_child(inventory_capacity_label)

	var salvage_label := Label.new()
	salvage_label.text = "一键分解："
	salvage_label.custom_minimum_size = Vector2(92, 28)
	title_row.add_child(salvage_label)

	for rarity in EquipmentFactory.RARITIES:
		var rarity_name := str(rarity["name"])
		var button := Button.new()
		button.text = rarity_name
		button.custom_minimum_size = Vector2(72, 32)
		button.pressed.connect(_on_salvage_rarity_pressed.bind(rarity_name))
		title_row.add_child(button)
		salvage_rarity_buttons[rarity_name] = button

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(86, 32)
	close_button.pressed.connect(_on_inventory_close_pressed)
	title_row.add_child(close_button)

	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 18)
	panel_root.add_child(content_row)

	var equipped_column := VBoxContainer.new()
	equipped_column.custom_minimum_size = Vector2(300, 500)
	equipped_column.add_theme_constant_override("separation", 12)
	content_row.add_child(equipped_column)

	var equipped_title := Label.new()
	equipped_title.text = "当前穿戴"
	equipped_column.add_child(equipped_title)

	_add_equipped_slot_row(equipped_column, ["helmet"])
	_add_equipped_slot_row(equipped_column, ["weapon", "armor"])
	_add_equipped_slot_row(equipped_column, ["necklace", "ring"])
	_add_equipped_slot_row(equipped_column, ["boots"])

	var inventory_column := VBoxContainer.new()
	inventory_column.custom_minimum_size = Vector2(700, 500)
	inventory_column.add_theme_constant_override("separation", 10)
	content_row.add_child(inventory_column)

	var inventory_title := Label.new()
	inventory_title.text = "背包装备"
	inventory_column.add_child(inventory_title)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(690, 460)
	inventory_column.add_child(list_scroll)

	inventory_list = GridContainer.new()
	inventory_list.columns = 6
	inventory_list.add_theme_constant_override("h_separation", 8)
	inventory_list.add_theme_constant_override("v_separation", 8)
	list_scroll.add_child(inventory_list)

	_build_inventory_detail_modal(root)

func _refresh_inventory_panel() -> void:
	if inventory_list == null:
		return
	_refresh_inventory_capacity()
	_refresh_salvage_buttons()
	_refresh_equipped_slot_buttons()
	for child in inventory_list.get_children():
		child.queue_free()
	if inventory_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "背包为空"
		empty_label.custom_minimum_size = Vector2(180, 42)
		inventory_list.add_child(empty_label)
		return
	for index in range(inventory_items.size()):
		var equipment: Dictionary = inventory_items[index]
		var button := Button.new()
		button.text = _get_equipment_icon_text(equipment, index == selected_inventory_index and selected_equipment_source == "inventory")
		button.custom_minimum_size = Vector2(104, 82)
		_apply_equipment_button_style(button, equipment, index == selected_inventory_index and selected_equipment_source == "inventory")
		button.pressed.connect(_on_inventory_item_pressed.bind(index))
		inventory_list.add_child(button)

func _on_inventory_item_pressed(index: int) -> void:
	selected_inventory_index = index
	selected_equipment_source = "inventory"
	selected_equipped_slot_id = ""
	_refresh_inventory_panel()
	_show_inventory_detail_modal()

func _on_inventory_close_pressed() -> void:
	if detail_modal_overlay != null:
		detail_modal_overlay.visible = false
	GameManager.set_inventory_open(false)

func _on_salvage_rarity_pressed(rarity_name: String) -> void:
	if detail_modal_overlay != null:
		detail_modal_overlay.visible = false
	GameManager.salvage_inventory_by_rarity(rarity_name)

func _refresh_inventory_capacity() -> void:
	if inventory_capacity_label == null:
		return
	var count := GameManager.get_inventory_count()
	var capacity := GameManager.get_inventory_capacity()
	inventory_capacity_label.text = "容量：%d / %d" % [count, capacity]
	var color := Color(1.0, 0.45, 0.35, 1.0) if count >= capacity else Color.WHITE
	inventory_capacity_label.add_theme_color_override("font_color", color)

func _refresh_salvage_buttons() -> void:
	for rarity_name in salvage_rarity_buttons.keys():
		var button: Button = salvage_rarity_buttons[rarity_name]
		button.disabled = _count_inventory_items_by_rarity(str(rarity_name)) <= 0

func _count_inventory_items_by_rarity(rarity_name: String) -> int:
	var count := 0
	for equipment in inventory_items:
		if str(equipment.get("rarity", "")) == rarity_name:
			count += 1
	return count

func _add_equipped_slot_row(parent: Control, slot_ids: Array) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	for slot_id in slot_ids:
		_add_equipped_slot_button(row, str(slot_id))

func _add_equipped_slot_button(parent: Control, slot_id: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(116, 76)
	button.pressed.connect(_on_equipped_slot_pressed.bind(slot_id))
	parent.add_child(button)
	equipped_slot_buttons[slot_id] = button

func _refresh_equipped_slot_buttons() -> void:
	for slot in EquipmentFactory.EQUIPMENT_SLOTS:
		var slot_id := str(slot["id"])
		if not equipped_slot_buttons.has(slot_id):
			continue
		var button: Button = equipped_slot_buttons[slot_id]
		var equipment: Dictionary = equipped_items.get(slot_id, {})
		var is_selected := selected_equipment_source == "equipped" and selected_equipped_slot_id == slot_id
		if equipment.is_empty():
			button.text = "%s\n空" % str(slot["label"])
			_apply_empty_slot_button_style(button, is_selected)
		else:
			button.text = _get_equipment_icon_text(equipment, is_selected)
			_apply_equipment_button_style(button, equipment, is_selected)

func _on_equipped_slot_pressed(slot_id: String) -> void:
	selected_equipment_source = "equipped"
	selected_equipped_slot_id = slot_id
	selected_inventory_index = -1
	_refresh_inventory_panel()
	_show_equipped_detail_modal(slot_id)

func _build_inventory_detail_modal(root: Control) -> void:
	detail_modal_overlay = Control.new()
	detail_modal_overlay.visible = false
	detail_modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_modal_overlay.gui_input.connect(_on_detail_overlay_gui_input)
	root.add_child(detail_modal_overlay)

	detail_modal_panel = PanelContainer.new()
	detail_modal_panel.position = Vector2(320, 90)
	detail_modal_panel.custom_minimum_size = Vector2(640, 520)
	detail_modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_modal_panel.gui_input.connect(_on_detail_panel_gui_input)
	detail_modal_overlay.add_child(detail_modal_panel)

	var modal_root := VBoxContainer.new()
	modal_root.add_theme_constant_override("separation", 10)
	detail_modal_panel.add_child(modal_root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	modal_root.add_child(title_row)

	detail_title_label = Label.new()
	detail_title_label.custom_minimum_size = Vector2(600, 28)
	title_row.add_child(detail_title_label)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2(600, 360)
	modal_root.add_child(detail_scroll)

	var detail_content := VBoxContainer.new()
	detail_content.custom_minimum_size = Vector2(580, 0)
	detail_content.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(detail_content)

	detail_body_label = Label.new()
	detail_body_label.custom_minimum_size = Vector2(580, 0)
	detail_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_content.add_child(detail_body_label)

	detail_comparison_label = Label.new()
	detail_comparison_label.custom_minimum_size = Vector2(580, 0)
	detail_comparison_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_comparison_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45, 1.0))
	detail_content.add_child(detail_comparison_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	modal_root.add_child(button_row)

	detail_equip_button = Button.new()
	detail_equip_button.text = "装备"
	detail_equip_button.custom_minimum_size = Vector2(120, 42)
	detail_equip_button.pressed.connect(_on_detail_equip_pressed)
	button_row.add_child(detail_equip_button)

	detail_salvage_button = Button.new()
	detail_salvage_button.custom_minimum_size = Vector2(170, 42)
	detail_salvage_button.pressed.connect(_on_detail_salvage_pressed)
	button_row.add_child(detail_salvage_button)

func _show_inventory_detail_modal() -> void:
	if selected_inventory_index < 0 or selected_inventory_index >= inventory_items.size():
		return
	var equipment: Dictionary = inventory_items[selected_inventory_index]
	var current_equipment := _get_current_equipment_for(equipment)
	var slot_label := EquipmentFactory.get_slot_label(str(equipment.get("slot", "weapon")))
	detail_title_label.text = str(equipment.get("name", "未知装备"))
	detail_body_label.text = "选中装备\n%s" % EquipmentFactory.describe_with_score(equipment)
	detail_comparison_label.text = "%s\n\n当前%s\n%s\n\n变化\n%s" % [
		EquipmentFactory.get_recommendation_text(equipment, current_equipment),
		slot_label,
		EquipmentFactory.describe_with_score(current_equipment),
		EquipmentFactory.get_comparison_summary(equipment, current_equipment)
	]
	detail_equip_button.visible = true
	detail_salvage_button.visible = true
	detail_salvage_button.text = "分解 +%d 金币" % EquipmentFactory.get_salvage_value(equipment)
	detail_modal_overlay.visible = true

func _show_equipped_detail_modal(slot_id: String) -> void:
	var slot_label := EquipmentFactory.get_slot_label(slot_id)
	var equipment: Dictionary = equipped_items.get(slot_id, {})
	detail_title_label.text = "当前%s" % slot_label
	if equipment.is_empty():
		detail_body_label.text = "%s槽位为空" % slot_label
	else:
		detail_body_label.text = EquipmentFactory.describe_with_score(equipment)
	detail_comparison_label.text = ""
	detail_equip_button.visible = false
	detail_salvage_button.visible = false
	detail_modal_overlay.visible = true

func _on_detail_equip_pressed() -> void:
	if selected_equipment_source != "inventory":
		return
	GameManager.equip_inventory_equipment(selected_inventory_index)
	detail_modal_overlay.visible = false

func _on_detail_salvage_pressed() -> void:
	if selected_equipment_source != "inventory":
		return
	GameManager.salvage_inventory_equipment(selected_inventory_index)
	detail_modal_overlay.visible = false

func _on_detail_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		detail_modal_overlay.visible = false

func _on_detail_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		detail_modal_panel.accept_event()

func _get_equipment_icon_text(equipment: Dictionary, is_selected: bool) -> String:
	var prefix := ">" if is_selected else ""
	var slot_symbol := _get_slot_symbol(str(equipment.get("slot", "weapon")))
	return "%s%s\nLv%d  %d" % [
		prefix,
		slot_symbol,
		int(equipment.get("level", 1)),
		EquipmentFactory.get_score(equipment)
	]

func _apply_equipment_button_style(button: Button, equipment: Dictionary, is_selected: bool) -> void:
	var rarity_color: Color = equipment.get("color", Color.WHITE)
	var border_color := Color.WHITE if is_selected else rarity_color
	var border_width := 4 if is_selected else 2
	_apply_icon_button_style(button, border_color, Color(0.10, 0.11, 0.12, 0.96), border_width)
	button.add_theme_color_override("font_color", rarity_color.lightened(0.12) if is_selected else rarity_color)
	button.add_theme_color_override("font_hover_color", rarity_color.lightened(0.24))
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

func _apply_empty_slot_button_style(button: Button, is_selected: bool) -> void:
	var border_color := Color.WHITE if is_selected else Color(0.35, 0.35, 0.35, 1.0)
	var border_width := 4 if is_selected else 2
	_apply_icon_button_style(button, border_color, Color(0.07, 0.07, 0.08, 0.92), border_width)
	button.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.90, 0.90, 0.90, 1.0))
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

func _apply_icon_button_style(button: Button, border_color: Color, bg_color: Color, border_width: int) -> void:
	button.add_theme_stylebox_override("normal", _make_icon_style(border_color, bg_color, border_width))
	button.add_theme_stylebox_override("hover", _make_icon_style(border_color.lightened(0.18), bg_color.lightened(0.08), border_width))
	button.add_theme_stylebox_override("pressed", _make_icon_style(Color.WHITE, bg_color.lightened(0.14), maxi(border_width, 3)))
	button.add_theme_stylebox_override("focus", _make_icon_style(Color.WHITE, bg_color.lightened(0.05), maxi(border_width, 3)))

func _make_icon_style(border_color: Color, bg_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style

func _get_slot_symbol(slot_id: String) -> String:
	match slot_id:
		"weapon":
			return "杖"
		"helmet":
			return "盔"
		"armor":
			return "甲"
		"boots":
			return "靴"
		"necklace":
			return "链"
		"ring":
			return "戒"
	return "装"

func _get_current_equipment_for(equipment: Dictionary) -> Dictionary:
	var slot_id := str(equipment.get("slot", "weapon"))
	return equipped_items.get(slot_id, {})
