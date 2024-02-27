extends Node3D

@export var player : CharacterBody3D

func _enter_tree():
	Worlds.player = player
	Worlds.game = self

func _ready():
	Worlds.load_if_not_already("res://worlds/sheol.tscn")
	Worlds.set_active_world("Sheol")
	
	DialogueManager.connect("dialogue_ended", end_dialogue)

# Show the passed dialogue source.
# Free the cursor, disable processing on the player node.
func show_dialogue(resource : DialogueResource, title : String):
	DialogueManager.show_dialogue_balloon(resource, title)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	Worlds.player.set_process(false)
	Worlds.player.set_physics_process(false)
	Worlds.player.set_process_input(false)

# Capture the cursor and enable processing on the player.
func end_dialogue(_resource : DialogueResource):
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	Worlds.player.set_process(true)
	Worlds.player.set_physics_process(true)
	Worlds.player.set_process_input(true)
