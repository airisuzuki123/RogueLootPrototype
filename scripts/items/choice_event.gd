extends Area2D

const CombatFeedback := preload("res://scripts/effects/combat_feedback.gd")

var event_config: Dictionary = {}
var event_id: String = ""
var opened: bool = false

@onready var visual: Polygon2D = $Visual
@onready var marker_label: Label = $MarkerLabel

func _ready() -> void:
	add_to_group("stage_events")
	body_entered.connect(_on_body_entered)
	_refresh_visual()

func _physics_process(_delta: float) -> void:
	if opened or GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	for body in get_overlapping_bodies():
		if body.name == "Player":
			_try_open()
			return

func configure(event: Dictionary) -> void:
	event_config = event.duplicate(true)
	event_id = str(event_config.get("id", ""))
	if is_inside_tree():
		_refresh_visual()

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_try_open()

func _try_open() -> void:
	if opened or event_id.is_empty() or GameManager.is_gameplay_paused():
		return
	if not GameManager.open_choice_event(event_id):
		return
	opened = true
	CombatFeedback.show_burst(get_tree().current_scene, global_position, Color(0.82, 0.48, 1.0, 0.95), 1.35)
	queue_free()

func _refresh_visual() -> void:
	visual.color = Color(0.70, 0.34, 1.0, 1.0)
	visual.polygon = PackedVector2Array([
		Vector2(0, -22),
		Vector2(18, -8),
		Vector2(14, 16),
		Vector2(0, 22),
		Vector2(-14, 16),
		Vector2(-18, -8)
	])
	marker_label.text = "?"
	marker_label.add_theme_color_override("font_color", Color(0.08, 0.02, 0.16, 1.0))
	marker_label.add_theme_color_override("font_outline_color", Color(0.95, 0.76, 1.0, 0.95))
	marker_label.add_theme_constant_override("outline_size", 3)
