extends Area2D

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

@export var gold_amount: int = 1
@export var pickup_radius: float = 20.0
@export var equipment_chance: float = 0.28
@export var source_level: int = 1

var equipment: Dictionary = {}
var blocked_pickup_retry_cooldown: float = 0.0

func _ready() -> void:
	if randf() <= _get_scaled_equipment_chance():
		equipment = EquipmentFactory.roll_equipment(source_level)
		$Visual.color = equipment["color"]
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if equipment.is_empty() or GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	blocked_pickup_retry_cooldown -= delta
	if blocked_pickup_retry_cooldown > 0.0:
		return
	for body in get_overlapping_bodies():
		if body.name == "Player":
			_try_pickup(body)
			return

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_try_pickup(body)

func _try_pickup(_body: Node) -> void:
	if equipment.is_empty():
		GameManager.add_gold(_get_scaled_gold_amount())
		queue_free()
		return
	if GameManager.pickup_equipment(equipment):
		queue_free()
	else:
		blocked_pickup_retry_cooldown = 0.8

func _get_scaled_equipment_chance() -> float:
	var level_bonus := minf(0.12, float(maxi(0, source_level - 1)) * 0.015)
	return clampf(equipment_chance + level_bonus, 0.0, 0.45)

func _get_scaled_gold_amount() -> int:
	return gold_amount + int(floor(float(maxi(0, source_level - 1)) / 3.0))
