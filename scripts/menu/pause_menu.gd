extends CanvasLayer

var pause = false
@export var entrarPausa = false
@export var salirPausa = false

func _physics_process(delta: float) -> void:
	if entrarPausa == true:
		$AnimationPlayer.play("EntrarPausa")
		await($AnimationPlayer.animation_finished)
		entrarPausa = false
		
	if Input.is_action_just_pressed("Pausa"):
		if visible == true:
			MusicPlayer.play_music("res://musica/pausa.mp3")
			$AnimationPlayer.play("SalirPausa")
			await($AnimationPlayer.animation_finished)
			visible = false
		

func _on_reanudar_pressed() -> void:
	$AnimationPlayer.play("SalirPausa")
	await($AnimationPlayer.animation_finished)
	salirPausa = true
	visible = false
	#pause = not pause
	#
#func status_pause(pause):
	#pause = pause


func _on_salir_pressed() -> void:
	$AnimationPlayer.play("SalirPausa")
	MusicPlayer.stop_music("res://musica/dialogo1.mp3")
	MusicPlayer.stop_music("res://musica/dialogo1.mp3")
	MusicPlayer.stop_music("res://musica/dialogo1.mp3")
	await($AnimationPlayer.animation_finished)
	get_tree().change_scene_to_file("res://scenes/menu/start_menu.tscn")
