extends Node

func play_music(path: String):
	var stream := load(path)
	if not stream:
		push_warning("No se pudo cargar: " + path)
		return null

	var player := AudioStreamPlayer.new()
	add_child(player)

	player.stream = stream
	player.volume_db = -10.0       # volumen global que pediste
	player.play()

	# Cuando termine, se borra solo
	player.finished.connect(player.queue_free)

	return player


func stop_music(path: String):
	# Detener solo las pistas que coincidan con el mismo path
	for child in get_children():
		if child is AudioStreamPlayer and child.stream.resource_path == path:
			child.stop()
			child.queue_free()
