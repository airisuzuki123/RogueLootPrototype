extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

var player: CharacterBody2D

func _ready() -> void:
	GameManager.reset_run()
	_spawn_player()
	enemy_spawn_timer.timeout.connect(_spawn_enemy)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(640, 360)
	add_child(player)

func _spawn_enemy() -> void:
	if player == null:
		return
	var enemy := ENEMY_SCENE.instantiate()
	enemy.target = player
	enemy.global_position = _random_spawn_position_around(player.global_position, 420.0)
	add_child(enemy)

func _random_spawn_position_around(center: Vector2, radius: float) -> Vector2:
	var angle := randf() * TAU
	return center + Vector2(cos(angle), sin(angle)) * radius

