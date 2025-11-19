extends CanvasLayer

@export var salirCreditos = false
@export var entrarCreditos = false

func _physics_process(delta: float) -> void:
	if entrarCreditos == true:
		visible = true
		$AnimationPlayer.play("EntrarCreditos")
		await($AnimationPlayer.animation_finished)
		entrarCreditos = false
		
func _on_stylish_bottom_pressed() -> void:
	$AnimationPlayer.play("SalirCreditos")
	await ($AnimationPlayer.animation_finished)
	$".".visible = false
	salirCreditos = true
