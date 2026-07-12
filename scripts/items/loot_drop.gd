extends Area2D

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

@export var gold_amount: int = 1
@export var pickup_radius: float = 20.0
@export var equipment_chance: float = 0.28
@export var source_level: int = 1

var equipment: Dictionary = {}

func _ready() -> void:
	if randf() <= _get_scaled_equipment_chance():
		equipment = EquipmentFactory.roll_equipment(source_level)
		$Visual.color = equipment["color"]
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if equipment.is_empty():
		GameManager.add_gold(_get_scaled_gold_amount())
		queue_free()
		return
	if GameManager.pickup_equipment(equipment):
		queue_free()

func _get_scaled_equipment_chance() -> float:
	var level_bonus := minf(0.12, float(maxi(0, source_level - 1)) * 0.015)
	return clampf(equipment_chance + level_bonus, 0.0, 0.45)

func _get_scaled_gold_amount() -> int:
	return gold_amount + int(floor(float(maxi(0, source_level - 1)) / 3.0))
