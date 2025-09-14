# Attach this to your main level node
extends Node3D

func _ready():
	# Manual signal connections
	$button.move_robot_left.connect($Robot.move_left_by_distance)
	$button2.move_player_right.connect($Robot/BoneAttachment3D/cockpit/player.move_right_by_distance)
	
	print("Signals connected manually")
