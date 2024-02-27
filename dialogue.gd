extends Node

# Contains state for the dialogue system.

func hello():
	print("Hello Dialogue!")

# Ophanim in Sheol.
var sheol_ophanim : Node3D
var sheol_merkabah : Node3D

var has_agreed_to_leave : bool = false
var has_met_ophanim : bool = false

func spawn_merkabah():
	var dir = Worlds.player.global_position - sheol_ophanim.global_position
	dir = dir.normalized() * 8
	dir += Worlds.player.global_position
	sheol_merkabah.global_position = Vector3(
		dir.x,
		0.408,
		dir.z
	) 

func ophanim_leave():
	var dir = sheol_ophanim.global_position - Worlds.player.global_position
	dir = dir.normalized() * 10
	
	sheol_ophanim.movement = dir
