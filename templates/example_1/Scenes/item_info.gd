extends VBoxContainer

var dataID: String
var amount = 0
var data

@export var amountLabel: Label

func find_recipe():
	for buildingID in Global.recipeTable:
		for recipeID in Global.recipeTable.get(buildingID):
			if recipeID == dataID:
				return Global.recipeTable.get(buildingID).get(recipeID)

	return null


func _ready():
	var test1 = Global.buildingsTree.search_building_by_id(dataID)
	var test2 = Global.regionsTable.get(dataID)
	var test3 = find_recipe()
	var test4 = ModAPI.get_item_data(dataID)

	if test1:
		data = test1
		$TextureRect.texture = data.Sprite
		$Label.text = data.ObjectName
	elif test2:
		data = test2
		$TextureRect.texture = data.Sprite
		$Label.text = data.Name
	elif test3 && test4.Name == "NAI":

		data = test3
		$TextureRect.texture = data.Sprite
		$Label.text = data.Name
	else:
		data = test4
		$TextureRect.texture = data.Sprite
		$Label.text = data.Name

	if amount > 0:
		amountLabel.text = str(amount)
		amountLabel.visible = true

	update_wrapping.call_deferred()


func update_wrapping():
	if $Label.size.x > 80:
		$Label.custom_minimum_size.x = 80
		$Label.size.x = 80
		$Label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
