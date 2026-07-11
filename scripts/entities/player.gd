extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

@export var move_speed: float = 260.0
@export var max_health: int = 100
@export var fire_interval: float = 0.45
@export var projectile_damage: int = 10

var health: int
var fire_cooldown: float = 0.0

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	_update_auto_attack(delta)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

func _update_auto_attack(delta: float) -> void:
	fire_cooldown -= delta
	if fire_cooldown > 0.0:
		return
	var target := _find_nearest_enemy()
	if target == null:
		return
	fire_cooldown = fire_interval
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position
	projectile.direction = global_position.direction_to(target.global_position)
	projectile.damage = projectile_damage
	get_tree().current_scene.add_child(projectile)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest
