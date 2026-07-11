extends CanvasLayer

var gold_label: Label
var kills_label: Label
var health_label: Label
var experience_label: Label
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

	upgrade_panel = PanelContainer.new()
	upgrade_panel.visible = false
	upgrade_panel.position = Vector2(390, 150)
	upgrade_panel.custom_minimum_size = Vector2(500, 260)
	root.add_child(upgrade_panel)

	upgrade_list = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 10)
	upgrade_panel.add_child(upgrade_list)

	var title := Label.new()
	title.text = "Level Up - Choose One"
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
	GameManager.upgrade_choices_requested.connect(_on_upgrade_choices_requested)
	GameManager.run_ended.connect(_on_run_ended)

func _refresh_all() -> void:
	_on_gold_changed(GameManager.gold)
	_on_enemy_killed(GameManager.kills)
	_on_experience_changed(GameManager.experience, GameManager.experience_to_next_level, GameManager.level)
	_on_health_changed(GameManager.player_health, GameManager.player_max_health)

func _on_gold_changed(total: int) -> void:
	gold_label.text = "Gold: %d" % total

func _on_enemy_killed(total: int) -> void:
	kills_label.text = "Kills: %d" % total

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP: %d / %d" % [current, maximum]

func _on_experience_changed(current: int, required: int, level: int) -> void:
	experience_label.text = "Level %d  XP: %d / %d" % [level, current, required]

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
	game_over_label.text = "Run Over\nKills: %d\nGold: %d" % [kills, gold]
