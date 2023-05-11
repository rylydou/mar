extends Control

@export var main: Main
@export var game: GameManager
@export var server_listener: ServerListener
@export var server_advertiser: ServerAdvertiser

@export var connect_label: Label

@export var connect_address: LineEdit
@export var connect_port: LineEdit
@export var connect_list: ItemList

@export var host_address: LineEdit
@export var host_port: LineEdit
@export var host_name: LineEdit
@export var host_broadcast: BaseButton

var is_broadcasting = false
var server_name = 'Unnamed Server'
var server_port = 0

func _enter_tree() -> void:
	clear_connect_list()
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _connected_to_server() -> void:
	connect_label.hide()

func _connection_failed() -> void:
	printerr('LOBBY: Failed to connect to server.')
	OS.alert('Failed to connect to server.')
	main.players.clear()
	multiplayer.multiplayer_peer.close()
	get_tree().reload_current_scene.call_deferred()

func _server_disconnected() -> void:
	print('LOBBY: The host has left.')
	OS.alert('The host left.')
	main.players.clear()
	multiplayer.multiplayer_peer.close()
	get_tree().reload_current_scene.call_deferred()

func _ready() -> void:
	get_tree().paused = true
	
	host_address.text = IP.get_local_addresses()[0]

func _btn_connect() -> void:
	var address = 'localhost'
	if not connect_address.text.is_empty():
		address = connect_address.text
	
	var port = 1234
	if connect_port.text.is_valid_int():
		port = int(connect_port.text)
	
	if not connect_client(address, port): return
	
	close()
	
	if OS.is_debug_build():
		get_window().position.x = DisplayServer.screen_get_usable_rect().size.x/2

func _btn_host(and_player: bool) -> void:
	var port = 1234
	if host_port.text.is_valid_int():
		port = int(host_port.text)
	
	if not host_server(port): return
	
	close()
	
	if OS.is_debug_build():
		get_window().position.x = 0
	
	if and_player:
		main.add_player(1)
	#game.reset()
	
	server_listener.socket_udp.close()
	
	server_advertiser.server_info['port'] = port
	if not host_name.text.is_empty():
		server_advertiser.server_info['name'] = host_name.text
	
	if OS.has_environment("COMPUTERNAME"):
		server_advertiser.server_info['device_name'] = OS.get_environment("COMPUTERNAME")
		return
	else:
		server_advertiser.server_info['device_name'] = 'Some %s device' % OS.get_name()
	
	if host_broadcast.button_pressed:
		server_advertiser.activate()

func host_server(port: int) -> bool:
	prints("LOBBY: Hosting server on port %s" % [port])
	
	var peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port)
	if error != OK:
		OS.alert("Failed to start server: " + error_string(error))
		return false
	multiplayer.multiplayer_peer = peer
	return true

func connect_client(address: String, port: int) -> bool:
	prints("LOBBY: Connecting client to '%s' on port %s " % [address, port])
	
	connect_label.show()
	
	var peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		OS.alert("Failed to connect to server: " + error_string(error), "Failed to connect to server.")
		return false
	multiplayer.multiplayer_peer = peer
	return true

func close() -> void:
	hide()
	get_tree().paused = false

func _process(delta: float) -> void:
	if is_broadcasting:
		server_advertiser.server_info['players'] = main.get_player_count()

func _on_connect_list_item_selected(index: int) -> void:
	var address = connect_list.get_item_metadata(index)
	if address == null: return
	
	if not server_listener.known_servers.has(address):
		connect_list.remove_item(index)
		OS.alert('This server is no longer online.')
		return
	
	var info = server_listener.known_servers[address]
	connect_address.text = address
	connect_port.text = str(info.port)

func _on_connect_list_item_activated(index: int) -> void:
	if connect_list.get_item_metadata(index) == null: return
	_on_connect_list_item_selected(index)
	_btn_connect()

func _on_server_listener_new_server(info: Dictionary) -> void:
	var txt := PackedStringArray()
	if info.has('name') and info.name != '':
		txt.append(info.name)
#		if info.has('device_name') and info.device_name != '':
#			txt.append(' on ')
#			txt.append(info.device_name)
#	elif info.has('device_name') and info.device_name != '':
#		txt.append(info.device_name)
	else:
		txt.append(info.address)
	
	if info.has('players') and info.players != '':
		txt.append(' (')
		txt.append(info.players)
		if info.players == 1 or info.players == '1':
			txt.append(' player)')
		else:
			txt.append(' players)')
	
	connect_list.add_item(''.join(txt))
	connect_list.set_item_tooltip(connect_list.item_count - 1, info.address)
	connect_list.set_item_metadata(connect_list.item_count - 1, info.address)
	
	if OS.is_debug_build() and (not info.has('name') or info.name == ''):
		_on_connect_list_item_selected(connect_list.item_count - 1)
		_btn_connect()

func _on_server_listener_error(err: int) -> void:
	connect_list.clear()
	connect_list.add_item('Cannot find games on your local network: ' + error_string(err), null, false)
	connect_list.set_item_disabled(0, true)
	connect_list.set_item_custom_fg_color(0, Color.RED)

func clear_connect_list() -> void:
	connect_list.clear()
	server_listener.known_servers.clear()
	connect_list.add_item('Looking for games on your local network...', null, false)
	connect_list.set_item_disabled(0, true)
