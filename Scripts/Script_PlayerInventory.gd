# Script_PlayerInventory.gd

extends Node

onready var itemList = get_node("Panel/ItemList")
onready var gearList = get_node("Panel/GearList")
onready var panel = get_node("Panel")

# WindowDialog_AddItemWindow Variables. and "addgearwindow"
onready var addItemWindow = get_node("Panel/WindowDialog_AddItemWindow")
onready var addItemWindow_SpinBox_ItemId = get_node("Panel/WindowDialog_AddItemWindow/AddItemWindow_SpinBox_ItemID")
onready var addGearWindow = get_node("Panel/WindowDialog_AddGearWindow")
onready var addGearWindow_Spinbox_ItemId = get_node("Panel/WindowDialog_AddGearWindow/AddItemWindow_SpinBox_ItemID")

# WindowDialog_ItemMenu Variables.
onready var itemMenu = get_node("Panel/WindowDialog_ItemMenu")
onready var itemMenu_TextureFrame_Icon = get_node("Panel/WindowDialog_ItemMenu/ItemMenu_TextureFrame_Icon")
onready var itemMenu_RichTextLabel_ItemInfo = get_node("Panel/WindowDialog_ItemMenu/ItemMenu_RichTextLabel_ItemInfo")
onready var itemMenu_Button_DropItem = get_node("Panel/WindowDialog_ItemMenu/ItemMenu_Button_DropItem")
onready var itemMenu_Button_UseItem = get_node("Panel/WindowDialog_ItemMenu/ItemMenu_Button_UseItem")

#WindowDialog_GearMenu vars
onready var gearMenu = get_node("Panel/WindowDialog_GearMenu")
onready var gearMenu_TextureFrame_Icon = get_node("Panel/WindowDialog_GearMenu/ItemMenu_TextureFrame_Icon")
onready var gearMenu_RichTextLabel_ItemInfo = get_node("Panel/WindowDialog_GearMenu/ItemMenu_RichTextLabel_ItemInfo")
onready var gearMenu_Button_DropItem = get_node("Panel/WindowDialog_GearMenu/ItemMenu_Button_DropItem")
onready var gearMenu_Button_Remove = get_node("Panel/WindowDialog_GearMenu/ItemMenu_Button_UseItem")

var activeItemSlot = -1
var dropItemSlot = -1

onready var isDraggingItem = false
var draggedItemTexture
onready var draggedItem = get_node("Panel/Sprite_DraggedItem")
onready var mouseButtonReleased = true
var draggedItemSlot = -1
onready var initial_mousePos = Vector2()
onready var cursor_insideItemList = false
onready var cursor_insideGearList = false
var to_gear


func _ready():
	
	# Initialize Item List
	itemList.set_max_columns(10)#
	itemList.set_fixed_icon_size(Vector2(48,48))
	itemList.set_icon_mode(ItemList.ICON_MODE_TOP)
	itemList.set_select_mode(ItemList.SELECT_SINGLE)
	itemList.set_same_column_width(true)
	itemList.set_allow_rmb_select(true)
	
	#gearlist
	gearList.set_max_columns(5)#
	gearList.set_fixed_icon_size(Vector2(48,48))
	gearList.set_icon_mode(ItemList.ICON_MODE_TOP)
	gearList.set_select_mode(ItemList.SELECT_SINGLE)
	gearList.set_same_column_width(true)
	gearList.set_allow_rmb_select(true)
	
	#loads itemlists
	load_items()
	load_gear()
	
	set_process(false)
	set_process_input(true)


#activated when you start dragging
func _process(delta):
	if (isDraggingItem):
		#mouse position of the scene's rootnode;not the viewport
		draggedItem.global_position = $".".get_global_mouse_position()
		
		if(itemList.get_global_rect().has_point(draggedItem.global_position)):
			#print("draggedItem is inside itemlist")
			to_gear = false
			activeItemSlot = itemList.get_item_at_position(itemList.get_local_mouse_position(),true)
		elif(gearList.get_global_rect().has_point(draggedItem.global_position)):
			#print("draggedItem is inside gearlist")
			to_gear = true
			activeItemSlot = gearList.get_item_at_position(gearList.get_local_mouse_position(),true)


func _input(event):
	if (event is InputEventMouseButton):
		if (event.is_action_pressed("mouse_leftbtn")):
			mouseButtonReleased = false
			initial_mousePos = get_viewport().get_mouse_position()
		if (event.is_action_released("mouse_leftbtn")):
			move_item(cursor_insideGearList,true)
			end_drag_item()
	
	if (event is InputEventMouseMotion):
		#itemlist
		if (cursor_insideItemList):
			activeItemSlot = itemList.get_item_at_position(itemList.get_local_mouse_position(),true)
			if (activeItemSlot >= 0):
				itemList.select(activeItemSlot, true)
				if (isDraggingItem or mouseButtonReleased):
					return
				if (!itemList.is_item_selectable(activeItemSlot)): 
					end_drag_item()
				if (initial_mousePos.distance_to(get_viewport().get_mouse_position()) > 0.0): 
					begin_drag_item(activeItemSlot,false)
		else:
			activeItemSlot = -1
		#gearlist
		if(cursor_insideGearList):
			activeItemSlot = gearList.get_item_at_position(gearList.get_local_mouse_position(),true)
			if(activeItemSlot >= 0):
				gearList.select(activeItemSlot, true)
				if (isDraggingItem or mouseButtonReleased):
					return
				if (!gearList.is_item_selectable(activeItemSlot)): 
					end_drag_item()
				if (initial_mousePos.distance_to(get_viewport().get_mouse_position()) > 0.0): 
					begin_drag_item(activeItemSlot,true)
		else:
			activeItemSlot = -1


func load_items():
	itemList.clear()
	for slot in range(0, Global_Player.inventory_maxSlots):
		itemList.add_item("", null, false)
		update_slot(slot)


func load_gear():
	gearList.clear()
	for slot in range(0, Global_Player.gear_maxSlots):
		gearList.add_item("",null,false)
		update_gear_slot(slot)


func update_slot(slot):
	var inventoryItem = Global_Player.inventory[String(slot)]
	var itemMetaData = Global_ItemDatabase.get_item(inventoryItem["id"])
	var icon = ResourceLoader.load(itemMetaData["icon"])
	var amount = int(inventoryItem["amount"])
	
	itemMetaData["amount"] = amount
	if (!itemMetaData["stackable"]): 
		amount = " "
	itemList.set_item_text(slot, String(amount))
	itemList.set_item_icon(slot, icon)
	itemList.set_item_selectable(slot, int(inventoryItem["id"]) > 0)
	itemList.set_item_metadata(slot, itemMetaData)
	itemList.set_item_tooltip(slot, itemMetaData["name"])
	itemList.set_item_tooltip_enabled(slot, int(inventoryItem["id"]) > 0)


func update_gear_slot(slot):
	var inventoryItem = Global_Player.gear[String(slot)]
	var itemMetaData = Global_ItemDatabase.get_item(inventoryItem["id"])
	var icon = ResourceLoader.load(itemMetaData["icon"])
	var amount = int(inventoryItem["amount"])
	
	itemMetaData["amount"] = amount
	if (!itemMetaData["stackable"]): 
		amount = " "
	gearList.set_item_text(slot, String(amount))
	gearList.set_item_icon(slot, icon)
	gearList.set_item_selectable(slot, int(inventoryItem["id"]) > 0)
	gearList.set_item_metadata(slot, itemMetaData)
	gearList.set_item_tooltip(slot, itemMetaData["name"])
	gearList.set_item_tooltip_enabled(slot, int(inventoryItem["id"]) > 0)

#buttons for adding items are for testing purposes
func _on_Button_AddItem_pressed():
	addItemWindow.popup()

#buttons for adding items are for testing purposes
func _on_Button_AddGear_pressed():
	addGearWindow.popup()


func _on_AddItemWindow_Button_Close_pressed():
	addItemWindow.hide()


func _on_AddItemWindow_Button_Close_Gear_pressed():
	addGearWindow.hide()


func _on_AddItemWindow_Button_AddItem_pressed():
	var affectedSlot = Global_Player.inventory_addItem(addItemWindow_SpinBox_ItemId.get_value())
	if (affectedSlot >= 0): 
		update_slot(affectedSlot)


func _on_AddItemWindow_Button_AddGear_pressed():
	var affectedSlot = Global_Player.inventory_addGear(addGearWindow_Spinbox_ItemId.get_value())
	if (affectedSlot >= 0): 
		update_gear_slot(affectedSlot)


#opens an infomenu for the item; you can also drop items there
func _on_ItemList_item_rmb_selected(index, atpos):
	if (isDraggingItem):
		return
	
	dropItemSlot = index
	
	var itemData = itemList.get_item_metadata(index)
	if (int(itemData["id"])) < 1: return
	var strItemInfo = ""
	
	itemMenu.set_position($".".get_global_mouse_position() + Vector2(15,15))
	itemMenu.set_title(itemData["name"])
	itemMenu_TextureFrame_Icon.set_texture(itemList.get_item_icon(index))
	
	strItemInfo = "Name: [color=#00aedb] " + itemData["name"] + "[/color]\n"
	strItemInfo = strItemInfo + "Type: [color=#f37735] " + itemData["type"] + "[/color]\n"
	strItemInfo = strItemInfo + "Weight: [color=#00b159] " + String(itemData["weight"]) + "[/color]\n"
	strItemInfo = strItemInfo + "Sell Price: [color=#ffc425] " + String(itemData["sell_price"]) + "[/color] gold\n"
	if(itemData.has("damage")):
		strItemInfo = strItemInfo + "Damage: " + String(itemData["damage"]) + "\n"
	if(itemData.has("heal")):
		strItemInfo = strItemInfo + "Heal: " + String(itemData["heal"]) + "\n"
	strItemInfo = strItemInfo + "\n[color=#b3cde0]" + itemData["description"] + "[/color]"
	
	itemMenu_RichTextLabel_ItemInfo.set_bbcode(strItemInfo)
	itemMenu_Button_DropItem.set_text("(" + String(itemData["amount"]) + ") Drop" )
	activeItemSlot = index
	itemMenu.popup()


#opens an infomenu for the item; you can also drop items there
func _on_GearList_item_rmb_selected(index, at_position):
	if (isDraggingItem):
		return
	
	dropItemSlot = index
	
	var itemData = gearList.get_item_metadata(index)
	if (int(itemData["id"])) < 1: return
	var strItemInfo = ""
	
	gearMenu.set_position($".".get_global_mouse_position() + Vector2(15,15))
	
	gearMenu.set_title(itemData["name"])
	gearMenu_TextureFrame_Icon.set_texture(gearList.get_item_icon(index))
	
	strItemInfo = "Name: [color=#00aedb] " + itemData["name"] + "[/color]\n"
	strItemInfo = strItemInfo + "Type: [color=#f37735] " + itemData["type"] + "[/color]\n"
	strItemInfo = strItemInfo + "Weight: [color=#00b159] " + String(itemData["weight"]) + "[/color]\n"
	strItemInfo = strItemInfo + "Sell Price: [color=#ffc425] " + String(itemData["sell_price"]) + "[/color] gold\n"
	if(itemData.has("damage")):
		strItemInfo = strItemInfo + "Damage: " + String(itemData["damage"]) + "\n"
	if(itemData.has("heal")):
		strItemInfo = strItemInfo + "Heal: " + String(itemData["heal"]) + "\n"
	strItemInfo = strItemInfo + "\n[color=#b3cde0]" + itemData["description"] + "[/color]"
	
	gearMenu_RichTextLabel_ItemInfo.set_bbcode(strItemInfo)
	
	gearMenu_Button_DropItem.set_text("(" + String(itemData["amount"]) + ") Drop" )
	activeItemSlot = index
	gearMenu.popup()


func _on_ItemMenu_Button_DropItem_pressed():
	var newAmount = Global_Player.inventory_removeItem(dropItemSlot)
	if (newAmount < 1):
		itemMenu.hide()
	else:
		itemMenu_Button_DropItem.set_text("(" + String(newAmount) + ") Drop")
	update_slot(dropItemSlot)


func _on_ItemMenu_Button_UseItem_pressed():
	var itemData = itemList.get_item_metadata(dropItemSlot)
	
	#check if equipment or consumable
	print("item type: " + String(itemData["type"]))
	if String(itemData["type"]) == "equipment":
		print("EQUIP ITEM")
		to_gear = true
		move_item(false, false)
	else:
		#use the item somehow
		print("USE ITEM")
	itemMenu.hide()


func _on_GearMenu_Button_DropGear_pressed():
	var newAmount = Global_Player.inventory_removeGear(dropItemSlot)
	if (newAmount < 1):
		gearMenu.hide()
	else:
		gearMenu_Button_DropItem.set_text("(" + String(newAmount) + ") Drop")
	update_gear_slot(dropItemSlot)


func _on_GearMenu_Button_RemoveGear_pressed():
	to_gear = false
	move_item(true, false)
	gearMenu.hide()


func _on_Button_Save_pressed():
	Global_Player.save_data()


func begin_drag_item(index,is_gear):
	if (isDraggingItem): 
		return
	if (index < 0): 
		return
	
	set_process(true)
	#sets the slot empty when you drag an item from it
	if(!is_gear): 
		draggedItem.texture = itemList.get_item_icon(index)
		draggedItem.show()

		itemList.set_item_text(index, " ")
		itemList.set_item_icon(index, ResourceLoader.load(Global_ItemDatabase.get_item(0)["icon"]))
	else:
		draggedItem.texture = gearList.get_item_icon(index)
		draggedItem.show()
		
		gearList.set_item_text(index," ")
		gearList.set_item_icon(index, ResourceLoader.load(Global_ItemDatabase.get_item(0)["icon"]))
	
	#halfs the the size of the dragged item if its over 50,50
	draggedItem.scale = Vector2(1,1)
	var s = Vector2(50,50)
	if draggedItem.texture.get_size() > Vector2(100,100):
		draggedItem.scale = Vector2(0.5,0.5)
	elif draggedItem.texture.get_size() > s:
		var a = draggedItem.texture.get_size()-s 
		a = a/100
		print(a)
		var b = Vector2(1,1)- a
		print(b)
		draggedItem.scale = b

	else:
		draggedItem.scale = Vector2(1,1)
	
	draggedItemSlot = index
	isDraggingItem = true
	mouseButtonReleased = false
	draggedItem.global_translate(get_viewport().get_mouse_position())


func end_drag_item():
	set_process(false)
	draggedItemSlot = -1
	draggedItem.hide()
	mouseButtonReleased = true
	isDraggingItem = false
	activeItemSlot = -1
	return


func move_item(is_gear, dragged):
	print("\nis this gear? " + str(is_gear))
	print("is this going to gear  " + str(to_gear))
	print("dragged to: " + str(activeItemSlot))
	
	if dragged:
		#if dragged and the index is invalid just returns
		if (draggedItemSlot < 0): 
			return
		if (activeItemSlot < 0): 
			if(is_gear):
				update_gear_slot(draggedItemSlot)
			elif(!is_gear):
				update_slot(draggedItemSlot)
			return
	elif !dragged:
		#the itemslot the dialog was made from. 
		draggedItemSlot = dropItemSlot
		if is_gear:
			activeItemSlot = Global_Player.inventory_getEmptySlot()
		elif !is_gear:
			activeItemSlot = Global_Player.gear_getEmptySlot()
	
	#if (itemData["stackable"]):
	#	pass
	
	#actual moving
	if(!is_gear and to_gear):
		print("moved to gear")
		Global_Player.inventory_itemToGear(draggedItemSlot, activeItemSlot)#
		update_gear_slot(activeItemSlot)
		update_slot(draggedItemSlot)
	elif(!is_gear):
		print("Moved inside inventory")
		Global_Player.inventory_moveItem(draggedItemSlot, activeItemSlot)
		update_slot(draggedItemSlot)
		update_slot(activeItemSlot)
	elif(is_gear and !to_gear):
		print("moved to inventory")
		Global_Player.inventory_gearToItem(draggedItemSlot, activeItemSlot)#
		update_slot(activeItemSlot)
		update_gear_slot(draggedItemSlot)
	elif(is_gear):
		print("moved inside gear")
		Global_Player.inventory_moveGear(draggedItemSlot, activeItemSlot)
		update_gear_slot(draggedItemSlot)
		update_gear_slot(activeItemSlot)
		
	print("dragged from: " + str(draggedItemSlot) + "\n")


func _on_ItemList_mouse_entered():
	cursor_insideItemList = true;


func _on_ItemList_mouse_exited():
	cursor_insideItemList = false;


func _on_GearList_mouse_entered():
	cursor_insideGearList = true;


func _on_GearList_mouse_exited():
	cursor_insideGearList = false;


func _on_Button_Exit_pressed():
	get_node(".").queue_free()
	get_tree().paused = false
	Global_Player.save_data()
	get_tree().call_group("room","inv_exit_pressed")


