extends Camera2D

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false

	if event is InputEventMouseMotion and dragging:
		var delta = event.position - last_mouse_pos
		position -= delta  # se mueve al revés para seguir la mano
		last_mouse_pos = event.position
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= 1.1
		zoom = zoom.clamp(Vector2(0.5, 0.5), Vector2(3, 3))
