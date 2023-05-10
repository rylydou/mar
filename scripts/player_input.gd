class_name PlayerInput extends MultiplayerSynchronizer

var move := Vector2.ZERO

var jump_pressed := false
var jump_down := false

var action_pressed := false
var action_down := false

func _ready() -> void:
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())

@rpc('call_local')
func jump():
	jump_pressed = true

@rpc('call_local')
func action():
	action_pressed = true

func _process(delta):
	move.x =Input.get_axis('left', 'right')
	move.y = Input.get_axis('up', 'down')
	
	jump_down = Input.is_action_pressed('jump')
	if Input.is_action_just_pressed('jump'):
		jump.rpc()
	
	action_down = Input.is_action_pressed('action')
	if Input.is_action_just_pressed('action'):
		action.rpc()
