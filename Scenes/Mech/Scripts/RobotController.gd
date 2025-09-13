# RobotController.gd — CharacterBody3D (Godot 4.4)
# Twists a chosen bone each frame (after animation) so a BoneAttachment like
# "Cube_002" visibly spins when you press punch inputs.

extends CharacterBody3D

@export_group("Nodes")
@export_node_path("Skeleton3D") var skeleton_path: NodePath = ^"Armature/Skeleton3D"
@export_node_path("AnimationPlayer") var anim_path: NodePath = ^"Armature/AnimationPlayer"

@export_group("Movement (Tank)")
@export var auto_forward: bool = false
@export var walk_speed: float = 4.0
@export var reverse_speed: float = 2.0
@export var acceleration: float = 12.0
@export var turn_speed_deg: float = 180.0
@export var use_gravity: bool = true

@export_group("Twist / Punch")
@export var torso_bone_name: String = "mixamorig_Spine2"
@export_node_path("BoneAttachment3D") var attachment_path: NodePath
@export_enum("X","Y","Z") var punch_axis: int = 1
@export var punch_twist_deg: float = 30.0
@export var punch_rise_time: float = 0.08
@export var punch_fall_time: float = 0.12

@export_group("Optional Anim")
@export var walk_anim_name: String = "walking"
@export var idle_anim_name: String = ""

var _skeleton: Skeleton3D
var _anim: AnimationPlayer
var _torso_idx: int = -1
var _punch_tween: Tween
var _punch_rotation: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	_skeleton = get_node_or_null(skeleton_path)
	_anim = get_node_or_null(anim_path)

	# If an attachment is provided, auto-use its bone
	if _skeleton:
		if not attachment_path.is_empty():
			var ba := get_node_or_null(attachment_path) as BoneAttachment3D
			if ba and ba.bone_name != "":
				torso_bone_name = ba.bone_name
		_torso_idx = _skeleton.find_bone(torso_bone_name)
		print("Twist bone: ", torso_bone_name, " idx=", _torso_idx)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	# Apply punch twist after animations evaluate this frame
	call_deferred("_apply_punch_twist")

func _handle_movement(delta: float) -> void:
	var fwd := 0.0
	if auto_forward:
		fwd = 1.0
		
	#elif Input.is_action_pressed("move_back"):
		#fwd = -1.0
		
	#if Input.is_action_pressed("turn_right"):
		#turn += 1.0
	#rotation.y += deg_to_rad(turn_speed_deg) * turn * delta

	var target_speed := 0.0
	if fwd > 0.0:
		target_speed = walk_speed
	elif fwd < 0.0:
		target_speed = -reverse_speed

	var forward_dir: Vector3 = -transform.basis.z
	var desired: Vector3 = forward_dir * target_speed
	var horiz := Vector3(velocity.x, 0.0, velocity.z).move_toward(desired, acceleration * delta)
	velocity.x = horiz.x
	velocity.z = horiz.z

	if use_gravity:
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	# Animation control - pause instead of stop
	if _anim:
		if absf(target_speed) > 0.01:
			# Moving - play/resume walking animation
			if not _anim.is_playing() or _anim.current_animation != walk_anim_name:
				_play_anim_safe(walk_anim_name)
			else:
				_anim.speed_scale = 1.0  # Resume if paused
		else:
			# Idle - pause current animation or play idle
			if _anim.is_playing():
				_anim.speed_scale = 0.0  # Pause by setting speed to 0
			elif idle_anim_name != "":
				_play_anim_safe(idle_anim_name)

func _apply_punch_twist() -> void:
	if _skeleton == null or _torso_idx == -1:
		return

	if absf(_punch_rotation) <= 0.001:
		_skeleton.set_bone_global_pose_override(_torso_idx, Transform3D(), 0.0, false)
		return

	# Start from animation-driven pose, then add local-axis twist
	var pose: Transform3D = _skeleton.get_bone_global_pose_no_override(_torso_idx)

	var axis: Vector3
	match punch_axis:
		0: axis = pose.basis.x
		1: axis = pose.basis.y
		_: axis = pose.basis.z
	axis = axis.normalized()

	var twist := Basis(axis, _punch_rotation)
	pose.basis = twist * pose.basis
	_skeleton.set_bone_global_pose_override(_torso_idx, pose, 1.0, true)

func punch_left() -> void:
	_punch(-1)

func punch_right() -> void:
	_punch(1)

func _punch(dir: int) -> void:
	if _punch_tween:
		_punch_tween.kill()
	
	var peak := deg_to_rad(punch_twist_deg) * float(dir)
	_punch_tween = create_tween()
	_punch_tween.tween_property(self, "_punch_rotation", peak, punch_rise_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(self, "_punch_rotation", 0.0, punch_fall_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("punch_left"):
		punch_left()
	if event.is_action_pressed("punch_right"):
		punch_right()
	if event.is_action_pressed("auto_forward"):
		auto_forward = !auto_forward
		print("auto_forward = ", auto_forward)

func _play_anim_safe(name: String) -> void:
	if name == "" or _anim == null:
		return
	if not _anim.is_playing() or _anim.current_animation != name:
		if _anim.has_animation(name):
			_anim.play(name)
