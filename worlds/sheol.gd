extends Node3D

# Called when this world is unloaded.
# Use it for cleanup.
func _on_world_unload():
	pass

func _process(_delta):
	if abs(Worlds.player.global_position.x) > 40:
		Worlds.player.global_position.x *= -1
	
	if abs(Worlds.player.global_position.z) > 40:
		Worlds.player.global_position.z *= -1
