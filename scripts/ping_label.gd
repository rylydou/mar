extends Label

func _process(delta: float) -> void:
	if multiplayer.is_server():
		text = 'Host'
		return
	
	if Performance.has_custom_monitor('Network/Ping'):
		var ping = Performance.get_custom_monitor('Network/Ping')
		text = '%sms' % ping
		return
	
	text = '???'
