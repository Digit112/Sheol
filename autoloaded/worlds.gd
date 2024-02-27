extends Node

var debug = true

var active_world : World = null

# The player and game nodes. Values set by the Game node in _enter_tree
var player : CharacterBody3D
var game : Node3D

# This script keeps track of which worlds are loaded and the merkabahs they contain.

class World:
	var res_path : String
	var world_root : Node3D
	var world_name : String
	
	func _init(res_path_init : String, world_root_init : Node3D, world_name_init : String):
		self.res_path = res_path_init
		self.world_root = world_root_init
		self.world_name = world_name_init

class Merkabah:
	var merkabah_node : Node3D
	var name : String
	
	func _init(merkabah_node_init : Node3D):
		self.merkabah_node = merkabah_node_init
		self.name = merkabah_node.unique_name

# All loaded worlds.
var worlds : Array[World]

# All merkabahs in all loaded worlds.
var merkabahs : Array[Merkabah]

# Loads the given scene.
# Does not add it to the scene tree.
# Call set_active_world(world_name) to do so.
# The world name is the world's root node's name.
# Returns the name of the world.
func load_if_not_already(res_path : String) -> String:
	for w in worlds:
		if w.res_path == res_path:
			return w.world_name
	
	var world = load(res_path).instantiate()
	worlds.append(World.new(res_path, world, world.name))
	
	return world.name

# Sets the given world as active and disables the current active world if it exists.
# The world name is the world's root node's name.
func set_active_world(world_name : String):
	if active_world != null and world_name == active_world.world_name:
		return
	
	for w in worlds:
		if w.world_name == world_name:
			if active_world != null:
				active_world.world_root.get_parent().remove_child(active_world.world_root)
			
			get_tree().root.add_child.call_deferred(w.world_root)
			active_world = w
			print("active: " + active_world.world_name)
			return
	
	print("No loaded world with the name \"" + world_name + "\"")

func register_merkabah(merkabah_node : Node3D):
	for i in merkabahs:
		if i.merkabah_node.unique_name == merkabah_node.unique_name:
			return
	
	print("Registration accepted.")
	merkabahs.append(Merkabah.new(merkabah_node))

# Returns the named merkabah or null if it doesn't exist.
func get_merkabah(merkabah_name : String):
	for m in merkabahs:
		if m.merkabah_node.is_inside_tree() and m.name == merkabah_name:
			return m.merkabah_node
	
	print("No merkabah named \"" + merkabah_name + "\"")
	return null
