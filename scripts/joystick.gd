extends Panel

func _process(delta: float) -> void:
	position.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)/2 + .5
	position.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)/2 + .5
	
	position *= get_parent().size
