extends Node

signal gold_changed(total: int)
signal enemy_killed(total: int)

var gold: int = 0
var kills: int = 0

func reset_run() -> void:
	gold = 0
	kills = 0
	gold_changed.emit(gold)
	enemy_killed.emit(kills)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func register_kill() -> void:
	kills += 1
	enemy_killed.emit(kills)

