extends Timer

var ping_usec = 0
func get_ping_usec() -> int: return ping_usec
func get_ping_msec() -> int: return ping_usec/1000
func get_ping_sec() -> int: return ping_usec/1000000

func _enter_tree() -> void:
	Performance.add_custom_monitor('Network/Ping', get_ping_msec)

@rpc('any_peer')
func ping(ping_index: int) -> void:
	pong.rpc_id(multiplayer.get_remote_sender_id(), ping_index)

@rpc('authority')
func pong(ping_index: int) -> void:
	var time = Time.get_ticks_usec()
	
	assert(ping_index <= next_ping_index, 'Ping #%s has not been sent yet.' % ping_index)
	assert(outgoing_pings_times.has(ping_index), 'Ping #%s has already been received.' % ping_index)
	
	var ping_send_time := outgoing_pings_times[ping_index] as int
	
	ping_usec = time - ping_send_time

var next_ping_index := 0
var outgoing_pings_times = {}
func _on_timeout() -> void:
	if multiplayer.is_server(): return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED: return
	next_ping_index += 1
	outgoing_pings_times[next_ping_index] = Time.get_ticks_usec()
	ping.rpc_id(1, next_ping_index)
