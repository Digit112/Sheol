extends Node3D

@onready var parent : Node3D = get_parent()

func _process(_delta):
	rotation.y = -parent.theta + PI/3
