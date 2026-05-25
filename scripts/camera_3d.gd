extends Camera3D

@onready var pos_target := self.get_parent()
@onready var look_target:Node3D = find_parent("Player").find_child("CameraLookTarget")
@onready var player = find_parent("Player")
@export var highlight_threshhold = 100.0

signal highlight_outlet(show:bool, screen_pos:Vector2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	#var dist = (pos_target.global_transform.origin - self.global_transform.origin).length()
	#var target_speed = 2**dist
	#self.global_transform.origin = \
		#self.global_transform.origin.move_toward(
			#pos_target.global_transform.origin, 
			#delta * target_speed
			#)
	look_at(look_target.global_position)
	
	#Testing for outlets in screen center
	var closest = null
	var closest_pos = null
	var screen_center:Vector2 = get_viewport().get_size() / 2
	for outlet in get_tree().get_nodes_in_group("attach-point"):
		var projection = unproject_position(outlet.global_transform.origin)
		var notifier :VisibleOnScreenNotifier3D = outlet.get_node(outlet.get_meta("screen_notifier"))
		
		var origin = self.global_position
		var end = outlet.global_position
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.exclude = [player]
		
		var space_state := get_world_3d().direct_space_state
		var result := space_state.intersect_ray(query)
		
		if result:
			if result.collider == outlet:
				print(notifier.is_on_screen())
				if notifier.is_on_screen() and abs((projection - screen_center).length()) < highlight_threshhold:
					if closest == null or abs((projection - screen_center).length()) < abs((closest_pos - screen_center).length()):
						closest = outlet
						closest_pos = projection
		
		
	if closest != null:
		highlight_outlet.emit(true, closest_pos)
	else:
		highlight_outlet.emit(false, Vector2(0,0))

	
