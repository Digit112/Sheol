extends CharacterBody3D

# Emitted with the result of raycasts run on player clicks.
# Allows objects to detect when the player clicks interactables (on layer 7)
# Only passes the colided object closest to the camera.
signal on_interactable_clicked(collider : CollisionObject3D);

## The distance from which the player can click on a collider.
@export var interaction_range : float

@export var cam : Camera3D
@export var tp_collider : Area3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# When teleporting, a new world may need to be loaded.
# In this case, we must wait one frame for the merkabahs in that world to register themselves.
# When these variables are set, a teleportation will be attempted every frame until it succeeds.
# Then the variables will be reset.
var queued_tp_dest_name : String = ""
var queued_tp_rel_pos : Vector3

# When the player clicks, these will be used to query a raycast on the next frame.
# The query will only identify colliders on layer 7 "interactables"
var is_raycast_queued : bool = false

# When greater than 0, arrow keys don't move the player.
# Set to a low value after teleporting.
var movement_deadlock_timer : float = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Rotate the player body and camera some fraction of what is necessary to look at the target.
func look_torward(target: Vector3, t : float):
	var facing_dir = to_global(Vector3(0, 0, -1)) - cam.global_position
	var target_diff = target - cam.global_position
	
	var hori_angle = Vector2(
		facing_dir.x, facing_dir.z
	).angle_to(Vector2(
		target_diff.x, target_diff.z
	))
	if hori_angle > PI:
		hori_angle = -2*PI + hori_angle
	
	rotate_y(-hori_angle * t)
	
	var cam_target_diff = cam.to_local(target)
	var veri_angle = Vector2(
		0, -1
	).angle_to(Vector2(
		cam_target_diff.y, -abs(cam_target_diff.z)
	))
	if veri_angle > PI:
		veri_angle = -2*PI + veri_angle
	
	cam.rotate_x(veri_angle * t)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if movement_deadlock_timer > 0:
		movement_deadlock_timer -= delta

func _physics_process(delta):
	# Perform any queued raycast.var space_state = get_world_2d().direct_space_state
	if is_raycast_queued:
		var origin = cam.global_position
		var target = cam.to_global(Vector3(0, 0, -interaction_range))
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			origin, target, 64
		)
		var result = space_state.intersect_ray(query)
		
		is_raycast_queued = false
		
		if result != {}:
			on_interactable_clicked.emit(result["collider"])
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and movement_deadlock_timer <= 0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Find nearest Merkabah that the player is within the effect range of.
	var min_merkabah_dist = 10
	var nearest_merkabah : Node3D
	for merkabah_obj in Worlds.merkabahs:
		var merkabah = merkabah_obj.merkabah_node
		
		# Exclude merkabahs registered by other worlds than the one which is active.
		if merkabah.is_inside_tree():
			var merkabah_center = merkabah.to_global(Vector3(0, 0.408, 0))
			var merkabah_dist = cam.global_position.distance_to(merkabah_center)
			if merkabah_dist < min_merkabah_dist and merkabah_dist < merkabah.effect_radius:
				min_merkabah_dist = merkabah_dist
				nearest_merkabah = merkabah
	
	# Apply Merkabah effects if the nearest is close enough.
	if nearest_merkabah != null:
		var merkabah_center = nearest_merkabah.to_global(Vector3(0, 0.408, 0))
		var effect_r = nearest_merkabah.effect_radius
		
		var merkabah_repulse_mul = (merkabah_center - cam.global_position).normalized() * \
			(1.3 - 1.3/effect_r * min_merkabah_dist)
		
		# Disabled merkabahs repel much more.
		if nearest_merkabah.is_disabled:
			merkabah_repulse_mul *= 1 + nearest_merkabah.disabled_timer*3
		
		# Rotate the camera towards the merkabah core
		look_torward(merkabah_center, -0.18 / effect_r * (min_merkabah_dist - effect_r))
		
		# Apply effects
		cam.fov = 100.0 / effect_r * (min_merkabah_dist - effect_r) + 75
	
		velocity += Vector3(
			-SPEED * merkabah_repulse_mul.x,
			0,
			-SPEED * merkabah_repulse_mul.z
		)
		
		# If nearest merkabah is close enough and enabled,
		# Teleport the player to its target.
		if tp_collider in nearest_merkabah.collider.get_overlapping_areas():
			if not nearest_merkabah.is_disabled and nearest_merkabah.dest_merkabah != "":
				var pos = nearest_merkabah.to_local(global_position)
				
				# Load the world containing the destination if necessary.
				if nearest_merkabah.dest_world_res_path != "":
					var w_name = Worlds.load_if_not_already(nearest_merkabah.dest_world_res_path)
					Worlds.set_active_world(w_name)
				
				queued_tp_dest_name = nearest_merkabah.dest_merkabah
				queued_tp_rel_pos = pos
		else:
			nearest_merkabah.start_enable_countdown()
	else:
		# Remove fov change from the last time the player was near a merkabah.
		cam.fov = 75
	
	if queued_tp_dest_name != "":
		# Get the destination merkabah.
		# Only possible if the world was already loaded
		# and _ready was called.
		var dest = Worlds.get_merkabah(queued_tp_dest_name)
		if dest != null:
			dest.disable()
			
			# Teleport the player to the destination merkabah.
			# They retain velocity and position in the nearest merkabah's local coordinates.
			global_position = dest.to_global(queued_tp_rel_pos)
			look_torward(dest.to_global(Vector3(0, 0.408, 0)), 1)
			movement_deadlock_timer = 0.5
			
			queued_tp_dest_name = ""
	
	move_and_slide()

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseMotion:
		rotate(Vector3(0, -1, 0), event.relative.x * 0.1 * PI / 180)
		cam.rotate_object_local(Vector3(-1, 0, 0), event.relative.y * 0.1 * PI / 180)
		
		cam.rotation.x = clamp(cam.rotation.x, -PI/2, PI/2)
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == 1:
		is_raycast_queued = true
