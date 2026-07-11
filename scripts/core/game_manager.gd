extends Node

signal gold_changed(total: int)
signal enemy_killed(total: int)
signal health_changed(current: int, maximum: int)
signal experience_changed(current: int, required: int, level: int)
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
var pending_upgrade_choices: Array = []

const UPGRADE_POOL := [
	{
		"id": "damage",
		"title": "Stronger Shots",
		"description": "+5 projectile damage"
	},
	{
		"id": "attack_speed",
		"title": "Faster Casting",
		"description": "Shoot 18% faster"
	},
	{
		"id": "move_speed",
		"title": "Swift Boots",
		"description": "+35 movement speed"
	},
	{
		"id": "max_health",
		"title": "Vitality",
		"description": "+25 max health and heal 25"
	},
	{
		"id": "heal",
		"title": "Second Wind",
		"description": "Restore 40 health"
	},
	{
		"id": "multishot",
		"title": "Split Shot",
		"description": "+1 projectile per attack"
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
	pending_upgrade_choices.clear()
	gold_changed.emit(gold)
	enemy_killed.emit(kills)
	experience_changed.emit(experience, experience_to_next_level, level)

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

func end_run() -> void:
	if is_run_over:
		return
	is_run_over = true
	run_ended.emit(kills, gold)

func _request_upgrade_choices() -> void:
	is_upgrade_pending = true
	var pool := UPGRADE_POOL.duplicate(true)
	pool.shuffle()
	pending_upgrade_choices.clear()
	for index in range(min(3, pool.size())):
		pending_upgrade_choices.append(pool[index])
	upgrade_choices_requested.emit(pending_upgrade_choices)
