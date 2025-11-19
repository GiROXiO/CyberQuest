extends Control

func _ready() -> void:
	$AnimationPlayer.play("EntrarStart")
	await($AnimationPlayer.animation_finished)

func _process(delta: float) -> void:
	if $Creditos.salirCreditos == true:
		$AnimationPlayer.play("EntrarStart")
		$Creditos.salirCreditos = false
		await($AnimationPlayer.animation_finished)
		
func _on_inicio_pressed() -> void:
	$AnimationPlayer.play("SalirStart")
	await($AnimationPlayer.animation_finished)
	get_tree().change_scene_to_file("res://scenes/gameManager.tscn")
	#Esto es para probar el menu de pause
	#get_tree().paused = not get_tree().paused
	#$pause_menu.entrarPausa = true
	#$pause_menu.visible = true


func _on_creditos_pressed() -> void:
	$AnimationPlayer.play("SalirStart")
	await($AnimationPlayer.animation_finished)
	$Creditos.entrarCreditos = true

func _on_salir_pressed() -> void:
	get_tree().quit()
