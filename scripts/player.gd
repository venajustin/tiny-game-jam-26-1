extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FRICTION = 5.0
const PLAYER_ACC = 35.0
const FLOOR_FRICTION = 20.0
const MOUSE_SENSITIVITY = -.003

@export var boost_speed := 30.0
@export var plug_speed := 15.0
@export var turn_speed := 1.0
@export var cam_offset_ammount := 2.0
@export var ray_length := 50.0
@export var plug_scene:PackedScene = null
@export var cable_scene:PackedScene = null
@export var world:Node3D = null

@onready var cam_pivot = $CameraPivot
@onready var cam_look_pivot = $CameraLookPivot
@onready var cam_look_target = $CameraLookPivot/CameraLookTarget
@onready var cam_target = $CameraPivot/CameraTarget
@onready var cam:Camera3D = $CameraPivot/CameraTarget/Camera3D
@onready var connpoint = find_child("ConnectionPoint")
@onready var model_vac_core = $"Vacum-2/Cube_001"

var backing_up := false
var breaking = false

var current_angle := 0.0
var max_look_degrees := 89
var max_look_rad := (PI / 2) - .1

var tilt_angle_start = 0;

var point_dir := 0.0

var active_plug = null
var active_cable = null
var active_conn_point = null

var connected := false
var powered := false
var stopped_timer := 0.0

signal display_crosshair(yes:bool)

#var camera_cart_speed := cam_cart_max_speed
#var cam_cart_max_speed := 30.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	tilt_angle_start = model_vac_core.rotation.x
	display_crosshair.emit(true)

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
			breaking = true
			stopped_timer = 0
			velocity = velocity.move_toward(Vector3(0,0,0), delta * FLOOR_FRICTION * 1.75)
		elif breaking == false:
			backing_up = true
			if velocity.length() < plug_speed / 2:
				velocity = global_basis.z * plug_speed / 2
		else:
			stopped_timer += delta
			if stopped_timer > .2:
				breaking = false
	if Input.is_action_just_released("back"):
		breaking = false

	
	if backing_up:
		turn_input = -turn_input
	velocity = velocity.rotated(Vector3(0, 1, 0),  delta * turn_input * turn_speed )
	
	#if velocity.length() > 0:
		#if backing_up:
			#point_dir = Vector2(-velocity.x, -velocity.z).angle_to(Vector2(0, -1))
		#else:
			#point_dir = Vector2(velocity.x, velocity.z).angle_to(Vector2(0, -1))
	
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
		
	
	if not connected and Input.is_action_pressed("secondary"):
		cam_target.position.z = move_toward(cam_target.position.z, 4, delta * 40)
		cam.position.x = move_toward(cam.position.x, cam_offset_ammount, delta* 20)
		cam_look_target.position.x = move_toward(cam_look_target.position.x, cam_offset_ammount, delta* 20 )
	else: 
		cam_target.position.z = move_toward(cam_target.position.z, 9, delta * 40)
		cam.position.x = move_toward(cam.position.x, 0, delta* 20)
		cam_look_target.position.x = move_toward(cam_look_target.position.x, 0, delta* 20 )
		
	if connected and Input.is_action_pressed("secondary"):
		
		var boost_dir:Vector3 = (active_conn_point.global_position - active_cable.global_position).normalized()
		var vac_dir:Vector3 = -global_basis.z
		
		if powered:
			if is_on_floor():
				# boost
				if velocity.dot(vac_dir) < boost_dir.dot(vac_dir) * boost_speed:
					velocity -= vac_dir * velocity.dot(vac_dir) 
					velocity += vac_dir * boost_dir.dot(vac_dir) * boost_speed
			else:
				if velocity.dot(boost_dir) < boost_speed:
					velocity -= velocity.dot(boost_dir) * boost_dir 
					velocity += boost_dir * boost_speed
		
		# Swinging
		if velocity.dot(boost_dir) < 0:
			velocity -= velocity.dot(boost_dir) * boost_dir
			
	
	
	
	if connected:
		active_cable.look_at(active_conn_point.global_position)
		active_cable.scale.z = (active_conn_point.global_position - active_cable.global_position).length()

	
	
	move_and_slide()



func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		cam_pivot.rotate_y(event.relative.x * MOUSE_SENSITIVITY)
		cam_look_pivot.rotate_y(event.relative.x * MOUSE_SENSITIVITY)
		
		if event.relative.y < 0 and cam_pivot.rotation.x < max_look_rad:
			cam_pivot.rotate_object_local(Vector3.RIGHT, event.relative.y * MOUSE_SENSITIVITY)
			cam_look_pivot.rotate_object_local(Vector3.RIGHT, event.relative.y * MOUSE_SENSITIVITY)
		if event.relative.y > 0 and cam_pivot.rotation.x > -max_look_rad:
			cam_pivot.rotate_object_local(Vector3.RIGHT, event.relative.y * MOUSE_SENSITIVITY)
			cam_look_pivot.rotate_object_local(Vector3.RIGHT, event.relative.y * MOUSE_SENSITIVITY)
		
		#var input_dir: float = event.relative.y
		#var angle_change = input_dir * MOUSE_SENSITIVITY
		#current_angle += angle_change
		#current_angle = clamp(current_angle, deg_to_rad(-max_look_degrees), deg_to_rad(max_look_degrees))
		#cam_pivot.transform.basis = Basis.from_euler(Vector3(current_angle, cam_pivot.transform.basis.rotation.y, cam_pivot.transform.basis.rotation.z))
	
	if event.is_action_pressed("primary"):
		fire_cable()
		
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	

func fire_cable():
	if not connected:
		var screen_size := get_viewport().get_visible_rect().size
		var screen_center := screen_size / 2
		var origin := cam.project_ray_origin(screen_center)
		var direction := cam.project_ray_normal(screen_center)
		var end := origin + direction * ray_length
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.exclude = [self]
		
		var space_state := get_world_3d().direct_space_state
		var result := space_state.intersect_ray(query)
		
		if result:
			powered = false
			if result.collider.is_in_group("attach-point"):
				print("OUTLET HIT")
				powered = true
			create_cable(result.position, result.normal)
			print("Hit object: ", result.collider.name)
	else:
		active_plug.queue_free()
		active_cable.queue_free()
		active_conn_point = null
		connected = false

func create_cable(pos:Vector3, norm:Vector3):
	var nplug:Node3D = plug_scene.instantiate()
	world.add_child(nplug)
	nplug.position = pos
	nplug.look_at(nplug.global_position - norm, Vector3.UP)
	connected = true
	active_plug = nplug
	
	var ncable:Node3D = cable_scene.instantiate()
	connpoint.add_child(ncable)
	ncable.look_at(nplug.position)
	ncable.scale.z = (nplug.position - ncable.position).length()
	active_cable = ncable
	active_conn_point = nplug.find_child("wire_connection")
	
	
	
