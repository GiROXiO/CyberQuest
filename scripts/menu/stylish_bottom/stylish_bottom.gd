extends Button


#var SelectedGrayIntesity 
#var SelectedBlackIntesity 
#var UnselectedGrayIntesity 
#var UnselectedBlackIntesity
#
#func free() -> void:
	#SelectedGrayIntesity = $Select/GrayRentangle.intensity
	#SelectedBlackIntesity = $Select/BlackRectangle.intensity
	#UnselectedGrayIntesity = $Unselect/GrayRentangle.intensity
	#UnselectedBlackIntesity = $Unselect/BlackRectangle.intensity
#
#func selecting(rect,num) -> void:
	#if num == 0:
		#for i in 4:
			#rect.intesity += 1
	#if num == 1:
		#for i in 4:
			#rect.intesity -= 1

func _on_mouse_entered() -> void:
	$Unselect.visible = false
	$Select.visible = true


func _on_mouse_exited() -> void:
	$Select.visible = false
	$Unselect.visible = true
