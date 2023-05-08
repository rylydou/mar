extends Label

func _process(delta: float) -> void:
	text = '%s fps' % Performance.get_monitor(Performance.TIME_FPS)
