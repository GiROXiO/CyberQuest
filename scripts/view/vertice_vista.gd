extends Area2D
class_name VerticeVista

signal vertex_clicked


var radius: float = 18.0
var aura_radius: float = 26.0
var aura_time: float = 0.0
var selected: bool = false

func _ready() -> void:
	# ajustar colisión al radio
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D.shape
		if shape is CircleShape2D:
			(shape as CircleShape2D).radius = radius
	set_process(true)

func _process(delta: float) -> void:
	if selected:
		aura_time += delta
	else:
		aura_time = 0.0
	queue_redraw()

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected = not selected
		emit_signal("vertex_clicked")
		queue_redraw()

func _draw() -> void:
	var base_color = Color(0.2, 0.8, 0.4)
	var outline_color = Color(0.1, 0.4, 0.2)

	if selected:
		base_color = Color(1.0, 0.8, 0.2)
		outline_color = Color(0.8, 0.5, 0.1)

		# aura
		var pulse = 0.5 + 0.5 * sin(aura_time * 4.0)
		var current_radius = lerp(aura_radius, aura_radius + 6.0, pulse)
		draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.9, 0.4, 0.3))

	# círculo
	draw_circle(Vector2.ZERO, radius + 2.0, outline_color)
	draw_circle(Vector2.ZERO, radius, base_color)
