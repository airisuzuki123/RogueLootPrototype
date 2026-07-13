extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemy_projectile.tscn")

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
@onready var arena_pattern_timer: Timer = $ArenaPatternTimer
@onready var arena_bounds: Node2D = $ArenaBounds

@export var spawn_radius: float = 460.0
@export var minimum_spawn_radius: float = 360.0
@export var spawn_interval_reduction_per_level: float = 0.04
@export var minimum_spawn_interval: float = 0.55

var player: CharacterBody2D
var enemy_spawn_table: Array[Dictionary] = [
	{"type": "grunt", "weight": 36, "min_level": 1},
	{"type": "runner", "weight": 16, "min_level": 1},
	{"type": "tank", "weight": 12, "min_level": 2},
	{"type": "ranged", "weight": 26, "min_level": 1},
	{"type": "weaver", "weight": 12, "min_level": 2},
	{"type": "turret", "weight": 8, "min_level": 3}
]

func _ready() -> void:
	GameManager.reset_run()
	enemy_spawn_timer.wait_time = 1.25
	_spawn_player()
	_spawn_hud()
	enemy_spawn_timer.timeout.connect(_spawn_enemy)
	arena_pattern_timer.timeout.connect(_spawn_arena_pattern)
	GameManager.run_phase_changed.connect(_on_run_phase_changed)
	GameManager.run_ended.connect(_on_run_ended)
	_update_arena_pattern_interval()

func _process(delta: float) -> void:
	GameManager.update_run_time(delta)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = _get_arena_center()
	add_child(player)
	if player.has_method("set_movement_bounds"):
		player.set_movement_bounds(_get_arena_rect())
	GameManager.register_player(player)

func _spawn_hud() -> void:
	var hud := HUD_SCENE.instantiate()
	add_child(hud)

func _spawn_enemy() -> void:
	if player == null or not is_instance_valid(player) or GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	var spawn_count := GameManager.get_current_phase_spawn_count()
	for index in range(spawn_count):
		_spawn_single_enemy()
	_update_spawn_interval()

func _spawn_single_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	enemy.configure(_roll_enemy_type())
	enemy.target = player
	enemy.global_position = _random_spawn_position_around(player.global_position, spawn_radius)
	if enemy.has_method("set_movement_bounds"):
		enemy.set_movement_bounds(_get_arena_rect())
	add_child(enemy)

func _random_spawn_position_around(center: Vector2, radius: float) -> Vector2:
	var spawn_rect := _get_spawn_rect()
	for attempt in range(18):
		var angle := randf() * TAU
		var spawn_distance := randf_range(minimum_spawn_radius, radius)
		var position := center + Vector2(cos(angle), sin(angle)) * spawn_distance
		if spawn_rect.has_point(position):
			return position
	return _random_position_on_arena_edge(center, spawn_rect)

func _on_run_ended(_kills: int, _gold: int) -> void:
	enemy_spawn_timer.stop()
	arena_pattern_timer.stop()

func _on_run_phase_changed(_phase: Dictionary) -> void:
	_update_spawn_interval()
	_update_arena_pattern_interval()

func _update_spawn_interval() -> void:
	var phase_interval := GameManager.get_current_phase_spawn_interval()
	var target_interval := maxf(minimum_spawn_interval, phase_interval - (GameManager.level - 1) * spawn_interval_reduction_per_level)
	enemy_spawn_timer.wait_time = target_interval

func _update_arena_pattern_interval() -> void:
	var phase := GameManager.get_current_run_phase()
	var interval := float(phase.get("arena_pattern_interval", 0.0))
	if interval <= 0.0:
		arena_pattern_timer.stop()
		return
	arena_pattern_timer.wait_time = interval
	arena_pattern_timer.start()

func _roll_enemy_type() -> String:
	var available: Array[Dictionary] = []
	var total_weight := 0
	var effective_level := GameManager.level + GameManager.get_current_phase_enemy_level_bonus()
	for entry in enemy_spawn_table:
		if effective_level < int(entry["min_level"]):
			continue
		available.append(entry)
		total_weight += int(entry["weight"]) + GameManager.get_current_phase_enemy_weight_bonus(str(entry["type"]))
	var roll := randi_range(1, max(1, total_weight))
	var cursor := 0
	for entry in available:
		cursor += int(entry["weight"]) + GameManager.get_current_phase_enemy_weight_bonus(str(entry["type"]))
		if roll <= cursor:
			return str(entry["type"])
	return "grunt"

func _spawn_arena_pattern() -> void:
	if player == null or not is_instance_valid(player) or GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	var phase := GameManager.get_current_run_phase()
	var patterns: Array = phase.get("arena_patterns", [])
	if patterns.is_empty():
		return
	match str(patterns.pick_random()):
		"cross_curtain":
			_fire_cross_curtain()
		"alternating_curtain":
			_fire_alternating_curtain()
		"corner_pinwheel":
			_fire_corner_pinwheel()
		_:
			_fire_side_curtain(randi_range(0, 3), 10, 2)

func _fire_cross_curtain() -> void:
	var first_side := randi_range(0, 3)
	_fire_side_curtain(first_side, 10, 2)
	_fire_side_curtain((first_side + 1) % 4, 10, 2)

func _fire_alternating_curtain() -> void:
	var first_side := randi_range(0, 1)
	_fire_side_curtain(first_side, 12, 2)
	_fire_side_curtain(first_side + 2, 12, 2)

func _fire_corner_pinwheel() -> void:
	var rect := _get_spawn_rect()
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	var center := _get_arena_center()
	for corner_index in range(corners.size()):
		var corner: Vector2 = corners[corner_index]
		var base_direction := corner.direction_to(center)
		for index in range(5):
			var angle := deg_to_rad((float(index) - 2.0) * 13.0)
			_spawn_arena_projectile(corner, base_direction.rotated(angle), Color(1.0, 0.36, 0.9, 1.0), 0.78, 0.88)

func _fire_side_curtain(side: int, bullet_count: int, gap_width: int) -> void:
	var gap_index := randi_range(1, maxi(1, bullet_count - gap_width - 1))
	for index in range(bullet_count):
		if index >= gap_index and index < gap_index + gap_width:
			continue
		var data := _get_side_projectile_spawn(side, index, bullet_count)
		var position: Vector2 = data["position"]
		var direction: Vector2 = data["direction"]
		_spawn_arena_projectile(position, direction, Color(0.38, 0.78, 1.0, 1.0), 0.82, 0.9)

func _get_side_projectile_spawn(side: int, index: int, bullet_count: int) -> Dictionary:
	var rect := _get_spawn_rect()
	var t := 0.5 if bullet_count <= 1 else float(index) / float(bullet_count - 1)
	match side:
		0:
			return {
				"position": Vector2(lerpf(rect.position.x, rect.end.x, t), rect.position.y),
				"direction": Vector2.DOWN
			}
		1:
			return {
				"position": Vector2(rect.end.x, lerpf(rect.position.y, rect.end.y, t)),
				"direction": Vector2.LEFT
			}
		2:
			return {
				"position": Vector2(lerpf(rect.position.x, rect.end.x, t), rect.end.y),
				"direction": Vector2.UP
			}
	return {
		"position": Vector2(rect.position.x, lerpf(rect.position.y, rect.end.y, t)),
		"direction": Vector2.RIGHT
	}

func _spawn_arena_projectile(position: Vector2, direction: Vector2, color: Color, scale_multiplier: float, speed_scale: float) -> void:
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
	projectile.global_position = position
	var speed := 230.0 * GameManager.get_current_phase_bullet_speed_multiplier() * speed_scale
	if projectile.has_method("configure"):
		projectile.configure(direction, 7, speed, color, scale_multiplier)
	else:
		projectile.direction = direction
		projectile.damage = 7
	projectile.lifetime = 5.0
	add_child(projectile)

func _get_arena_rect() -> Rect2:
	if arena_bounds != null and arena_bounds.has_method("get_arena_rect"):
		return arena_bounds.get_arena_rect()
	var viewport_rect := get_viewport_rect()
	return Rect2(Vector2.ZERO, viewport_rect.size)

func _get_spawn_rect() -> Rect2:
	if arena_bounds != null and arena_bounds.has_method("get_spawn_rect"):
		return arena_bounds.get_spawn_rect(28.0)
	return _get_arena_rect().grow(-28.0)

func _get_arena_center() -> Vector2:
	var rect := _get_arena_rect()
	return rect.position + rect.size * 0.5

func _random_position_on_arena_edge(center: Vector2, spawn_rect: Rect2) -> Vector2:
	var side := randi_range(0, 3)
	var position := Vector2.ZERO
	match side:
		0:
			position = Vector2(randf_range(spawn_rect.position.x, spawn_rect.end.x), spawn_rect.position.y)
		1:
			position = Vector2(spawn_rect.end.x, randf_range(spawn_rect.position.y, spawn_rect.end.y))
		2:
			position = Vector2(randf_range(spawn_rect.position.x, spawn_rect.end.x), spawn_rect.end.y)
		_:
			position = Vector2(spawn_rect.position.x, randf_range(spawn_rect.position.y, spawn_rect.end.y))
	if position.distance_to(center) < minimum_spawn_radius:
		var fallback_direction := center.direction_to(position)
		if fallback_direction.is_zero_approx():
			fallback_direction = Vector2.RIGHT.rotated(randf() * TAU)
		position = center + fallback_direction * minimum_spawn_radius
		position.x = clampf(position.x, spawn_rect.position.x, spawn_rect.end.x)
		position.y = clampf(position.y, spawn_rect.position.y, spawn_rect.end.y)
	return position
