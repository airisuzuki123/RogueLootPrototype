extends Area2D

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

@export var gold_amount: int = 1
@export var pickup_radius: float = 20.0
@export var equipment_chance: float = 0.28
@export var source_level: int = 1

var equipment: Dictionary = {}

func _ready() -> void:
	if randf() <= equipment_chance:
		equipment = EquipmentFactory.roll_weapon(source_level)
		$Visual.color = equipment["color"]
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if equipment.is_empty():
		GameManager.add_gold(gold_amount)
	else:
		GameManager.pickup_equipment(equipment)
	queue_free()
