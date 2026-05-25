extends Control

@onready var primary_cont = $Control/PrimaryControls
@onready var secondary_cont = $Control/SecondaryControls
@onready var crosshair = $Croshair
@onready var high = $highlight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	player.connect("display_crosshair", on_display_crosshair)
	player.connect("set_controls_mode", on_set_controls_mode)
	secondary_cont.visible = false
	crosshair.visible = false
	player.find_child("Camera3D").connect("highlight_outlet", on_highlight_object)
	high.visible = false

func set_primary():
	secondary_cont.visible = false
	primary_cont.visible = true

func set_secondary():
	secondary_cont.visible = true
	primary_cont.visible = false

func on_display_crosshair(yesorno:bool):
	crosshair.visible = yesorno
	
func on_set_controls_mode(primary:bool):
	if primary:
		set_primary()
	else:
		set_secondary()

func on_highlight_object(show:bool, location:Vector2):
	if show:
		high.visible = true
		high.position = location
	else:
		high.visible = false
	
