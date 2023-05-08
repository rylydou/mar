class_name Main extends Node

@export var player_scene: PackedScene
@export var players_node: Node

func _enter_tree() -> void:
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

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
		multiplayer.multiplayer_peer.close()
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
