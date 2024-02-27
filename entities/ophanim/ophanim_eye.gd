extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Worlds.player != null:
		look_at(Worlds.player.cam.global_position)
