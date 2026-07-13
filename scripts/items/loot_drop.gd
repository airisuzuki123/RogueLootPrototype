extends Area2D

const EquipmentFactory := preload("res://scripts/items/equipment_factory.gd")

@export var gold_amount: int = 1
@export var pickup_radius: float = 20.0
@export var equipment_chance: float = 0.10
@export var source_level: int = 1
@export var equipment_only: bool = false

var equipment: Dictionary = {}
var blocked_pickup_retry_cooldown: float = 0.0

func _ready() -> void:
	if equipment_only or randf() <= _get_scaled_equipment_chance():
		equipment = EquipmentFactory.roll_equipment(source_level)
		_configure_equipment_visual()
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
	if equipment.is_empty():
		GameManager.add_gold(_get_scaled_gold_amount())
		queue_free()
		return
	if GameManager.pickup_equipment(equipment):
		queue_free()
	else:
		blocked_pickup_retry_cooldown = 0.8

func _get_scaled_equipment_chance() -> float:
	return get_scaled_equipment_chance_for_level(source_level, equipment_chance)

static func get_scaled_equipment_chance_for_level(level: int, base_chance: float = 0.10) -> float:
	var level_bonus := minf(0.06, float(maxi(0, level - 1)) * 0.006)
	return clampf(base_chance + level_bonus, 0.0, 0.18)

func _get_scaled_gold_amount() -> int:
	return gold_amount + int(floor(float(maxi(0, source_level - 1)) / 3.0))

func _configure_gold_visual() -> void:
	$Visual.color = Color(1.0, 0.82, 0.18, 1.0)
	$Visual.polygon = _make_regular_polygon(12, 8.0)
	_configure_marker_label("金", Color(0.24, 0.16, 0.02, 1.0), 13)

func _configure_experience_visual() -> void:
	$Visual.color = Color(0.2, 0.95, 1.0, 1.0)
	$Visual.polygon = _make_regular_polygon(12, 7.0)
	_configure_marker_label("经", Color(0.02, 0.18, 0.22, 1.0), 12)

func _configure_equipment_visual() -> void:
	$Visual.color = equipment["color"]
	$Visual.polygon = PackedVector2Array([Vector2(0, -12), Vector2(12, 0), Vector2(0, 12), Vector2(-12, 0)])
	_configure_marker_label(_get_equipment_slot_symbol(), Color.WHITE, 12)

func _configure_marker_label(text: String, color: Color, font_size: int) -> void:
	var marker := Label.new()
	marker.text = text
	marker.position = Vector2(-12, -10)
	marker.size = Vector2(24, 20)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.add_theme_font_size_override("font_size", font_size)
	marker.add_theme_color_override("font_color", color)
	marker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	marker.add_theme_constant_override("outline_size", 3)
	marker.z_index = 2
	add_child(marker)

func _get_equipment_slot_symbol() -> String:
	match str(equipment.get("slot", "weapon")):
		"weapon":
			return "杖"
		"helmet":
			return "盔"
		"armor":
			return "甲"
		"boots":
			return "靴"
		"necklace":
			return "链"
		"ring":
			return "戒"
	return "装"

func _make_regular_polygon(points: int, radius: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in range(points):
		var angle := -PI / 2.0 + TAU * float(index) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon
