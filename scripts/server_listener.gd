class_name ServerListener extends Node

signal new_server(info: Dictionary)
signal remove_server(ip: int)
signal error(err: int)

var clean_up_timer := Timer.new()
var socket_udp := PacketPeerUDP.new()
@export var listen_port := 3111
var known_servers = {}

# Number of seconds to wait when a server hasn't been heard from
# before calling remove_server
@export var server_cleanup_threshold: int = 3

func _init():
	clean_up_timer.wait_time = server_cleanup_threshold
	clean_up_timer.one_shot = false
	clean_up_timer.autostart = true
	clean_up_timer.timeout.connect(clean_up)
	add_child(clean_up_timer)

func _ready():
	known_servers.clear()
	
	var err = socket_udp.bind(listen_port)
	if err != OK:
		printerr('LAN: Error starting broadcast on port %s: %s.' % [listen_port, error_string(err)])
		error.emit(err)
		return
	
	print('LAN: Listening on port: ' + str(listen_port))

func _process(delta):
	if socket_udp.get_available_packet_count() > 0:
		var server_ip := socket_udp.get_packet_ip()
		var server_port := socket_udp.get_packet_port()
		var array_bytes := socket_udp.get_packet()
		var server_address := server_ip
		
		if server_ip != '' and server_port > 0:
			if not known_servers.has(server_address):
				# We've discovered a new server! Add it to the list and let people know
				var server_message := array_bytes.get_string_from_ascii()
				var game_info := JSON.parse_string(server_message) as Dictionary
				game_info.ip = server_ip
				game_info.address = server_address
				game_info.last_seen = Time.get_unix_time_from_system()
				known_servers[server_address] = game_info
				new_server.emit(game_info)
			else:
				# Update the last seen time
				var game_info := known_servers[server_address] as Dictionary
				game_info.last_seen = Time.get_unix_time_from_system()

func clean_up():
	var now := Time.get_unix_time_from_system()
	for server_address in known_servers:
		var server_info := known_servers[server_address] as Dictionary
		if (now - server_info.last_seen) > server_cleanup_threshold:
			known_servers.erase(server_address)
			remove_server.emit(server_address)

func _exit_tree():
	socket_udp.close()
