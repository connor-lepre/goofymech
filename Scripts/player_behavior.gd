extends CharacterBody3D

# Constants

const JUMP_VELOCITY = 3.0

# Player stuff
@export var base_speed = 2.5
@export var sprint_speed = 3.0
@export var sensivity = 0.3
var fov = false
var lerp_speed = 10
var player = self
var player_spawn: Vector3
@onready var speed = base_speed
@onready var is_moving: bool = false

# Camera stuff
@onready var camera = $Camera
var base_fov = 80.0
var sprint_fov = 90.0
var target_fov: float


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Store starting position
	player_spawn = player.position
	target_fov = base_fov

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _input(event):
	if event is InputEventMouseMotion:
		$Camera.rotation_degrees.x -= event.relative.y * sensivity
		$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x, -90, 90)
		rotation_degrees.y -= event.relative.x * sensivity

func _physics_process(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	#Handle sprint	
	if Input.is_action_pressed("sprint") and is_moving:
		speed = base_speed + sprint_speed
		target_fov = sprint_fov
	else:
		speed = base_speed
		target_fov = base_fov
	
	camera.fov = lerp(camera.fov, target_fov, lerp_speed * delta)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_fwd", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, (delta * speed * 10))
		velocity.z = move_toward(velocity.z, 0, (delta * speed * 10))
		is_moving = false

	move_and_slide()

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		player.position = player_spawn
