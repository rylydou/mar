class_name Projectile extends CharacterBody2D

@export var lifetime := 1.

@export var distance_as_speed := false
@export var distance_over_lifetime: Curve

@export var offset_over_lifetime: Curve

@onready var starting_position := position
@onready var direction := transform.basis_xform(Vector2.RIGHT)
@onready var p_direction := transform.basis_xform(Vector2.UP)

var age := 0.
var distance := 0.
func _physics_process(delta: float) -> void:
	age += delta
	var ratio := age/lifetime
	if age >= lifetime:
		destroy()
		return
	
	if distance_as_speed:
		distance += distance_over_lifetime.sample_baked(ratio)*8*delta
	else:
		distance = distance_over_lifetime.sample_baked(ratio)*8
	
	var offset = 0
	if offset_over_lifetime:
		offset = offset_over_lifetime.sample_baked(ratio)*8
	
	var target = starting_position + direction*distance + p_direction*offset
	if move_and_collide(target - position):
		destroy()
		return
	
	position = target

func destroy() -> void:
	if multiplayer.is_server():
		queue_free()
