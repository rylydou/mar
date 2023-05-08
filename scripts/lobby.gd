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
	
	main.connect_client(address, port)

func _btn_host() -> void:
	var port = 1234
	if not host_port.text.is_empty():
		port = int(host_port.text)
	
	main.host_server(port)
	
	server_advertiser.server_info['name'] = host_name.text
	server_advertiser.server_info['port'] = port
	
	if host_broadcast.button_pressed:
		server_advertiser.activate()
	
	server_listener.socket_udp.close()

func _process(delta: float) -> void:
	server_advertiser.server_info['players'] = main.get_player_count()

func _on_server_listener_new_server(info: Dictionary) -> void:
	if info.has('name') and info.name != '':
		connect_list.add_item(info.name)
	else:
		connect_list.add_item(info.address)
	
	connect_list.set_item_tooltip(connect_list.item_count - 1, info.address)
	connect_list.set_item_metadata(connect_list.item_count - 1, info.address)

func _on_connect_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var address = connect_list.get_item_metadata(index)
	if address == null: return
	
	if not server_listener.known_servers.has(address):
		connect_list.remove_item(index)
		OS.alert('This server does not exist anymore.')
		return
	
	var info = server_listener.known_servers[address]
	connect_address.text = address
	connect_port.text = str(info.port)
