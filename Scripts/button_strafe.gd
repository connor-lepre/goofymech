# Button_Strafe.gd - Clean version with movement-based cooldown
extends Node

# Signals for different button actions
signal move_robot_left(distance: float, speed: float)
signal move_robot_right(distance: float, speed: float)
signal button_pressed(button_id: String)

# Button configuration
@export var button_id: String = "button1"
@export var move_distance: float = 10.0
@export var move_speed: float = 20.0

# Button mechanics
var default: bool = true
var default_pos: float
var pressed: bool = false
var pressed_pos = 0.15
var on_cooldown: bool = false

@onready var button = $buttonswitch

func _ready():
	default_pos = button.position.y
	print("Button ", button_id, " ready with distance: ", move_distance, " and speed: ", move_speed)

func _on_button_trigger_entered(body):
	print("DEBUG: Function called, body: ", body.name, ", in player group: ", body.is_in_group("player"))
	
	# Only respond to player, ignore button parts
	if not body.is_in_group("player"):
		return
		
	print("DEBUG: Player detected, checking cooldown...")
	print("DEBUG: on_cooldown = ", on_cooldown)
		
	if not on_cooldown:
		print("UNIQUE DEBUG: Player entered ", button_id)
		print("DEBUG: Setting button pressed...")
		pressed = true
		button.position.y -= pressed_pos
		on_cooldown = true  # Start cooldown immediately
		
		print("DEBUG: About to emit signal for ", button_id)
		
		# Emit appropriate signal based on button ID
		match button_id:
			"button1":
				print("BUTTON DEBUG: About to emit move_robot_left signal")
				move_robot_left.emit(move_distance, move_speed)
				print("BUTTON DEBUG: Signal emitted")
			"button2": 
				print("BUTTON DEBUG: About to emit move_robot_right signal")
				move_robot_right.emit(move_distance, move_speed)
				print("BUTTON DEBUG: Signal emitted")
	
		print("DEBUG: Emitting button_pressed signal")
		button_pressed.emit(button_id)
		print("DEBUG: Function complete")
	else:
		print("DEBUG: Button on cooldown, ignoring")

func _on_movement_complete():
	# Called when the robot finishes moving
	print("Button ", button_id, " movement complete - ending cooldown")
	on_cooldown = false
	button.position.y += pressed_pos
	print("Button ", button_id, " ready for next use")
