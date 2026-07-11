extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

@export var spawn_radius: float = 460.0
@export var minimum_spawn_radius: float = 360.0
@export var spawn_interval_reduction_per_level: float = 0.04
@export var minimum_spawn_interval: float = 0.55

var player: CharacterBody2D

func _ready() -> void:
	GameManager.reset_run()
	enemy_spawn_timer.wait_time = 1.25
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
	enemy.global_position = _random_spawn_position_around(player.global_position, spawn_radius)
	add_child(enemy)
	_update_spawn_interval()

func _random_spawn_position_around(center: Vector2, radius: float) -> Vector2:
	var angle := randf() * TAU
	var spawn_distance := randf_range(minimum_spawn_radius, radius)
	var viewport_size := get_viewport_rect().size
	var position := center + Vector2(cos(angle), sin(angle)) * spawn_distance
	position.x = clampf(position.x, 24.0, viewport_size.x - 24.0)
	position.y = clampf(position.y, 24.0, viewport_size.y - 24.0)
	return position

func _on_run_ended(_kills: int, _gold: int) -> void:
	enemy_spawn_timer.stop()

func _update_spawn_interval() -> void:
	var target_interval := maxf(minimum_spawn_interval, 1.25 - (GameManager.level - 1) * spawn_interval_reduction_per_level)
	enemy_spawn_timer.wait_time = target_interval
