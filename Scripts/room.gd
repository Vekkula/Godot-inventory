extends Node2D

var inventory
var inventoryScene = preload("res://Scenes/Scene_PlayerInventory.tscn")
var inv_location
var inv_bool = true

func _init():
	add_to_group("room")

func inventory_open():
	if inv_bool == true:
		inv_bool = false
		get_tree().paused = true #pause
		spawn_inventory()
	else:
		get_tree().paused = false
		inv_bool = true
		Global_Player.save_data()
		del_inventory()


func spawn_inventory():
	inv_location = $walls/troll.global_position
	inventory = inventoryScene.instance()
	add_child(inventory)
	inventory.show()
	inventory.rect_global_position = inv_location

func del_inventory():
	if has_node("Node"):
		get_node("Node").free()

func inv_exit_pressed():
	if !inv_bool:
		inv_bool = true
		$walls/troll.troll_lock =false