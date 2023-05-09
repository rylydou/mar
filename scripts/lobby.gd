extends Control

@export var main: Main
@export var server_listener: ServerListener
@export var server_advertiser: ServerAdvertiser

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

func _ready() -> void:
	get_tree().paused = true
	
	host_address.text = IP.get_local_addresses()[0]
	prints('My local addresses:', IP.get_local_addresses())

func _btn_connect() -> void:
	var address = 'localhost'
	if not connect_address.text.is_empty():
		address = connect_address.text
	
	var port = 1234
	if not connect_port.text.is_empty():
		port = int(connect_port.text)
	
	if not connect_client(address, port): return
	
	close()

func _btn_host(and_player: bool) -> void:
	var port = 1234
	if not host_port.text.is_empty():
		port = int(host_port.text)
	
	if not host_server(port): return
	
	close()
	
	if and_player:
		main.add_player(1)
	
	server_listener.socket_udp.close()
	
	server_advertiser.server_info['name'] = host_name.text
	server_advertiser.server_info['port'] = port
	
	if host_broadcast.button_pressed:
		server_advertiser.activate()

func host_server(port: int) -> bool:
	prints("SERVER: Hosting server on port %s" % [port])
	
	var peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port)
	if error != OK:
		OS.alert(error_string(error), "Failed to start server.")
		return false
	multiplayer.multiplayer_peer = peer
	return true

func connect_client(address: String, port: int) -> bool:
	prints("CLIENT: Connecting client to '%s' on port %s " % [address, port])
	
	var peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		OS.alert(error_string(error), "Failed to connect to server.")
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
		OS.alert('This server does not exist anymore.')
		return
	
	var info = server_listener.known_servers[address]
	connect_address.text = address
	connect_port.text = str(info.port)

func _on_connect_list_item_activated(index: int) -> void:
	_on_connect_list_item_selected(index)
	#_btn_connect()

func _on_server_listener_new_server(info: Dictionary) -> void:
	var txt := PackedStringArray()
	if info.has('name') and info.name != '':
		txt.append(info.name)
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
