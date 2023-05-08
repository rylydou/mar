class_name Main extends Node

@export var player_scene: PackedScene
@export var players_node: Node

func _enter_tree() -> void:
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

func host_server(port: int) -> void:
	prints("SERVER: Hosting server on port %s" % [port])
	
	var peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port)
	if error != OK:
		OS.alert(error_string(error), "Failed to start server.")
		return
	multiplayer.multiplayer_peer = peer
	$UI/Lobby.hide()
	
	add_player(1)
	
	get_tree().paused = false

func connect_client(address: String, port: int) -> void:
	prints("CLIENT: Connecting client to '%s' on port %s " % [address, port])
	
	var peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		OS.alert(error_string(error), "Failed to connect to server.")
		return
	multiplayer.multiplayer_peer = peer
	$UI/Lobby.hide()
	
	get_tree().paused = false

var players: Array[int] = []

func add_player(id: int):
	if not is_multiplayer_authority():
		return
	
	print('SERVER: Adding player #', id)
	players.append(id)
	
	var player = player_scene.instantiate() as Player
	# Set player id.
	player.id = id
	# Randomize player position.
	player.position = Vector2(randf_range(-20, 20), 0)
	player.name = str(id)
	players_node.add_child(player)

func del_player(id: int):
	if id == 1:
		print('CLIENT: Host left, restarting game.')
		players.clear()
		get_tree().reload_current_scene.call_deferred()
		return
	
	if not is_multiplayer_authority():
		return
	
	print('SERVER: Deleting player #', id)
	players.erase(id)
	
	if not players_node.has_node(str(id)):
		return
	players_node.get_node(str(id)).queue_free()

func get_player_count() -> int:
	return players.size()
