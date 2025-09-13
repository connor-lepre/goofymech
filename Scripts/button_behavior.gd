extends Node

var default: bool = true
var default_pos: float
var pressed: bool = false
var pressed_pos = 0.15

var _on_cooldown: bool = false
var cooldown: float


@onready var button = $buttonswitch

func _ready():
	default_pos = button.position.y


func _on_button_trigger_entered(body):
	if body.is_in_group("player") and not _on_cooldown:
		print("Player entered button")
		pressed = true
		button.position.y -= pressed_pos
		button_cooldown()
	
func button_cooldown() -> void:
	_on_cooldown = true
	cooldown = 3.0
	print("Cooldown started")
	await get_tree().create_timer(cooldown).timeout
	_on_cooldown = false
	button.position.y += pressed_pos
	print("Cooldown ended")
	
