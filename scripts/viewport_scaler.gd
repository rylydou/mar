extends Control

@export var viewport: SubViewport
@export var viewport_container: SubViewportContainer
@export var base_size := Vector2i(1920, 1080)

func _enter_tree() -> void:
	get_viewport().size_changed.connect(update_viewport)

func _ready() -> void:
	update_viewport()
	update(8)

func _process(delta: float) -> void:
	update_viewport()

func update_viewport() -> void:
	var inner := base_size
	var outer := Vector2(get_viewport().size)
	var inner_ratio := inner.x/inner.y
	var outer_ratio := outer.x/outer.y
	
	var s := 1.0
	if inner_ratio >= outer_ratio:
		s = outer.x/inner.x
	else:
		s = outer.y/inner.y
	
	scale = Vector2(s, s)
	position = (outer - inner*s)/2.


func update(scale_factor: float) -> void:
	viewport.size.x = base_size.x/scale_factor
	viewport.size.y = base_size.y/scale_factor
	viewport_container.scale = Vector2(scale_factor, scale_factor)
	
