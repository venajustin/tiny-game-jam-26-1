extends Area3D

@onready var animator = $"Dust Bunies_anims/AnimationPlayer"

var life_state = "ALIVE"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var anim = $"Dust Bunies_anims/AnimationPlayer".get_animation("Idle")
	anim.loop_mode = Animation.LOOP_LINEAR 
	animator.play("Idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and life_state == "ALIVE":
		animator.play("Alert")
		life_state = "QUEUE_DEAD"
		body.add_bunny()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if life_state == "QUEUE_DEAD":
		self.queue_free()
