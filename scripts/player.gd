extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FRICTION = 5.0
const PLAYER_ACC = 35.0
const FLOOR_FRICTION = 5.0
const MOUSE_SENSITIVITY = -.003

@export var boost_speed := 30.0
@export var plug_speed := 15.0
@export var plug_acc := 30
@export var turn_speed := 1.0
@export var cam_offset_ammount := 2.0
@export var ray_length := 300.0
@export var plug_scene:PackedScene = null
@export var cable_scene:PackedScene = null
@export var world:Node3D = null

@onready var cam_pivot = $CameraPivot
@onready var cam_look_pivot = $CameraLookPivot
@onready var cam_look_target = $CameraLookPivot/CameraLookTarget
@onready var cam_target = find_child("CameraTarget")
@onready var cam:Camera3D = find_child("Camera3D")
@onready var connpoint = find_child("ConnectionPoint")
@onready var model_vac_core = $"Vacum-2/Cube_001"
@onready var spring_arm = $CameraPivot/SpringArm3D

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
var last_bend_norm = null

var connected := false
var powered := false
var stopped_timer := 0.0

var bend_count := 0

signal display_crosshair(yes:bool)
signal set_controls_mode(primary_controls: bool)

#var camera_cart_speed := cam_cart_max_speed
#var cam_cart_max_speed := 30.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	tilt_angle_start = model_vac_core.rotation.x
	display_crosshair.emit(true)
	spring_arm.add_excluded_object(self)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# friction
		velocity += -velocity.normalized() * delta * FLOOR_FRICTION
	
	var move_input = Input.get_axis("back", "forward")
	var turn_input = Input.get_axis("right","left")

	if is_on_floor():
		backing_up = false
		if move_input > 0:
			if velocity.dot(global_basis.z) > -plug_speed:
				velocity += -global_basis.z * delta * plug_acc 
		if move_input < 0:
			if velocity.dot(global_basis.z) > -0.001:
				backing_up = true
				if velocity.dot(global_basis.z) < plug_speed *.75:
					velocity += global_basis.z * delta * plug_acc *.75 
			else:
				velocity += global_basis.z * delta * plug_acc 
	
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
		# cam_target.position.z = move_toward(cam_target.position.z, 4, delta * 40)
		spring_arm.spring_length = move_toward(cam_target.position.z, 4, delta * 40)
		cam.position.x = move_toward(cam.position.x, cam_offset_ammount, delta* 20)
		cam_look_target.position.x = move_toward(cam_look_target.position.x, cam_offset_ammount, delta* 20 )
	else: 
		# cam_target.position.z = move_toward(cam_target.position.z, 9, delta * 40)
		spring_arm.spring_length = move_toward(cam_target.position.z, 9, delta * 40)
		cam.position.x = move_toward(cam.position.x, 0, delta* 20)
		cam_look_target.position.x = move_toward(cam_look_target.position.x, 0, delta* 20 )
		
	if connected and Input.is_action_pressed("pull"):
		
		var boost_dir:Vector3 = (active_conn_point.global_position - active_cable.global_position).normalized()
		var vac_dir:Vector3 = -global_basis.z
		
		# powered = true # quick override
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
		#if last_bend_norm != null and bend_count > 0:
			#check_cable_release()
		#check_cable_intersections()
		
	
	move_and_slide()

func check_cable_intersections():
	
	var origin = active_cable.global_position
	var end = active_conn_point.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	
	var space_state := get_world_3d().direct_space_state
	var result := space_state.intersect_ray(query)
	
	if result:
		last_bend_norm = result.normal
		new_cable_linkage(result.position)
	

func check_cable_release():
	var dir = (active_cable.global_position - active_conn_point.global_position ).normalized()
	if last_bend_norm.dot(dir) > 0:
		remove_cable_linkage()


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		cam_pivot.rotate_y(event.screen_relative.x * MOUSE_SENSITIVITY)
		cam_look_pivot.rotate_y(event.screen_relative.x * MOUSE_SENSITIVITY)
		
		if event.screen_relative.y < 0 and cam_pivot.rotation.x < max_look_rad:
			cam_pivot.rotate_object_local(Vector3.RIGHT, event.screen_relative.y * MOUSE_SENSITIVITY)
			cam_look_pivot.rotate_object_local(Vector3.RIGHT, event.screen_relative.y * MOUSE_SENSITIVITY)
		if event.screen_relative.y > 0 and cam_pivot.rotation.x > -max_look_rad:
			cam_pivot.rotate_object_local(Vector3.RIGHT, event.screen_relative.y * MOUSE_SENSITIVITY)
			cam_look_pivot.rotate_object_local(Vector3.RIGHT, event.screen_relative.y * MOUSE_SENSITIVITY)
		
		#var input_dir: float = event.screen_relative.y
		#var angle_change = input_dir * MOUSE_SENSITIVITY
		#current_angle += angle_change
		#current_angle = clamp(current_angle, deg_to_rad(-max_look_degrees), deg_to_rad(max_look_degrees))
		#cam_pivot.transform.basis = Basis.from_euler(Vector3(current_angle, cam_pivot.transform.basis.rotation.y, cam_pivot.transform.basis.rotation.z))
	
	if  event.is_action_pressed("primary"):
		fire_cable()

		
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_left"):
		remove_cable_linkage()

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
			display_crosshair.emit(false)
			set_controls_mode.emit(false)
			powered = false
			if result.collider.is_in_group("attach-point"):
				print("OUTLET HIT")
				powered = true
			create_cable(result.position, result.normal)
			print("Hit object: ", result.collider.name)
	else:
		display_crosshair.emit(true)
		set_controls_mode.emit(true)
		while active_plug.name == "Cable":
			remove_cable_linkage()
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
	active_conn_point = nplug.find_child("wire_connection")
	
	var ncable:Node3D = cable_scene.instantiate()
	connpoint.add_child(ncable)
	active_cable = ncable
	
func new_cable_linkage(point:Vector3):
	active_cable.reparent(world)
	active_cable.position = point
	active_cable.add_pivot(active_plug, last_bend_norm)
	
	active_plug = active_cable
	active_conn_point = active_cable.find_child("wire_connection")
	
	var ncable:Node3D = cable_scene.instantiate()
	connpoint.add_child(ncable)
	active_cable = ncable
	bend_count+= 1

func remove_cable_linkage() -> bool:
	if active_plug.name != "Cable":
		return false

	var old_cable = active_cable
	old_cable.queue_free()

	active_cable = active_plug
	active_cable.reparent(connpoint)
	last_bend_norm = active_cable.get_last_bend()
	active_plug = active_cable.remove_pivot()
	bend_count-= 1
	active_conn_point = active_plug.find_child("wire_connection")

	return true
