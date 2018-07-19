extends KinematicBody2D

# This is a demo showing how KinematicBody2D
# move_and_slide works.

# Member variables
const MOTION_SPEED = 160 # Pixels/second
var inventoryScene
onready var troll = get_node(".")
onready var camera = get_node("Camera2D")
var inv_bool = true
var troll_lock = false
var inventory
var timer
	
func _ready():
	inventoryScene = preload("res://Scenes/Scene_PlayerInventory.tscn")
	
func _physics_process(delta):
	var motion = Vector2()
	
	if !troll_lock:
		if Input.is_action_pressed("move_up"):
			motion += Vector2(0, -1)
		if Input.is_action_pressed("move_bottom"):
			motion += Vector2(0, 1)
		if Input.is_action_pressed("move_left"):
			motion += Vector2(-1, 0)
		if Input.is_action_pressed("move_right"):
			motion += Vector2(1, 0)
		
		motion = motion.normalized() * MOTION_SPEED
	
		move_and_slide(motion)
		
		if Input.is_key_pressed(KEY_F):
			$AnimationPlayer.play("trick")
		if Input.is_key_pressed(KEY_G):
			$AnimationPlayer.play_backwards("trick")

func _input(event):
	if(event.is_action_pressed("inv_key")):
		get_tree().call_group("room","inventory_open")
		if troll_lock:
			troll_lock = false
		elif !troll_lock:
			troll_lock = true
	if(event.is_action_pressed("exit_key")):
		get_tree().quit()

func _on_door_area_body_entered(body):
	#print("You're at the door")
	get_node("/root/global").goto_scene("res://Scenes/hideout.tscn") 

