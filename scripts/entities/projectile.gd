extends Area2D

@export var speed: float = 520.0
@export var lifetime: float = 1.4

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if GameManager.is_upgrade_pending:
		return
	global_position += direction.normalized() * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
