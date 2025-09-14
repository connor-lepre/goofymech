# OrbitCamera.gd
# Helicopter-style orbiting camera with realistic shake
# Attach this script to your OverheadCamera (Camera3D) inside the SubViewport

extends Camera3D

# Target to orbit around
@export var target: Node3D  # Drag your robot here in the inspector

# Orbit settings
@export_group("Orbit Settings")
@export var orbit_distance: float = 15.0
@export var orbit_height: float = 8.0
@export var orbit_speed: float = 30.0  # degrees per second

# Camera behavior
@export_group("Camera Behavior")
@export var follow_target: bool = true
@export var smooth_follow: bool = true
@export var follow_speed: float = 5.0

# Helicopter shake settings
@export_group("Helicopter Shake")
@export var enable_shake: bool = true
@export var shake_intensity: float = 0.3
@export var shake_speed: float = 8.0
@export var vertical_shake_multiplier: float = 0.5
@export var rotation_shake_intensity: float = 1.0

# Internal variables
var orbit_angle: float = 0.0
var target_position: Vector3 = Vector3.ZERO
var shake_time: float = 0.0
var base_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Try to find the robot automatically if not assigned
	if not target:
		target = get_node_or_null("../../Robot")  # Adjust path as needed
		if target:
			print("OrbitCamera: Automatically found target: ", target.name)
		else:
			print("OrbitCamera: No target found! Please assign in inspector.")

func _process(delta: float) -> void:
	if not target:
		return
	
	# Update orbit angle
	orbit_angle += orbit_speed * delta
	if orbit_angle >= 360.0:
		orbit_angle -= 360.0
	
	# Update shake time
	shake_time += delta
	
	# Calculate target position to follow
	var new_target_pos = target.global_position
	
	if smooth_follow and follow_target:
		# Smoothly move towards target
		target_position = target_position.lerp(new_target_pos, follow_speed * delta)
	else:
		# Instantly follow target
		target_position = new_target_pos
	
	# Calculate base orbit position (without shake)
	base_position = calculate_orbit_position()
	
	# Apply helicopter shake
	var final_position = base_position
	var final_rotation = Vector3.ZERO
	
	if enable_shake:
		var shake_offset = calculate_helicopter_shake()
		final_position += shake_offset
		final_rotation = calculate_rotation_shake()
	
	# Set camera position and rotation
	global_position = final_position
	
	# Look at target with shake applied to rotation
	look_at(target_position, Vector3.UP)
	
	# Apply additional rotation shake
	if enable_shake:
		rotation.x += final_rotation.x
		rotation.y += final_rotation.y
		rotation.z += final_rotation.z

func calculate_orbit_position() -> Vector3:
	# Convert angle to radians
	var angle_rad = deg_to_rad(orbit_angle)
	
	# Calculate orbit position
	var x = target_position.x + orbit_distance * cos(angle_rad)
	var z = target_position.z + orbit_distance * sin(angle_rad)
	var y = target_position.y + orbit_height
	
	return Vector3(x, y, z)

func calculate_helicopter_shake() -> Vector3:
	# Multi-layered noise for realistic helicopter movement
	var shake_x = sin(shake_time * shake_speed) * shake_intensity
	shake_x += sin(shake_time * shake_speed * 1.7) * shake_intensity * 0.3
	shake_x += sin(shake_time * shake_speed * 2.3) * shake_intensity * 0.1
	
	var shake_z = cos(shake_time * shake_speed * 1.3) * shake_intensity  
	shake_z += cos(shake_time * shake_speed * 1.9) * shake_intensity * 0.3
	shake_z += cos(shake_time * shake_speed * 2.7) * shake_intensity * 0.1
	
	# Vertical shake (less intense - helicopters are more stable vertically)
	var shake_y = sin(shake_time * shake_speed * 0.8) * shake_intensity * vertical_shake_multiplier
	shake_y += cos(shake_time * shake_speed * 1.1) * shake_intensity * vertical_shake_multiplier * 0.2
	
	return Vector3(shake_x, shake_y, shake_z)

func calculate_rotation_shake() -> Vector3:
	# Subtle rotation shake for camera instability
	var rot_x = sin(shake_time * shake_speed * 0.7) * deg_to_rad(rotation_shake_intensity)
	var rot_y = cos(shake_time * shake_speed * 0.9) * deg_to_rad(rotation_shake_intensity * 0.5)  
	var rot_z = sin(shake_time * shake_speed * 1.2) * deg_to_rad(rotation_shake_intensity * 0.8)
	
	return Vector3(rot_x, rot_y, rot_z)

# Public functions to control the camera
func set_orbit_speed(new_speed: float) -> void:
	orbit_speed = new_speed

func set_orbit_distance(new_distance: float) -> void:
	orbit_distance = new_distance

func set_orbit_height(new_height: float) -> void:
	orbit_height = new_height

func set_shake_intensity(intensity: float) -> void:
	shake_intensity = intensity

func enable_helicopter_shake(enabled: bool) -> void:
	enable_shake = enabled

func pause_orbit() -> void:
	orbit_speed = 0.0

func resume_orbit(speed: float = 30.0) -> void:
	orbit_speed = speed
