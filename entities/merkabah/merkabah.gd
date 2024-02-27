extends Node3D

@export var unique_name : String

# The name of the merkabah this will teleport the player to.
@export var dest_merkabah : String

# The name of the scene containing the destination merkabah.
# When the player attempts to teleport, this scene will be loaded if it isn't already.
@export var dest_world_res_path : String

# Range at which this merkabah effects the player.
@export var effect_radius : float = 4

# This collider cannot be detected, but it can detect layer 8, which should only contain the player.
@export var collider : Area3D

# Merkabah will not teleport players if this value is true.
var is_disabled : bool = false

# After the player leaves the collider of a disabled merkabah,
# It will be reenabled when this timer counts down.
var disabled_timer : float = 0

func _enter_tree():
	Dialogue.sheol_merkabah = self
	print("Registering " + self.unique_name)
	Worlds.register_merkabah(self)
	disable()

func disable():
	is_disabled = true

# If called while the counter is already running,
# or while the merkabah is already enabled, does nothing.
func start_enable_countdown():
	if disabled_timer <= 0 and is_disabled == true:
		disabled_timer = 0.5
		set_process(true)

func _process(delta):
	if disabled_timer > 0:
		disabled_timer -= delta
		
		# If broken into an else block, merkabah will be re-enabled next frame.
		# character_controlled may have restarted the timer in the meantime...
		if disabled_timer <= 0:
			is_disabled = false
			set_process(false)
