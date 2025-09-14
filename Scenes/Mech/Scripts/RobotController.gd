# RobotController.gd — CharacterBody3D (Godot 4.4)
# Controls mech movement, animations, and bone twisting for punch effects

extends CharacterBody3D

# Signals
signal button1_movement_complete
signal button2_movement_complete
signal button3_movement_complete
signal button4_movement_complete
signal button5_movement_complete

@export_group("Nodes")
@export_node_path("Skeleton3D") var skeleton_path: NodePath = ^"Armature/Skeleton3D"
@export_node_path("AnimationPlayer") var anim_path: NodePath = ^"Armature/AnimationPlayer"

@export_group("Movement")
@export var auto_forward: bool = false
@export var walk_speed: float = 0.1
@export var acceleration: float = 12.0
@export var use_gravity: bool = true

@export_group("Button Movement")
@export var button_move_speed: float = 2.0

@export_group("Twist / Punch")
@export var torso_bone_name: String = "mixamorig_Spine2"
@export_node_path("BoneAttachment3D") var attachment_path: NodePath
@export_enum("X","Y","Z") var punch_axis: int = 1
@export var punch_twist_deg: float = 30.0
@export var punch_rise_time: float = 0.08
@export var punch_fall_time: float = 0.12

@export_group("Animation")
@export var walk_anim_name: String = "walking"
@export var walk_anim_speed: float = 0.3

# Internal vars
var _skeleton: Skeleton3D
var _anim: AnimationPlayer
var _torso_idx: int = -1
var _punch_tween: Tween
var _punch_rotation: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Button movement
var _button_moving: bool = false
var _button_tween: Tween

func _ready() -> void:
	_skeleton = get_node_or_null(skeleton_path)
	_anim = get_node_or_null(anim_path)

	if _skeleton:
		if not attachment_path.is_empty():
			var ba := get_node_or_null(attachment_path) as BoneAttachment3D
			if ba and ba.bone_name != "":
				torso_bone_name = ba.bone_name
		_torso_idx = _skeleton.find_bone(torso_bone_name)
		print("Twist bone: ", torso_bone_name, " idx=", _torso_idx)

func _physics_process(delta: float) -> void:
	if not _button_moving:  # Only handle normal movement when not button moving
		_handle_movement(delta)
	call_deferred("_apply_punch_twist")

func _handle_movement(delta: float) -> void:
	var target_speed := 0.0
	
	if auto_forward:
		target_speed = walk_speed

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
	_handle_animation(target_speed)

func _handle_animation(target_speed: float) -> void:
	if not _anim:
		return
	
	if absf(target_speed) > 0.01:
		# Moving - play/resume walking animation
		if not _anim.is_playing() or _anim.current_animation != walk_anim_name:
			_play_anim_safe(walk_anim_name)
		else:
			_anim.speed_scale = walk_anim_speed
	else:
		# Idle - pause animation
		if _anim.is_playing():
			_anim.speed_scale = 0.0

func _apply_punch_twist() -> void:
	if _skeleton == null or _torso_idx == -1:
		return

	if absf(_punch_rotation) <= 0.001:
		_skeleton.set_bone_global_pose_override(_torso_idx, Transform3D(), 0.0, false)
		return

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

# Button-triggered movement functions

func move_left_by_distance(distance: float, speed: float = 0.0) -> void:
	if _button_moving:
		return
	
	print("Robot moving left by ", distance, "m at speed ", speed)
	await _move_by_offset(Vector3(distance, 0, 0), speed)

func move_right_by_distance(distance: float, speed: float = 0.0) -> void:
	if _button_moving:
		return
	
	print("Robot moving right by ", distance, "m at speed ", speed)
	await _move_by_offset(Vector3(-distance, 0, 0), speed)

func move_forward_by_distance(distance: float, speed: float = 0.0) -> void:
	if _button_moving:
		return
	
	print("Robot moving forward by ", distance, "m at speed ", speed)
	await _move_by_offset(Vector3(0, 0, -distance), speed)

func move_back_by_distance(distance: float, speed: float = 0.0) -> void:
	if _button_moving:
		return
	
	print("Robot moving back by ", distance, "m at speed ", speed)
	await _move_by_offset(Vector3(0, 0, distance), speed)

func _move_by_offset(offset: Vector3, custom_speed: float = 0.0) -> void:
	print("ROBOT DEBUG: _move_by_offset called with offset: ", offset)
	_button_moving = true
	
	if _button_tween:
		print("ROBOT DEBUG: Killing existing tween")
		_button_tween.kill()
	
	var start_pos = global_position
	var target_pos = start_pos + offset
	
	# Use custom speed if provided, otherwise use default
	var speed_to_use = custom_speed if custom_speed > 0.0 else button_move_speed
	var move_time = offset.length() / speed_to_use
	
	print("ROBOT DEBUG: Moving from ", start_pos, " to ", target_pos, " in ", move_time, " seconds at speed ", speed_to_use)
	
	_button_tween = create_tween()
	_button_tween.tween_property(self, "global_position", target_pos, move_time)
	_button_tween.set_trans(Tween.TRANS_SINE)
	_button_tween.set_ease(Tween.EASE_IN_OUT)
	
	await _button_tween.finished
	_button_moving = false
	print("ROBOT DEBUG: Movement complete")

# Punch functions
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

# Signal handlers for button connections
func _on_button_move_robot_left(distance: float, speed: float) -> void:
	await move_left_by_distance(distance, speed)
	button1_movement_complete.emit()

func _on_button_move_robot_right(distance: float, speed: float) -> void:
	await move_right_by_distance(distance, speed)
	button2_movement_complete.emit()
