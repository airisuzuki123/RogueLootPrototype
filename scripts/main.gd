extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

var player: CharacterBody2D

func _ready() -> void:
	GameManager.reset_run()
	_spawn_player()
	_spawn_hud()
	enemy_spawn_timer.timeout.connect(_spawn_enemy)
	GameManager.run_ended.connect(_on_run_ended)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(640, 360)
	add_child(player)
	GameManager.register_player(player)

func _spawn_hud() -> void:
	var hud := HUD_SCENE.instantiate()
	add_child(hud)

func _spawn_enemy() -> void:
	if player == null or not is_instance_valid(player) or GameManager.is_run_over or GameManager.is_upgrade_pending:
		return
	var enemy := ENEMY_SCENE.instantiate()
	enemy.target = player
	enemy.global_position = _random_spawn_position_around(player.global_position, 420.0)
	add_child(enemy)

func _random_spawn_position_around(center: Vector2, radius: float) -> Vector2:
	var angle := randf() * TAU
	return center + Vector2(cos(angle), sin(angle)) * radius

func _on_run_ended(_kills: int, _gold: int) -> void:
	enemy_spawn_timer.stop()
