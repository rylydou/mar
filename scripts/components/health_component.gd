extends Node

@export var base_health = 1
@onready var health = base_health

func take_damage(damage: int) -> bool:
	return false
