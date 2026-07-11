extends CharacterBody2D

const LOOT_DROP_SCENE := preload("res://scenes/loot_drop.tscn")

@export var move_speed: float = 120.0
@export var max_health: int = 20
@export var touch_damage: int = 10
@export var loot_chance: float = 0.45

var health: int
var target: Node2D

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

func _physics_process(_delta: float) -> void:
	if target == null:
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	GameManager.register_kill()
	if randf() <= loot_chance:
		var loot := LOOT_DROP_SCENE.instantiate()
		loot.global_position = global_position
		get_tree().current_scene.add_child(loot)
	queue_free()
