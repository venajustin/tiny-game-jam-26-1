extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FRICTION = 5.0
const PLAYER_ACC = 35.0
const FLOOR_FRICTION = 20.0
const MOUSE_SENSITIVITY = -.003

@export var plug_speed := 15.0
@export var turn_speed := 1.0
@onready var cam_pivot = $CameraPivot
@onready var cam_target = $CameraPivot/CameraTarget

@onready var model_vac_core = $"Vacum-2/Cube_001"

var backing_up := false

var current_angle := 0.0
var max_look_degrees := 89
var max_look_rad := (PI / 2) - .1

var tilt_angle_start = 0;

var point_dir := 0.0

#var camera_cart_speed := cam_cart_max_speed
#var cam_cart_max_speed := 30.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	tilt_angle_start = model_vac_core.rotation.x

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# friction
		velocity = velocity.move_toward(Vector3(0,0,0), delta * FLOOR_FRICTION)
	
	
	var move_input = Input.get_axis("back", "forward")
	var turn_input = Input.get_axis("right","left")
	
	# temp movement
	if move_input > 0:
		if backing_up:
			backing_up = false
			velocity = -global_basis.z * plug_speed
		if velocity.length() < plug_speed:
			velocity = -global_basis.z * plug_speed
	if move_input < 0:
		if velocity.dot(-global_basis.z) > 0.0:
			# breaking
			velocity = velocity.move_toward(Vector3(0,0,0), delta * FLOOR_FRICTION * 3)
		else:
			backing_up = true
			if velocity.length() < plug_speed / 2:
				velocity = global_basis.z * plug_speed / 2
	
	if backing_up:
		turn_input = -turn_input
	velocity = velocity.rotated(Vector3(0, 1, 0),  delta * turn_input * turn_speed )
	
	if velocity.length() > 0:
		if backing_up:
			point_dir = Vector2(-velocity.x, -velocity.z).angle_to(Vector2(0, -1))
		else:
			point_dir = Vector2(velocity.x, velocity.z).angle_to(Vector2(0, -1))

	else:
		point_dir += delta * turn_input * turn_speed
	
	rotation.y = point_dir
		
	if velocity.dot(global_basis.z) < 0:
		var tmp_vel = velocity.dot(global_basis.z)
		if tmp_vel > 30.0:
			tmp_vel = 30.0
		tmp_vel = tmp_vel / 30.0
		model_vac_core.rotation.x = (tilt_angle_start - lerp(0.0, PI/4, tmp_vel))
	else:
		model_vac_core.rotation.x = (tilt_angle_start)
		
		
	#if camera_cart_speed > 0 and cam_target.position.z <= 9.0:
		#cam_target.position.z = cam_target.position.z + camera_cart_speed * delta
	#if camera_cart_speed < 0 and cam_target.position.z >= 2.0:
		#cam_target.position.z = cam_target.position.z + camera_cart_speed * delta
		
	
	move_and_slide()


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		cam_pivot.rotate_y(event.relative.x * MOUSE_SENSITIVITY)
		if event.relative.y < 0 and cam_pivot.rotation.x < max_look_rad:
			cam_pivot.rotate_object_local(Vector3.RIGHT, event.relative.y * MOUSE_SENSITIVITY)
		if event.relative.y > 0 and cam_pivot.rotation.x > -max_look_rad:
			cam_pivot.rotate_object_local(Vector3.RIGHT, event.relative.y * MOUSE_SENSITIVITY)
		
		#var input_dir: float = event.relative.y
		#var angle_change = input_dir * MOUSE_SENSITIVITY
		#current_angle += angle_change
		#current_angle = clamp(current_angle, deg_to_rad(-max_look_degrees), deg_to_rad(max_look_degrees))
		#cam_pivot.transform.basis = Basis.from_euler(Vector3(current_angle, cam_pivot.transform.basis.rotation.y, cam_pivot.transform.basis.rotation.z))
		
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		

func _on_cam_detector_body_entered(body: Node3D) -> void:
	# camera_cart_speed = -cam_cart_max_speed
	pass

func _on_cam_detected_body_exited(body: Node3D) -> void:
	# camera_cart_speed = cam_cart_max_speed
	pass
