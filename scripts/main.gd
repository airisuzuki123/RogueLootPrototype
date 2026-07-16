extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemy_projectile.tscn")
const CHEST_EVENT_SCENE := preload("res://scenes/chest_event.tscn")
const SHOP_EVENT_SCENE := preload("res://scenes/shop_event.tscn")
const CHOICE_EVENT_SCENE := preload("res://scenes/choice_event.tscn")

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
@onready var arena_pattern_timer: Timer = $ArenaPatternTimer
@onready var arena_warning_timer: Timer = $ArenaWarningTimer
@onready var arena_bounds: Node2D = $ArenaBounds
@onready var arena_warning: Node2D = $ArenaWarning

@export var spawn_radius: float = 460.0
@export var minimum_spawn_radius: float = 360.0
@export var spawn_interval_reduction_per_level: float = 0.025
@export var minimum_spawn_interval: float = 0.52
@export var arena_warning_duration: float = 0.75

var player: CharacterBody2D
var pending_arena_pattern: Dictionary = {}
var arena_pattern_index: int = 0
var enemy_spawn_table: Array[Dictionary] = [
	{"type": "grunt", "weight": 36, "min_level": 1},
	{"type": "runner", "weight": 16, "min_level": 1},
	{"type": "tank", "weight": 12, "min_level": 2},
	{"type": "ranged", "weight": 26, "min_level": 1},
	{"type": "weaver", "weight": 12, "min_level": 2},
	{"type": "turret", "weight": 8, "min_level": 3},
	{"type": "bulwark", "weight": 4, "min_level": 5}
]

func _ready() -> void:
	GameManager.reset_run()
	enemy_spawn_timer.wait_time = 1.25
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_spawn_player()
	_spawn_hud()
	enemy_spawn_timer.timeout.connect(_spawn_enemy)
	arena_pattern_timer.timeout.connect(_prepare_arena_pattern)
	arena_warning_timer.timeout.connect(_fire_pending_arena_pattern)
	GameManager.run_phase_changed.connect(_on_run_phase_changed)
	GameManager.run_ended.connect(_on_run_ended)
	GameManager.encounter_requested.connect(_on_encounter_requested)
	GameManager.stage_event_requested.connect(_on_stage_event_requested)
	GameManager.combat_cleanup_requested.connect(_on_combat_cleanup_requested)
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
	enemy.global_position = _random_spawn_position_around(player.global_position, _get_dynamic_spawn_radius())
	if enemy.has_method("set_movement_bounds"):
		enemy.set_movement_bounds(_get_arena_rect())
	add_child(enemy)

func _spawn_encounter_enemy(encounter: Dictionary) -> void:
	if player == null or not is_instance_valid(player) or GameManager.is_run_over:
		return
	var enemy := ENEMY_SCENE.instantiate()
	enemy.configure(str(encounter.get("enemy_type", "turret")))
	if enemy.has_method("configure_encounter"):
		enemy.configure_encounter(encounter)
	enemy.target = player
	enemy.global_position = _random_position_on_arena_edge(player.global_position, _get_spawn_rect())
	if enemy.has_method("set_movement_bounds"):
		enemy.set_movement_bounds(_get_arena_rect())
	add_child(enemy)

func _spawn_stage_event(event: Dictionary) -> void:
	if player == null or not is_instance_valid(player) or GameManager.is_run_over:
		return
	match str(event.get("kind", "")):
		"chest":
			var chest := CHEST_EVENT_SCENE.instantiate()
			if chest.has_method("configure"):
				chest.configure(event)
			chest.global_position = _random_stage_event_position()
			add_child(chest)
		"shop":
			var shop := SHOP_EVENT_SCENE.instantiate()
			if shop.has_method("configure"):
				shop.configure(event)
			shop.global_position = _random_stage_event_position()
			add_child(shop)
		"choice":
			var choice_event := CHOICE_EVENT_SCENE.instantiate()
			if choice_event.has_method("configure"):
				choice_event.configure(event)
			choice_event.global_position = _random_stage_event_position()
			add_child(choice_event)

func _random_spawn_position_around(center: Vector2, radius: float) -> Vector2:
	var spawn_rect := _get_spawn_rect()
	var minimum_distance := _get_dynamic_minimum_spawn_radius()
	for attempt in range(18):
		var angle := randf() * TAU
		var spawn_distance := randf_range(minimum_distance, radius)
		var position := center + Vector2(cos(angle), sin(angle)) * spawn_distance
		if spawn_rect.has_point(position):
			return position
	return _random_position_on_arena_edge(center, spawn_rect)

func _on_run_ended(_kills: int, _gold: int) -> void:
	enemy_spawn_timer.stop()
	arena_pattern_timer.stop()
	arena_warning_timer.stop()
	pending_arena_pattern.clear()
	if arena_warning.has_method("clear_warning"):
		arena_warning.clear_warning()
	_clear_active_combat_nodes()

func _on_run_phase_changed(_phase: Dictionary) -> void:
	arena_pattern_index = 0
	_update_spawn_interval()
	_update_arena_pattern_interval()
	if not enemy_spawn_timer.is_stopped():
		return
	enemy_spawn_timer.start()

func _on_encounter_requested(encounter: Dictionary) -> void:
	_spawn_encounter_enemy(encounter)

func _on_stage_event_requested(event: Dictionary) -> void:
	_spawn_stage_event(event)

func _on_combat_cleanup_requested() -> void:
	enemy_spawn_timer.stop()
	arena_pattern_timer.stop()
	arena_warning_timer.stop()
	pending_arena_pattern.clear()
	if arena_warning.has_method("clear_warning"):
		arena_warning.clear_warning()
	_clear_active_combat_nodes()

func _on_viewport_size_changed() -> void:
	if arena_bounds != null:
		arena_bounds.queue_redraw()
	var arena_rect := _get_arena_rect()
	if player != null and is_instance_valid(player) and player.has_method("set_movement_bounds"):
		player.set_movement_bounds(arena_rect)
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node != null and is_instance_valid(enemy_node) and enemy_node.has_method("set_movement_bounds"):
			enemy_node.set_movement_bounds(arena_rect)

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
		var entry_weight := maxi(0, int(entry["weight"]) + GameManager.get_current_phase_enemy_weight_bonus(str(entry["type"])))
		if entry_weight <= 0:
			continue
		var weighted_entry := entry.duplicate(true)
		weighted_entry["roll_weight"] = entry_weight
		available.append(weighted_entry)
		total_weight += entry_weight
	var roll := randi_range(1, max(1, total_weight))
	var cursor := 0
	for entry in available:
		cursor += int(entry.get("roll_weight", entry["weight"]))
		if roll <= cursor:
			return str(entry["type"])
	return "grunt"

func _prepare_arena_pattern() -> void:
	if player == null or not is_instance_valid(player) or GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	var phase := GameManager.get_current_run_phase()
	var patterns: Array = phase.get("arena_patterns", [])
	if patterns.is_empty():
		return
	var pattern_id := str(patterns[arena_pattern_index % patterns.size()])
	arena_pattern_index += 1
	pending_arena_pattern = _create_arena_pattern_plan(pattern_id)
	if pending_arena_pattern.is_empty():
		return
	if arena_warning.has_method("show_warning"):
		arena_warning.show_warning(_get_arena_warning_segments(pending_arena_pattern), arena_warning_duration)
	arena_warning_timer.start(arena_warning_duration)

func _fire_pending_arena_pattern() -> void:
	if pending_arena_pattern.is_empty():
		return
	if GameManager.is_run_over:
		pending_arena_pattern.clear()
		return
	if GameManager.is_gameplay_paused():
		arena_warning_timer.start(0.1)
		return
	_fire_arena_pattern_plan(pending_arena_pattern)
	pending_arena_pattern.clear()

func _create_arena_pattern_plan(pattern_id: String) -> Dictionary:
	match pattern_id:
		"cross_curtain":
			var first_side := randi_range(0, 3)
			return {
				"id": "curtain",
				"sides": [
					_create_curtain_side(first_side, 8, 4),
					_create_curtain_side((first_side + 1) % 4, 8, 4)
				]
			}
		"alternating_curtain":
			var first_side := randi_range(0, 1)
			return {
				"id": "curtain",
				"sides": [
					_create_curtain_side(first_side, 9, 4),
					_create_curtain_side(first_side + 2, 9, 4)
				]
			}
		"corner_pinwheel":
			return {"id": "corner_pinwheel"}
		"center_pulse":
			return _create_center_pulse_plan()
	return {
		"id": "curtain",
		"sides": [_create_curtain_side(randi_range(0, 3), 8, 4)]
	}

func _create_curtain_side(side: int, bullet_count: int, gap_width: int) -> Dictionary:
	return {
		"side": side,
		"bullet_count": bullet_count,
		"gap_width": gap_width,
		"gap_index": randi_range(1, maxi(1, bullet_count - gap_width - 1))
	}

func _create_center_pulse_plan() -> Dictionary:
	var bullet_count := 12
	var gap_width := 5
	return {
		"id": "center_pulse",
		"bullet_count": bullet_count,
		"gap_width": gap_width,
		"gap_index": randi_range(0, bullet_count - gap_width),
		"angle_offset": randf() * TAU
	}

func _fire_arena_pattern_plan(pattern_plan: Dictionary) -> void:
	match str(pattern_plan.get("id", "")):
		"corner_pinwheel":
			_fire_corner_pinwheel()
		"center_pulse":
			_fire_center_pulse(pattern_plan)
		_:
			var sides: Array = pattern_plan.get("sides", [])
			for side_index in range(sides.size()):
				var side_data: Dictionary = sides[side_index]
				_fire_side_curtain(
					int(side_data.get("side", 0)),
					int(side_data.get("bullet_count", 10)),
					int(side_data.get("gap_width", 2)),
					int(side_data.get("gap_index", 1))
				)

func _get_arena_warning_segments(pattern_plan: Dictionary) -> Array[Dictionary]:
	match str(pattern_plan.get("id", "")):
		"corner_pinwheel":
			return _get_corner_pinwheel_warning_segments()
		"center_pulse":
			return _get_center_pulse_warning_segments(pattern_plan)
	var segments: Array[Dictionary] = []
	var sides: Array = pattern_plan.get("sides", [])
	for side_index in range(sides.size()):
		var side_data: Dictionary = sides[side_index]
		segments.append_array(_get_side_curtain_warning_segments(
			int(side_data.get("side", 0)),
			int(side_data.get("bullet_count", 10)),
			int(side_data.get("gap_width", 2)),
			int(side_data.get("gap_index", 1))
		))
	return segments

func _get_corner_pinwheel_warning_segments() -> Array[Dictionary]:
	var rect := _get_spawn_rect()
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	var center := _get_arena_center()
	var segments: Array[Dictionary] = []
	for corner_index in range(corners.size()):
		var corner: Vector2 = corners[corner_index]
		var base_direction := corner.direction_to(center)
		for index in range(3):
			var angle := deg_to_rad((float(index) - 1.0) * 18.0)
			segments.append({
				"start": corner,
				"end": corner + base_direction.rotated(angle) * 260.0,
				"color": Color(1.0, 0.36, 0.9, 1.0),
				"width": 3.0
			})
	return segments

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
		for index in range(3):
			var angle := deg_to_rad((float(index) - 1.0) * 18.0)
			_spawn_arena_projectile(corner, base_direction.rotated(angle), Color(1.0, 0.36, 0.9, 1.0), 0.78, 0.88)

func _get_center_pulse_warning_segments(pattern_plan: Dictionary) -> Array[Dictionary]:
	var center := _get_arena_center()
	var bullet_count := maxi(1, int(pattern_plan.get("bullet_count", 16)))
	var gap_width := maxi(0, int(pattern_plan.get("gap_width", 3)))
	var gap_index := int(pattern_plan.get("gap_index", 0))
	var angle_offset := float(pattern_plan.get("angle_offset", 0.0))
	var segments: Array[Dictionary] = []
	for index in range(bullet_count):
		if index >= gap_index and index < gap_index + gap_width:
			continue
		var angle := angle_offset + TAU * float(index) / float(bullet_count)
		var direction := Vector2.RIGHT.rotated(angle)
		segments.append({
			"start": center + direction * 22.0,
			"end": center + direction * 280.0,
			"color": Color(1.0, 0.78, 0.28, 1.0),
			"width": 3.0
		})
	return segments

func _fire_center_pulse(pattern_plan: Dictionary) -> void:
	var center := _get_arena_center()
	var bullet_count := maxi(1, int(pattern_plan.get("bullet_count", 16)))
	var gap_width := maxi(0, int(pattern_plan.get("gap_width", 3)))
	var gap_index := int(pattern_plan.get("gap_index", 0))
	var angle_offset := float(pattern_plan.get("angle_offset", 0.0))
	for index in range(bullet_count):
		if index >= gap_index and index < gap_index + gap_width:
			continue
		var angle := angle_offset + TAU * float(index) / float(bullet_count)
		var direction := Vector2.RIGHT.rotated(angle)
		_spawn_arena_projectile(center + direction * 22.0, direction, Color(1.0, 0.72, 0.24, 1.0), 0.78, 0.82)

func _get_side_curtain_warning_segments(side: int, bullet_count: int, gap_width: int, gap_index: int) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	for index in range(bullet_count):
		if index >= gap_index and index < gap_index + gap_width:
			continue
		var data := _get_side_projectile_spawn(side, index, bullet_count)
		var position: Vector2 = data["position"]
		var direction: Vector2 = data["direction"]
		segments.append({
			"start": position,
			"end": position + direction * 220.0,
			"color": Color(0.45, 0.82, 1.0, 1.0),
			"width": 3.0
		})
	return segments

func _fire_side_curtain(side: int, bullet_count: int, gap_width: int, gap_index: int) -> void:
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

func _clear_active_combat_nodes() -> void:
	for group_name in ["enemies", "enemy_projectiles", "player_projectiles", "stage_events"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if is_instance_valid(node):
				node.queue_free()

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

func _get_dynamic_spawn_radius() -> float:
	var rect := _get_spawn_rect()
	var diagonal := rect.size.length() * 0.5
	return maxf(spawn_radius, diagonal)

func _get_dynamic_minimum_spawn_radius() -> float:
	var rect := _get_spawn_rect()
	var short_side := minf(rect.size.x, rect.size.y)
	return minf(maxf(minimum_spawn_radius, short_side * 0.42), maxf(120.0, short_side * 0.72))

func _random_stage_event_position() -> Vector2:
	var rect := _get_spawn_rect().grow(-64.0)
	var center := _get_arena_center()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return center
	for attempt in range(18):
		var position := Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		if player == null or position.distance_to(player.global_position) >= 120.0:
			return position
	return center

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
	var minimum_distance := _get_dynamic_minimum_spawn_radius()
	if position.distance_to(center) < minimum_distance:
		var fallback_direction := center.direction_to(position)
		if fallback_direction.is_zero_approx():
			fallback_direction = Vector2.RIGHT.rotated(randf() * TAU)
		position = center + fallback_direction * minimum_distance
		position.x = clampf(position.x, spawn_rect.position.x, spawn_rect.end.x)
		position.y = clampf(position.y, spawn_rect.position.y, spawn_rect.end.y)
	return position
