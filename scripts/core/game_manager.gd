extends Node

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

signal gold_changed(total: int)
signal enemy_killed(total: int)
signal health_changed(current: int, maximum: int)
signal experience_changed(current: int, required: int, level: int)
signal equipment_changed(equipment: Dictionary)
signal loot_message_changed(message: String)
signal equipment_choice_requested(candidate: Dictionary, current: Dictionary, salvage_value: int)
signal inventory_changed(items: Array)
signal inventory_open_changed(is_open: bool)
signal upgrade_choices_requested(choices: Array)
signal run_ended(kills: int, gold: int)

var gold: int = 0
var kills: int = 0
var level: int = 1
var experience: int = 0
var experience_to_next_level: int = 5
var player_health: int = 0
var player_max_health: int = 0
var player: Node = null
var is_run_over: bool = false
var is_upgrade_pending: bool = false
var is_equipment_choice_pending: bool = false
var is_inventory_open: bool = false
var pending_upgrade_choices: Array = []
var pending_equipment_choice: Dictionary = {}
var pending_equipment_salvage_value: int = 0
var inventory: Array[Dictionary] = []
var equipped_weapon: Dictionary = {}
var latest_loot_message: String = ""

const UPGRADE_POOL := [
	{
		"id": "damage",
		"title": "强化弹体",
		"description": "投射物伤害 +5"
	},
	{
		"id": "attack_speed",
		"title": "快速施放",
		"description": "射击间隔缩短 18%"
	},
	{
		"id": "move_speed",
		"title": "迅捷步伐",
		"description": "移动速度 +35"
	},
	{
		"id": "max_health",
		"title": "生命强化",
		"description": "最大生命 +25，并回复 25 生命"
	},
	{
		"id": "heal",
		"title": "喘息之机",
		"description": "回复 40 生命"
	},
	{
		"id": "multishot",
		"title": "分裂射击",
		"description": "每次攻击投射物 +1"
	}
]

func reset_run() -> void:
	gold = 0
	kills = 0
	level = 1
	experience = 0
	experience_to_next_level = 5
	player_health = 0
	player_max_health = 0
	player = null
	is_run_over = false
	is_upgrade_pending = false
	is_equipment_choice_pending = false
	is_inventory_open = false
	pending_upgrade_choices.clear()
	pending_equipment_choice.clear()
	pending_equipment_salvage_value = 0
	inventory.clear()
	equipped_weapon.clear()
	latest_loot_message = ""
	gold_changed.emit(gold)
	enemy_killed.emit(kills)
	experience_changed.emit(experience, experience_to_next_level, level)
	inventory_changed.emit(inventory)
	inventory_open_changed.emit(is_inventory_open)
	equipment_changed.emit(equipped_weapon)
	loot_message_changed.emit(latest_loot_message)

func register_player(player_node: Node) -> void:
	player = player_node
	if player.has_method("sync_health_state"):
		player.sync_health_state()

func update_player_health(current: int, maximum: int) -> void:
	player_health = current
	player_max_health = maximum
	health_changed.emit(current, maximum)

func add_gold(amount: int) -> void:
	if is_run_over:
		return
	gold += amount
	gold_changed.emit(gold)
	_set_loot_message("金币 +%d" % amount)

func pickup_equipment(equipment: Dictionary) -> void:
	if is_run_over or equipment.is_empty():
		return
	inventory.append(equipment.duplicate(true))
	_sort_inventory()
	inventory_changed.emit(inventory)
	_set_loot_message("已放入背包：%s" % equipment["name"])

func toggle_inventory_open() -> void:
	if is_run_over or is_upgrade_pending:
		return
	set_inventory_open(not is_inventory_open)

func set_inventory_open(open: bool) -> void:
	if is_run_over:
		open = false
	if is_upgrade_pending and open:
		return
	if is_inventory_open == open:
		return
	is_inventory_open = open
	inventory_open_changed.emit(is_inventory_open)

func equip_inventory_equipment(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var new_weapon := inventory[index].duplicate(true)
	inventory.remove_at(index)
	var old_weapon := equipped_weapon.duplicate(true)
	if not old_weapon.is_empty():
		inventory.append(old_weapon)
	equipped_weapon = new_weapon
	if player != null and player.has_method("equip_weapon"):
		player.equip_weapon(equipped_weapon, old_weapon)
	_sort_inventory()
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipped_weapon)
	if old_weapon.is_empty():
		_set_loot_message("已装备：%s" % equipped_weapon["name"])
	else:
		_set_loot_message("已装备：%s，旧武器放入背包" % equipped_weapon["name"])

func salvage_inventory_equipment(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var equipment := inventory[index]
	var value := EquipmentFactory.get_salvage_value(equipment)
	var salvaged_name := str(equipment["name"])
	inventory.remove_at(index)
	gold += value
	gold_changed.emit(gold)
	inventory_changed.emit(inventory)
	_set_loot_message("已分解：%s，金币 +%d" % [salvaged_name, value])

func get_inventory_items() -> Array:
	return inventory.duplicate(true)

func get_inventory_count() -> int:
	return inventory.size()

func _legacy_pickup_equipment_choice(equipment: Dictionary) -> void:
	is_equipment_choice_pending = true
	pending_equipment_choice = equipment.duplicate(true)
	pending_equipment_salvage_value = _calculate_salvage_value(pending_equipment_choice)
	_set_loot_message("发现武器：%s" % pending_equipment_choice["name"])
	equipment_choice_requested.emit(pending_equipment_choice, equipped_weapon, pending_equipment_salvage_value)

func equip_pending_equipment() -> void:
	if is_run_over or pending_equipment_choice.is_empty():
		return
	var old_weapon := equipped_weapon.duplicate(true)
	equipped_weapon = pending_equipment_choice.duplicate(true)
	if player != null and player.has_method("equip_weapon"):
		player.equip_weapon(equipped_weapon, old_weapon)
	equipment_changed.emit(equipped_weapon)
	_set_loot_message("已装备：%s" % equipped_weapon["name"])
	_clear_pending_equipment_choice()

func salvage_pending_equipment() -> void:
	if is_run_over or pending_equipment_choice.is_empty():
		return
	var salvaged_name := str(pending_equipment_choice["name"])
	var value := pending_equipment_salvage_value
	_clear_pending_equipment_choice()
	gold += value
	gold_changed.emit(gold)
	_set_loot_message("已分解：%s，金币 +%d" % [salvaged_name, value])

func register_kill() -> void:
	if is_run_over:
		return
	kills += 1
	enemy_killed.emit(kills)

func add_experience(amount: int) -> void:
	if is_run_over:
		return
	experience += amount
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = int(ceil(float(experience_to_next_level) * 1.35 + 2.0))
		_request_upgrade_choices()
	experience_changed.emit(experience, experience_to_next_level, level)

func apply_upgrade(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= pending_upgrade_choices.size():
		return
	var upgrade: Dictionary = pending_upgrade_choices[choice_index]
	pending_upgrade_choices.clear()
	is_upgrade_pending = false
	if player != null and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade["id"])

func is_gameplay_paused() -> bool:
	return is_upgrade_pending or is_equipment_choice_pending or is_inventory_open

func end_run() -> void:
	if is_run_over:
		return
	is_run_over = true
	set_inventory_open(false)
	run_ended.emit(kills, gold)

func _request_upgrade_choices() -> void:
	is_upgrade_pending = true
	var pool := UPGRADE_POOL.duplicate(true)
	pool.shuffle()
	pending_upgrade_choices.clear()
	for index in range(min(3, pool.size())):
		pending_upgrade_choices.append(pool[index])
	upgrade_choices_requested.emit(pending_upgrade_choices)

func _set_loot_message(message: String) -> void:
	latest_loot_message = message
	loot_message_changed.emit(latest_loot_message)

func _clear_pending_equipment_choice() -> void:
	pending_equipment_choice.clear()
	pending_equipment_salvage_value = 0
	is_equipment_choice_pending = false

func _calculate_salvage_value(equipment: Dictionary) -> int:
	return EquipmentFactory.get_salvage_value(equipment)

func _sort_inventory() -> void:
	inventory.sort_custom(_is_inventory_item_before)

func _is_inventory_item_before(left: Dictionary, right: Dictionary) -> bool:
	return EquipmentFactory.should_sort_before(left, right)
