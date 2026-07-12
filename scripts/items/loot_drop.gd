extends Area2D

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

const DROP_MIXED := "mixed"
const DROP_EXPERIENCE := "experience"

@export var gold_amount: int = 1
@export var pickup_radius: float = 20.0
@export var equipment_chance: float = 0.10
@export var source_level: int = 1
@export var drop_kind: String = DROP_MIXED
@export var experience_amount: int = 1

var equipment: Dictionary = {}
var blocked_pickup_retry_cooldown: float = 0.0

func _ready() -> void:
	if drop_kind == DROP_EXPERIENCE:
		_configure_experience_visual()
	elif randf() <= _get_scaled_equipment_chance():
		equipment = EquipmentFactory.roll_equipment(source_level)
		$Visual.color = equipment["color"]
	else:
		_configure_gold_visual()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	if not equipment.is_empty():
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
	if drop_kind == DROP_EXPERIENCE:
		GameManager.add_experience(experience_amount)
		queue_free()
		return
	if equipment.is_empty():
		GameManager.add_gold(_get_scaled_gold_amount())
		queue_free()
		return
	if GameManager.pickup_equipment(equipment):
		queue_free()
	else:
		blocked_pickup_retry_cooldown = 0.8

func _get_scaled_equipment_chance() -> float:
	var level_bonus := minf(0.06, float(maxi(0, source_level - 1)) * 0.006)
	return clampf(equipment_chance + level_bonus, 0.0, 0.18)

func _get_scaled_gold_amount() -> int:
	return gold_amount + int(floor(float(maxi(0, source_level - 1)) / 3.0))

func _configure_gold_visual() -> void:
	$Visual.color = Color(1.0, 0.82, 0.18, 1.0)
	$Visual.polygon = PackedVector2Array([Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)])

func _configure_experience_visual() -> void:
	$Visual.color = Color(0.2, 0.95, 1.0, 1.0)
	$Visual.polygon = _make_regular_polygon(8, 6.0)

func _make_regular_polygon(points: int, radius: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in range(points):
		var angle := -PI / 2.0 + TAU * float(index) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon
