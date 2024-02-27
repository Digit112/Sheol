extends Node3D

@export var collider : StaticBody3D

var movement : Vector3 = Vector3(0, 0, 0)

func _ready():
	Dialogue.sheol_ophanim = self
	Worlds.player.connect("on_interactable_clicked", on_interactable_clicked)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if movement.length_squared() > 0.01 and \
	global_position.length_squared() < 7000:
		translate(movement * delta)

func on_interactable_clicked(clicked_collider : CollisionObject3D):
	if clicked_collider == collider:
		Worlds.game.show_dialogue(
			load("res://dialogue/ophanim_introduction.dialogue"),
			"ophanim_introduction"
		)
