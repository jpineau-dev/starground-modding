extends VBoxContainer

@export var objectID: String
var selected = false
var islocked = false


func _ready():
	$Button.icon = load("res://Sprites/Items/nai.png")
	for i in Global.researchTable:
		if Global.researchTable[i].Unlocks.has(objectID):
			islocked = true
	var loadData = Global.buildingsTable.search_building_by_id(objectID)
	if loadData:
		$Button / MarginContainer / VBoxContainer / powerIndicator.visible = loadData.PowerStatus != 0
		$Button / MarginContainer / VBoxContainer / FuelIndicator.visible = loadData.UsesFuel
		$Button.icon = loadData.Sprite
		$Name.text = loadData.ObjectName


func _process(_delta):
	if islocked:
		if Global.unlockedThings.has(objectID):
			visible = true
		else:
			visible = false


func _on_button_pressed():
	Global.activePlayer.get_node("PositionIndependent/BuildPreview").select_new_object(objectID)
	Global.activePlayer.get_node("Canvas/InventoryDisplayBuilding").visible = false


func _on_button_mouse_exited():
	get_parent().get_parent().get_parent().get_parent().buildingID = ""


func _on_button_gui_input(_event):
	get_parent().get_parent().get_parent().get_parent().buildingID = objectID
