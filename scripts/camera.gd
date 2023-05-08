extends Camera2D

@export var y_damp := 4.

@export var lookahead_distance := 8.
@export var lookahead_damp := 4.

@onready var player: Player = get_parent()
@onready var target_y = player.position.y
@onready var target_lookagead = player.direction

func _ready() -> void:
	return
	var map := get_tree().root.get_node('World/TileMap') as TileMap
	var rect := map.get_used_rect() as Rect2
	rect.position = rect.position*16
	rect.size = rect.size*16
	
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.end.x
	limit_bottom = rect.end.y

var lookahead = 0.
func _process(delta: float) -> void:
	target_lookagead = player.direction
	lookahead = damp(lookahead, target_lookagead, lookahead_damp, delta)
	
	position.x = player.position.x + lookahead*lookahead_distance*16
	
	if player.position.y > target_y or player.is_on_floor() or player.position.y < target_y - 80:
		target_y = player.position.y
	position.y = damp(position.y, target_y, y_damp, delta)
	position = Vector2.ZERO

func damp(current: float, target: float, smoothing: float, delta: float) -> float:
	var t := 1 - exp(-smoothing*delta)
	return lerp(current, target, t)
