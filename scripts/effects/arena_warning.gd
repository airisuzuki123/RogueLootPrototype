extends Node2D

var segments: Array[Dictionary] = []
var duration: float = 0.75
var elapsed: float = 0.0

func show_warning(new_segments: Array[Dictionary], warning_duration: float) -> void:
	segments = new_segments.duplicate(true)
	duration = maxf(0.1, warning_duration)
	elapsed = 0.0
	visible = true
	queue_redraw()

func clear_warning() -> void:
	segments.clear()
	visible = false
	queue_redraw()

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible or GameManager.is_run_over or GameManager.is_gameplay_paused():
		return
	elapsed += delta
	if elapsed >= duration:
		clear_warning()
		return
	queue_redraw()

func _draw() -> void:
	if segments.is_empty():
		return
	var progress: float = clampf(elapsed / duration, 0.0, 1.0)
	var pulse: float = 0.45 + absf(sin(progress * TAU * 2.0)) * 0.35
	for segment in segments:
		var start: Vector2 = segment["start"]
		var end: Vector2 = segment["end"]
		var color: Color = segment.get("color", Color(1.0, 0.25, 0.25, 1.0))
		var width := float(segment.get("width", 3.0))
		color.a = pulse
		draw_line(start, end, color, width)
		var glow_color := Color(color.r, color.g, color.b, pulse * 0.18)
		draw_line(start, end, glow_color, width + 10.0)
