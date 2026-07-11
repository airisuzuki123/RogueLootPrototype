extends Area2D

@export var gold_amount: int = 1
@export var pickup_radius: float = 20.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	GameManager.add_gold(gold_amount)
	queue_free()

