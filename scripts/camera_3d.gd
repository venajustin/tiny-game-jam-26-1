extends Camera3D

@onready var pos_target := self.get_parent()
@onready var look_target:Node3D = find_parent("Player").find_child("CameraLookTarget")

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
