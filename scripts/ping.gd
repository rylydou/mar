extends Node

var ping_usec = 0
func get_ping_usec() -> int: return ping_usec
func get_ping_msec() -> int: return ping_usec/1000
func get_ping_sec() -> int: return ping_usec/1000000

func _enter_tree() -> void:
	Performance.add_custom_monitor('network/ping', get_ping_msec)

@rpc('any_peer')
func ping(dict: Dictionary) -> void:
	var usec := Time.get_ticks_usec()
	dict['receive_time'] = usec
	pong.rpc_id(dict.sender_id, dict)
	print('ping ', dict)

@rpc('any_peer')
func pong(dict: Dictionary) -> void:
	print('pong ', dict)
	var send_time := dict['send_time'] as int
	var receive_time := dict['receive_time'] as int
	
	ping_usec = receive_time-send_time

var ping_index := 0
func _on_timeout() -> void:
	if multiplayer.is_server(): return
	
	var usec := Time.get_ticks_usec()
	ping_index += 1
	
	var dict := {}
	dict['ping_index'] = ping_index
	dict['receiver_id'] = 1
	dict['sender_id'] = multiplayer.get_unique_id()
	dict['send_time'] = usec
	
	ping.rpc_id(1, dict)
