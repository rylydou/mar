extends Label

func _process(delta: float) -> void:
	if multiplayer.is_server():
		text = 'Host'
		return
	
	if Performance.has_custom_monitor('network/ping'):
		var ping = Performance.get_custom_monitor('network/ping')
		text = '%sms ping' % round(ping*1000)
		return
	
	text = 'Unknown ping'
