class_name Player extends CharacterBody2D

signal death()

@export var input: PlayerInput
@export var flip_node: Node2D
@export var ladder_dectector_area: Area2D
@export var shoot_marker: Marker2D

@export var TPS = 60.
@export var BLOCK_SIZE = 16.

@export_group('Movement', 'move_')
@export var move_speed := 64.
@export var move_crouch_speed := 32.

@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var move_acc_ticks := 4.
@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var move_dec_ticks := 6.
@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var move_opp_ticks := 2.

@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var move_acc_air_ticks := 8.
@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var move_dec_air_ticks := 12.
@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var move_opp_air_ticks := 4.

@export_group('Gravity and Jump')
@export var jump_height_min := 1.
@export var jump_height_max := 3.
@export_range(0, 120, 1, 'or_greater', 'suffix:ticks') var jump_ticks := 60
@export_range(0, 120, 1, 'or_greater', 'suffix:ticks') var fall_ticks := 60
var fall_gravity := 0.
var jump_gravity := 0.
var jump_velocity_min := 0.
var jump_velocity_max := 0.

## The maxinum falling speed based on the max jump height
@export var max_fall_ratio := 2.
var max_fall_speed := 0.
var is_jumping := false

@export_group('Assits')
## The amount of time the player can still jump after leaving a platform, see 'Looney Tunes'
@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var coyote_time_ticks := 6
var coyote_timer := -1.
@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var jump_buffer_ticks := 6
var jump_buffer_timer := -1.
@export_range(0, 60, 1, 'or_greater', 'suffix:ticks') var action_buffer_ticks := 6
var action_buffer_timer := -1.

## If the player hits their head on a cornner then how far can they be nuged out of the way
@export_range(0, 16, 1, 'or_greater', 'suffix:px') var max_bonknuge_distance := 4.

@export_group('Climbing', 'climb_')
@export var climb_speed_vertical := 6.
@export var climb_speed_horizontal := 4.
@export var climb_coyote_time_ticks := 10
var is_clibing := false

@export_group('Extra', 'extra_')
@export var extra_ground_dec := 8.
@export var extra_air_dec := 0.

@export_group('Shooting')
@export var shoot_ticks := 15
var shoot_timer := 0.
@export var proj_scene: PackedScene

var colors = [
	Color.RED,
	Color.YELLOW,
	Color.LIME,
	Color.CYAN,
	Color.BLUE,
	Color.MAGENTA,
]

var id := 1 :
	set(new_id):
		id = new_id
		input.set_multiplayer_authority(new_id)
		modulate = colors[id%colors.size()]

func _ready() -> void:
	calculate()

func calculate() -> void:
	jump_gravity = Calc.jump_gravity(jump_height_max*BLOCK_SIZE, jump_ticks*2/TPS)
	fall_gravity = Calc.jump_gravity(jump_height_max*BLOCK_SIZE, fall_ticks*2/TPS)
	jump_velocity_min = Calc.jump_velocity(jump_height_min*BLOCK_SIZE, jump_gravity)
	jump_velocity_max = Calc.jump_velocity(jump_height_max*BLOCK_SIZE, jump_gravity)
	max_fall_speed = jump_velocity_max*max_fall_ratio

var speed_move := 0.
var speed_extra := 0.
var speed_vertical := 0.
var direction := 1.
func _physics_process(delta: float) -> void:
	jump_buffer_timer -= delta
	if input.jump_pressed:
		input.jump_pressed = false
		jump_buffer_timer = jump_buffer_ticks/TPS
	
	action_buffer_timer -= delta
	if input.action_pressed:
		input.action_pressed = false
		action_buffer_timer = action_buffer_ticks/TPS
	
	if input.move.x != 0 and is_on_floor():
		direction = sign(input.move.x)
	flip_node.scale.x = direction
	
	if is_clibing:
		process_state_climb(delta)
	else:
		process_state_platformer(delta)
	
	shoot_timer -= delta
	if action_buffer_timer > 0:
		if shoot_timer <= 0:
			action_buffer_timer = 0
			shoot_timer = shoot_ticks/TPS
			if multiplayer.is_server():
				var proj = proj_scene.instantiate() as Projectile
				proj.transform = shoot_marker.global_transform
				proj.name = str(id) + '_' + str(counter)
				proj.modulate = modulate
				counter += 1
				get_parent().add_child(proj, true)
var counter := 0

func process_state_platformer(delta: float) -> void:
	if is_on_floor():
		is_jumping = false
	
	if ladder_dectector_area.get_overlapping_bodies().size() > 0 and input.move.y < 0 and speed_vertical > -climb_speed_vertical:
		is_clibing = true
		is_jumping = false
		return
	
	process_movement(delta)
	process_gravity(delta)
	process_jump(delta)
	move()

var jumped_from_ladder := false
func process_state_climb(delta: float) -> void:
	if ladder_dectector_area.get_overlapping_bodies().size() == 0 or (is_on_floor() and input.move.y > 0):
		is_clibing = false
		coyote_timer = climb_coyote_time_ticks/TPS
		return
	
	speed_vertical = input.move.y*climb_speed_vertical*BLOCK_SIZE
	speed_move = input.move.x*climb_speed_horizontal
	speed_extra = 0.
	
	if jump_buffer_timer > 0.:
		jump_buffer_timer = -1.
		coyote_timer = -1.
		speed_vertical = -jump_velocity_max
		is_jumping = true
		is_clibing = false
		return
	
	move()

func move() -> void:
	velocity.x = (speed_move + speed_extra)*BLOCK_SIZE
	velocity.y = speed_vertical
	
	move_and_slide()

func process_movement(delta: float) -> void:
	var is_grounded := is_on_floor()
	var is_input_opposing = speed_move != 0. and sign(speed_move) != sign(input.move.x)
	
	var speed := 0.0
	if is_grounded: # grounded movement
		if input.move.x != 0.0:
			if is_input_opposing: # opposing movement
				speed = move_speed/((move_opp_ticks/TPS)/delta)
			else:
				speed = move_speed/((move_acc_ticks/TPS)/delta)
		else:
			speed_move = move_toward(speed_move, 0., move_speed/((move_dec_ticks/TPS)/delta))
		speed_extra = move_toward(speed_extra, 0., extra_ground_dec*delta)
	else: # air movement
		if input.move.x != 0.0:
			if is_input_opposing: # opposing movement
				speed = move_speed/((move_opp_air_ticks/TPS)/delta)
			else:
				speed = move_speed/((move_acc_air_ticks/TPS)/delta)
		else:
			speed_move = move_toward(speed_move, 0., move_speed/((move_dec_air_ticks/TPS)/delta))
		speed_extra = move_toward(speed_extra, 0., extra_air_dec*delta)
	
	speed_move += input.move.x * speed
	var max_speed := move_crouch_speed if input.move.y > 0. else move_speed
	speed_move = clamp(speed_move, -max_speed, max_speed)
	
	var hit_wall_on_left := is_on_wall() and test_move(transform, Vector2.LEFT)
	var hit_wall_on_right := is_on_wall() and test_move(transform, Vector2.RIGHT)
	
	if hit_wall_on_left:
		if speed_move < 0.:
			speed_move = 0.
		if speed_extra < 0.: 
			speed_extra = 0.
	
	if hit_wall_on_right:
		if speed_move > 0.:
			speed_move = 0.
		if speed_extra > 0.: 
			speed_extra = 0.

func process_gravity(delta: float) -> void:
	if is_on_ceiling():
		if !try_bonknudge(max_bonknuge_distance*direction):
			if speed_vertical < 0.: speed_vertical = 0.
	
	if is_jumping and not input.jump_down: 
		if speed_vertical < -jump_velocity_min:
			speed_vertical = -jump_velocity_min
	
	if is_on_floor():
		if speed_vertical > 0.:
			speed_vertical = 0.
	else:
		var gravity = fall_gravity if velocity.y >= 0 else jump_gravity
		speed_vertical += gravity*delta
	
	if speed_vertical > max_fall_speed:
		speed_vertical = max_fall_speed

func try_bonknudge(distance: float) -> bool:
	var x := 0.
	while x != distance:
		if !test_move(transform.translated(Vector2(x, 0.)), Vector2.UP):
			position.x += x
			return true
		x = move_toward(x, distance, 1)
	return false

func process_jump(delta: float) -> void:
	coyote_timer -= delta
	if is_on_floor():
		coyote_timer = coyote_time_ticks / TPS
	
	if jump_buffer_timer > 0.:
		if input.move.y > 0.: # if chrouching then fall though
			#SoundBank.play('fallthrough', position)
			jump_buffer_timer = 0.
			position.y += 1.
		elif coyote_timer > 0.: # or else jump
			#SoundBank.play('jump', position)
			is_jumping = true
			coyote_timer = 0.
			jump_buffer_timer = 0.
			
			speed_vertical = -jump_velocity_max
#		else:
#			jump_buffer_timer = 0
#			if abs(speed_extra) < 4:
#				speed_vertical = -jump_velocity_max/3
#				speed_extra = direction*8
#			else:
#				speed_vertical = -jump_velocity_max
#				speed_extra = min(speed_extra, 4)
