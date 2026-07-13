extends Node

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

signal gold_changed(total: int)
signal enemy_killed(total: int)
signal health_changed(current: int, maximum: int)
signal experience_changed(current: int, required: int, level: int)
signal equipment_changed(equipped_items: Dictionary)
signal loot_message_changed(message: String)
signal equipment_choice_requested(candidate: Dictionary, current: Dictionary, salvage_value: int)
signal inventory_changed(items: Array)
signal inventory_open_changed(is_open: bool)
signal upgrade_choices_requested(choices: Array)
signal run_ended(kills: int, gold: int)
signal run_time_changed(elapsed_seconds: int, phase: Dictionary, remaining_seconds: int)
signal run_phase_changed(phase: Dictionary)
signal run_phase_objective_changed(phase: Dictionary, progress: int, target: int, completed: bool)
signal run_milestone_message_changed(message: String)

const MAX_INVENTORY_SIZE: int = 36
const RUN_PHASES: Array[Dictionary] = [
	{
		"id": "opening",
		"name": "初始清场",
		"duration": 45.0,
		"spawn_interval": 1.25,
		"spawn_count": 1,
		"enemy_level_bonus": 0,
		"enemy_weight_bonus": {"ranged": 10},
		"bullet_pattern": "aimed",
		"bullet_speed_multiplier": 0.88,
		"goal": "阅读直线弹道，积累经验球完成第一轮升级",
		"kill_target": 10,
		"reward_gold": 8,
		"reward_experience": 2,
		"reward_heal": 0
	},
	{
		"id": "chase",
		"name": "追击加压",
		"duration": 60.0,
		"spawn_interval": 1.05,
		"spawn_count": 1,
		"enemy_level_bonus": 0,
		"enemy_weight_bonus": {"runner": 8, "ranged": 28},
		"bullet_pattern": "fan",
		"bullet_speed_multiplier": 0.95,
		"goal": "穿过扇形弹幕，保持移动空间",
		"kill_target": 18,
		"reward_gold": 12,
		"reward_experience": 3,
		"reward_heal": 10
	},
	{
		"id": "mixed",
		"name": "混编压迫",
		"duration": 75.0,
		"spawn_interval": 0.90,
		"spawn_count": 1,
		"enemy_level_bonus": 1,
		"enemy_weight_bonus": {"tank": 8, "ranged": 34},
		"bullet_pattern": "ring",
		"bullet_speed_multiplier": 1.0,
		"goal": "观察环形弹幕缺口，处理远程压力",
		"kill_target": 26,
		"reward_gold": 16,
		"reward_experience": 4,
		"reward_heal": 15
	},
	{
		"id": "surge",
		"name": "密集来袭",
		"duration": 90.0,
		"spawn_interval": 0.75,
		"spawn_count": 2,
		"enemy_level_bonus": 1,
		"enemy_weight_bonus": {"runner": 8, "tank": 8, "ranged": 38},
		"bullet_pattern": "spiral",
		"bullet_speed_multiplier": 1.08,
		"goal": "预判旋转弹幕轨迹，保持输出空间",
		"kill_target": 40,
		"reward_gold": 24,
		"reward_experience": 5,
		"reward_heal": 20
	},
	{
		"id": "endless_pressure",
		"name": "终局试炼",
		"duration": 75.0,
		"spawn_interval": 0.65,
		"spawn_count": 2,
		"enemy_level_bonus": 2,
		"enemy_weight_bonus": {"runner": 10, "tank": 12, "ranged": 44},
		"bullet_pattern": "wall",
		"bullet_speed_multiplier": 1.15,
		"goal": "穿越弹幕墙，撑过最后一波压力",
		"kill_target": 60,
		"reward_gold": 35,
		"reward_experience": 6,
		"reward_heal": 25
	}
]

var gold: int = 0
var kills: int = 0
var level: int = 1
var experience: int = 0
var experience_to_next_level: int = 5
var player_health: int = 0
var player_max_health: int = 0
var player: Node = null
var is_run_over: bool = false
var is_run_completed: bool = false
var is_upgrade_pending: bool = false
var is_equipment_choice_pending: bool = false
var is_inventory_open: bool = false
var pending_upgrade_choices: Array = []
var pending_equipment_choice: Dictionary = {}
var pending_equipment_salvage_value: int = 0
var inventory: Array[Dictionary] = []
var equipped_items := {
	"weapon": {},
	"helmet": {},
	"armor": {},
	"boots": {},
	"necklace": {},
	"ring": {}
}
var latest_loot_message: String = ""
var latest_milestone_message: String = ""
var run_elapsed_time: float = 0.0
var current_phase_index: int = 0
var current_phase_kill_start: int = 0
var current_phase_objective_completed: bool = false
var current_phase_warning_sent: bool = false
var latest_run_time_second: int = -1

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
	is_run_completed = false
	is_upgrade_pending = false
	is_equipment_choice_pending = false
	is_inventory_open = false
	pending_upgrade_choices.clear()
	pending_equipment_choice.clear()
	pending_equipment_salvage_value = 0
	inventory.clear()
	_reset_equipped_items()
	latest_loot_message = ""
	latest_milestone_message = ""
	run_elapsed_time = 0.0
	current_phase_index = 0
	current_phase_kill_start = 0
	current_phase_objective_completed = false
	current_phase_warning_sent = false
	latest_run_time_second = -1
	gold_changed.emit(gold)
	enemy_killed.emit(kills)
	experience_changed.emit(experience, experience_to_next_level, level)
	inventory_changed.emit(inventory)
	inventory_open_changed.emit(is_inventory_open)
	equipment_changed.emit(equipped_items)
	loot_message_changed.emit(latest_loot_message)
	run_milestone_message_changed.emit(latest_milestone_message)
	run_phase_changed.emit(get_current_run_phase())
	_emit_run_time_changed(true)
	_emit_phase_objective_changed()

func update_run_time(delta: float) -> void:
	if is_run_over or is_gameplay_paused():
		return
	run_elapsed_time += delta
	_update_run_phase()
	if _is_run_duration_complete():
		run_elapsed_time = _get_total_run_duration()
		_emit_run_time_changed(true)
		complete_run()
		return
	_update_phase_warning()
	_emit_run_time_changed(false)

func get_current_run_phase() -> Dictionary:
	if RUN_PHASES.is_empty():
		return {}
	return RUN_PHASES[clampi(current_phase_index, 0, RUN_PHASES.size() - 1)].duplicate(true)

func get_current_phase_spawn_interval() -> float:
	return float(get_current_run_phase().get("spawn_interval", 1.25))

func get_current_phase_spawn_count() -> int:
	return maxi(1, int(get_current_run_phase().get("spawn_count", 1)))

func get_current_phase_enemy_level_bonus() -> int:
	return maxi(0, int(get_current_run_phase().get("enemy_level_bonus", 0)))

func get_current_phase_enemy_weight_bonus(enemy_type: String) -> int:
	var weight_bonus: Dictionary = get_current_run_phase().get("enemy_weight_bonus", {})
	return maxi(0, int(weight_bonus.get(enemy_type, 0)))

func get_current_phase_bullet_pattern() -> String:
	return str(get_current_run_phase().get("bullet_pattern", "aimed"))

func get_current_phase_bullet_speed_multiplier() -> float:
	return maxf(0.2, float(get_current_run_phase().get("bullet_speed_multiplier", 1.0)))

func get_run_elapsed_seconds() -> int:
	return int(floor(run_elapsed_time))

func get_current_phase_remaining_seconds() -> int:
	var phase := get_current_run_phase()
	var duration := float(phase.get("duration", -1.0))
	if duration < 0.0:
		return -1
	var phase_elapsed := run_elapsed_time - _get_phase_start_time(current_phase_index)
	return maxi(0, int(ceil(duration - phase_elapsed)))

func get_current_phase_objective_progress() -> int:
	return maxi(0, kills - current_phase_kill_start)

func get_current_phase_objective_target() -> int:
	return maxi(0, int(get_current_run_phase().get("kill_target", 0)))

func is_current_phase_objective_completed() -> bool:
	return current_phase_objective_completed

func get_next_run_phase() -> Dictionary:
	var next_index := current_phase_index + 1
	if next_index < 0 or next_index >= RUN_PHASES.size():
		return {}
	return RUN_PHASES[next_index].duplicate(true)

func register_player(player_node: Node) -> void:
	player = player_node
	if player.has_method("sync_health_state"):
		player.sync_health_state()

func update_player_health(current: int, maximum: int) -> void:
	player_health = current
	player_max_health = maximum
	health_changed.emit(current, maximum)

func add_gold(amount: int, apply_bonus: bool = true) -> int:
	if is_run_over:
		return 0
	var final_amount := amount
	if apply_bonus and player != null and player.has_method("get_gold_bonus_percent"):
		var bonus_percent := int(player.get_gold_bonus_percent())
		if bonus_percent > 0:
			final_amount += int(round(float(amount) * float(bonus_percent) / 100.0))
	final_amount = maxi(0, final_amount)
	gold += final_amount
	gold_changed.emit(gold)
	_set_loot_message("金币 +%d" % final_amount)
	return final_amount

func pickup_equipment(equipment: Dictionary) -> bool:
	if is_run_over or equipment.is_empty():
		return false
	if inventory.size() >= MAX_INVENTORY_SIZE:
		_set_loot_message("背包已满，无法拾取：%s" % equipment["name"])
		return false
	inventory.append(equipment.duplicate(true))
	_sort_inventory()
	inventory_changed.emit(inventory)
	_set_loot_message("已放入背包：%s" % equipment["name"])
	return true

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
	var new_equipment := inventory[index].duplicate(true)
	var slot_id := str(new_equipment.get("slot", "weapon"))
	inventory.remove_at(index)
	var old_equipment: Dictionary = equipped_items.get(slot_id, {}).duplicate(true)
	if not old_equipment.is_empty():
		inventory.append(old_equipment)
	equipped_items[slot_id] = new_equipment
	if player != null and player.has_method("equip_item"):
		player.equip_item(new_equipment, old_equipment)
	elif player != null and player.has_method("equip_weapon"):
		player.equip_weapon(new_equipment, old_equipment)
	_sort_inventory()
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipped_items)
	if old_equipment.is_empty():
		_set_loot_message("已装备：%s" % new_equipment["name"])
	else:
		_set_loot_message("已装备：%s，原%s放入背包" % [new_equipment["name"], EquipmentFactory.get_slot_label(slot_id)])

func unequip_item(slot_id: String) -> bool:
	if not equipped_items.has(slot_id):
		return false
	var equipment: Dictionary = equipped_items.get(slot_id, {}).duplicate(true)
	if equipment.is_empty():
		_set_loot_message("%s槽位为空" % EquipmentFactory.get_slot_label(slot_id))
		return false
	if inventory.size() >= MAX_INVENTORY_SIZE:
		_set_loot_message("背包已满，无法卸下：%s" % equipment["name"])
		return false
	equipped_items[slot_id] = {}
	inventory.append(equipment)
	if player != null and player.has_method("equip_item"):
		player.equip_item({}, equipment)
	elif player != null and player.has_method("equip_weapon"):
		player.equip_weapon({}, equipment)
	_sort_inventory()
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipped_items)
	_set_loot_message("已卸下：%s" % equipment["name"])
	return true

func salvage_inventory_equipment(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var equipment := inventory[index]
	var value := EquipmentFactory.get_salvage_value(equipment)
	var salvaged_name := str(equipment["name"])
	inventory.remove_at(index)
	var gained_gold := add_gold(value)
	inventory_changed.emit(inventory)
	_set_loot_message("已分解：%s，金币 +%d" % [salvaged_name, gained_gold])

func salvage_inventory_by_rarity(rarity_name: String) -> void:
	salvage_inventory_by_rarities([rarity_name])

func salvage_inventory_by_rarities(rarity_names: Array) -> void:
	if rarity_names.is_empty():
		_set_loot_message("请选择要分解的品质")
		return
	var kept_items: Array[Dictionary] = []
	var total_value := 0
	var salvaged_count := 0
	for equipment in inventory:
		if rarity_names.has(str(equipment.get("rarity", ""))):
			total_value += EquipmentFactory.get_salvage_value(equipment)
			salvaged_count += 1
		else:
			kept_items.append(equipment)
	if salvaged_count <= 0:
		_set_loot_message("没有可分解的指定品质装备")
		return
	inventory = kept_items
	_sort_inventory()
	var gained_gold := add_gold(total_value)
	inventory_changed.emit(inventory)
	_set_loot_message("已分解%d件装备，金币 +%d" % [salvaged_count, gained_gold])

func get_inventory_items() -> Array:
	return inventory.duplicate(true)

func get_inventory_count() -> int:
	return inventory.size()

func get_inventory_capacity() -> int:
	return MAX_INVENTORY_SIZE

func get_equipped_item(slot_id: String) -> Dictionary:
	return equipped_items.get(slot_id, {}).duplicate(true)

func _legacy_pickup_equipment_choice(equipment: Dictionary) -> void:
	is_equipment_choice_pending = true
	pending_equipment_choice = equipment.duplicate(true)
	pending_equipment_salvage_value = _calculate_salvage_value(pending_equipment_choice)
	var slot_id := str(pending_equipment_choice.get("slot", "weapon"))
	_set_loot_message("发现装备：%s" % pending_equipment_choice["name"])
	equipment_choice_requested.emit(pending_equipment_choice, get_equipped_item(slot_id), pending_equipment_salvage_value)

func equip_pending_equipment() -> void:
	if is_run_over or pending_equipment_choice.is_empty():
		return
	var new_equipment := pending_equipment_choice.duplicate(true)
	var slot_id := str(new_equipment.get("slot", "weapon"))
	var old_equipment: Dictionary = equipped_items.get(slot_id, {}).duplicate(true)
	equipped_items[slot_id] = new_equipment
	if player != null and player.has_method("equip_item"):
		player.equip_item(new_equipment, old_equipment)
	elif player != null and player.has_method("equip_weapon"):
		player.equip_weapon(new_equipment, old_equipment)
	equipment_changed.emit(equipped_items)
	_set_loot_message("已装备：%s" % new_equipment["name"])
	_clear_pending_equipment_choice()

func salvage_pending_equipment() -> void:
	if is_run_over or pending_equipment_choice.is_empty():
		return
	var salvaged_name := str(pending_equipment_choice["name"])
	var value := pending_equipment_salvage_value
	_clear_pending_equipment_choice()
	var gained_gold := add_gold(value)
	_set_loot_message("已分解：%s，金币 +%d" % [salvaged_name, gained_gold])

func register_kill() -> void:
	if is_run_over:
		return
	kills += 1
	enemy_killed.emit(kills)
	_update_current_phase_objective()

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

func end_run(completed: bool = false) -> void:
	if is_run_over:
		return
	is_run_over = true
	is_run_completed = completed
	set_inventory_open(false)
	if completed:
		_set_milestone_message("试炼完成")
	run_ended.emit(kills, gold)

func complete_run() -> void:
	end_run(true)

func _update_run_phase() -> void:
	var new_phase_index := _get_phase_index_for_time(run_elapsed_time)
	if new_phase_index == current_phase_index:
		return
	current_phase_index = new_phase_index
	current_phase_kill_start = kills
	current_phase_objective_completed = false
	current_phase_warning_sent = false
	var phase := get_current_run_phase()
	run_phase_changed.emit(phase)
	var message := "进入阶段：%s - %s" % [str(phase.get("name", "未知阶段")), str(phase.get("goal", ""))]
	_set_loot_message(message)
	_set_milestone_message(message)
	_emit_run_time_changed(true)
	_emit_phase_objective_changed()

func _update_current_phase_objective() -> void:
	if current_phase_objective_completed:
		return
	var target := get_current_phase_objective_target()
	if target <= 0:
		return
	var progress := get_current_phase_objective_progress()
	if progress < target:
		_emit_phase_objective_changed()
		return
	current_phase_objective_completed = true
	_apply_phase_objective_reward()
	_emit_phase_objective_changed()

func _apply_phase_objective_reward() -> void:
	var phase := get_current_run_phase()
	var reward_parts: Array[String] = []
	var reward_gold := maxi(0, int(phase.get("reward_gold", 0)))
	var reward_experience := maxi(0, int(phase.get("reward_experience", 0)))
	var reward_heal := maxi(0, int(phase.get("reward_heal", 0)))
	if reward_gold > 0:
		var gained_gold := add_gold(reward_gold)
		reward_parts.append("金币 +%d" % gained_gold)
	if reward_experience > 0:
		add_experience(reward_experience)
		reward_parts.append("经验 +%d" % reward_experience)
	if reward_heal > 0 and player != null and player.has_method("heal_fixed_amount"):
		var healed_amount := int(player.heal_fixed_amount(reward_heal))
		if healed_amount > 0:
			reward_parts.append("生命 +%d" % healed_amount)
	var reward_text := "，".join(reward_parts) if not reward_parts.is_empty() else "无额外奖励"
	var message := "阶段目标完成：%s，%s" % [str(phase.get("name", "未知阶段")), reward_text]
	_set_loot_message(message)
	_set_milestone_message(message)

func _update_phase_warning() -> void:
	if current_phase_warning_sent:
		return
	var remaining_seconds := get_current_phase_remaining_seconds()
	if remaining_seconds < 0 or remaining_seconds > 10:
		return
	current_phase_warning_sent = true
	var next_phase := get_next_run_phase()
	var message := ""
	if next_phase.is_empty():
		message = "终局试炼即将完成，坚持最后 %d 秒" % remaining_seconds
	else:
		message = "%d 秒后进入：%s" % [remaining_seconds, str(next_phase.get("name", "下一阶段"))]
	_set_milestone_message(message)

func _get_phase_index_for_time(elapsed_time: float) -> int:
	var cursor := 0.0
	for index in range(RUN_PHASES.size()):
		var duration := float(RUN_PHASES[index].get("duration", -1.0))
		if duration < 0.0:
			return index
		cursor += duration
		if elapsed_time < cursor:
			return index
	return maxi(0, RUN_PHASES.size() - 1)

func _is_run_duration_complete() -> bool:
	var total_duration := _get_total_run_duration()
	return total_duration >= 0.0 and run_elapsed_time >= total_duration

func _get_total_run_duration() -> float:
	var total_duration := 0.0
	for phase in RUN_PHASES:
		var duration := float(phase.get("duration", -1.0))
		if duration < 0.0:
			return -1.0
		total_duration += duration
	return total_duration

func _get_phase_start_time(phase_index: int) -> float:
	var cursor := 0.0
	for index in range(mini(phase_index, RUN_PHASES.size())):
		var duration := float(RUN_PHASES[index].get("duration", -1.0))
		if duration < 0.0:
			return cursor
		cursor += duration
	return cursor

func _emit_run_time_changed(force: bool) -> void:
	var elapsed_seconds := get_run_elapsed_seconds()
	if not force and elapsed_seconds == latest_run_time_second:
		return
	latest_run_time_second = elapsed_seconds
	run_time_changed.emit(elapsed_seconds, get_current_run_phase(), get_current_phase_remaining_seconds())

func _emit_phase_objective_changed() -> void:
	run_phase_objective_changed.emit(
		get_current_run_phase(),
		get_current_phase_objective_progress(),
		get_current_phase_objective_target(),
		current_phase_objective_completed
	)

func _request_upgrade_choices() -> void:
	is_upgrade_pending = true
	var pool := UPGRADE_POOL.duplicate(true)
	var form_upgrade := _get_current_form_upgrade_choice()
	if not form_upgrade.is_empty():
		pool.append(form_upgrade)
	pool.shuffle()
	pending_upgrade_choices.clear()
	for index in range(min(3, pool.size())):
		pending_upgrade_choices.append(pool[index])
	upgrade_choices_requested.emit(pending_upgrade_choices)

func _get_current_form_upgrade_choice() -> Dictionary:
	var weapon: Dictionary = equipped_items.get("weapon", {})
	var form: Dictionary = weapon.get("form", {})
	match str(form.get("id", "")):
		"focused":
			return {
				"id": "form_focused",
				"title": "聚能专精",
				"description": "当前武器为聚能法杖：投射物伤害 +8"
			}
		"scatter":
			return {
				"id": "form_scatter",
				"title": "散射专精",
				"description": "当前武器为散射法杖：每次攻击投射物 +1"
			}
		"piercing":
			return {
				"id": "form_piercing",
				"title": "穿透专精",
				"description": "当前武器为穿透法杖：投射物穿透 +1"
			}
		"burst":
			return {
				"id": "form_burst",
				"title": "爆裂专精",
				"description": "当前武器为爆裂法杖：爆裂范围 +28"
			}
	return {}

func _set_loot_message(message: String) -> void:
	latest_loot_message = message
	loot_message_changed.emit(latest_loot_message)

func _set_milestone_message(message: String) -> void:
	latest_milestone_message = message
	run_milestone_message_changed.emit(latest_milestone_message)

func _clear_pending_equipment_choice() -> void:
	pending_equipment_choice.clear()
	pending_equipment_salvage_value = 0
	is_equipment_choice_pending = false

func _calculate_salvage_value(equipment: Dictionary) -> int:
	return EquipmentFactory.get_salvage_value(equipment)

func _reset_equipped_items() -> void:
	equipped_items = _create_empty_equipped_items()

func _create_empty_equipped_items() -> Dictionary:
	var empty_items := {}
	for slot in EquipmentFactory.EQUIPMENT_SLOTS:
		empty_items[str(slot["id"])] = {}
	return empty_items

func _sort_inventory() -> void:
	inventory.sort_custom(_is_inventory_item_before)

func _is_inventory_item_before(left: Dictionary, right: Dictionary) -> bool:
	return EquipmentFactory.should_sort_before(left, right)
