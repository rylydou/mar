class_name ServerAdvertiser extends Node

signal error(err: int)

# How often to broadcast out to the network that this host is active
@export var broadcast_interval: float = 1.
var server_info := {}

var socket_udp: PacketPeerUDP
var broadcast_timer := Timer.new()
@export var broadcast_port := 3111

func _enter_tree() -> void:
	broadcast_timer.wait_time = broadcast_interval
	broadcast_timer.one_shot = false
	broadcast_timer.autostart = true

func activate() -> void:
	if not multiplayer.is_server():
		printerr('LAN: Cannot start broadcast. Current network peer is not in server mode.')
		error.emit(ERR_UNAVAILABLE)
		return
	
	add_child(broadcast_timer)
	broadcast_timer.timeout.connect(broadcast) 
	
	socket_udp = PacketPeerUDP.new()
	socket_udp.set_broadcast_enabled(true)
	var err := socket_udp.set_dest_address('255.255.255.255', broadcast_port)
	if err != OK:
		printerr('LAN: Error starting broadcast on port %s: %s.' % [broadcast_port, error_string(err)])
		error.emit(err)
		return
	
	print('LAN: Broadcast started successfully.')

func broadcast() -> void:
	#print('Broadcasting game...')
	var packet_message := JSON.stringify(server_info)
	var packet := packet_message.to_ascii_buffer()
	socket_udp.put_packet(packet)

func _exit_tree() -> void:
	broadcast_timer.stop()
	if socket_udp != null:
		socket_udp.close()
