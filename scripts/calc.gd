class_name Calc

static func jump_gravity(height: float, duration: float) -> float:
	return 8.*(height/pow(duration, 2.))

static func jump_velocity(height: float, gravity: float) -> float:
	return sqrt(2.*gravity*height)

static func convert_m_ss(time_in_sec: float) -> String:
	var fracts := fmod(time_in_sec, 1) * 100
	var seconds := int(time_in_sec)%60
	var minutes := int(time_in_sec)/60
	
	return "%01d:%02d" % [minutes, seconds]
