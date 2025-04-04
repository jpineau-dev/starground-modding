extends HBoxContainer

var recipes
var inventory
var object
@export var currentRecipe = ""
var lastRecipe = ""
@export var categoryContainer: Control
@export var recipeIndiciator: Control
@export var categoryButtons: Control
@export var fuelSection: Control
@export var outputSection: Control

@export var progress = 0.0
@export var fuelAmount = 0.0

var fuelBar
var progressBar

func _ready():
	inventory = get_node(owner.path)
	object = inventory.get_parent()

	recipes = Global.recipeTable.get(object.buildingID, [])

	var buildingData = Global.buildingsTable.search_building_by_id(object.buildingID)

	progressBar = outputSection.get_node("ProgressBar")
	fuelBar = fuelSection.get_node("FuelBar")


	if buildingData.get("UsesFuel", false) == true:
		fuelSection.visible = true
		get_parent().staticSlotCount = 1
	else:
		get_parent().staticSlotCount = 0
		fuelSection.visible = false
		var newArr: Array[NodePath] = []
		get_parent().children = newArr



	if recipes.size() < 2:
		$RecipeBox.visible = false

	for i in recipes:
		var recipe = recipes[i]
		var category = recipe.get("Category", "Miscellaneous")

		if !categoryContainer.get_node_or_null(category):
			var categoryNode = GridContainer.new()
			categoryContainer.add_child(categoryNode)
			categoryNode.name = category

			categoryNode.set_h_size_flags(SIZE_EXPAND_FILL)
			categoryNode.set_v_size_flags(SIZE_EXPAND_FILL)

			categoryNode.visible = false

			var groupButton: Button = load("res://Scenes/Displays/recipe_group_button.tscn").instantiate()
			categoryButtons.get_node("VBox").add_child(groupButton)
			groupButton.node = categoryNode

			if ResourceLoader.exists("res://Sprites/icon_" + category.to_lower() + ".png"):
				groupButton.icon = load("res://Sprites/icon_" + category.to_lower() + ".png")
			else:
				groupButton.icon = load("res://Sprites/icon_question_mark.png")

			groupButton.tooltip_text = category
			categoryNode.visibility_changed.connect(groupButton.change_highlight)

		var recipeButton = load("res://Scenes/crafter_recipe_button.tscn").instantiate()
		recipeButton.recipeID = i
		recipeButton.buildingID = object.buildingID
		categoryContainer.get_node(category).add_child(recipeButton, true)
		recipeButton.set_owner(self)

	if categoryContainer.get_children().size() > 0:
		categoryContainer.get_children()[0].visible = true

	if categoryContainer.get_children().size() < 2:
		categoryButtons.visible = false

	update_data()


func _process(_delta):
	update_data()


func update_data():
	if multiplayer.is_server():
		progress = object.progress
		fuelAmount = object.fuelAmount

	currentRecipe = object.newRecipe
	progressBar.value = progress
	fuelBar.value = fuelAmount

	if currentRecipe != lastRecipe:
		var recipeData = null
		var testItem = ModAPI.get_item_data(currentRecipe)
		if testItem.Name == "NAI":
			recipeData = Global.recipeTable.get(object.buildingID).get(currentRecipe)
			if !recipeData.get("Sprite"):
				recipeData = testItem
		else:
			recipeData = testItem

		recipeIndiciator.get_node("MarginContainer/HBoxContainer/TextureRect").texture = recipeData.Sprite
		recipeIndiciator.get_node("MarginContainer/HBoxContainer/Label").text = recipeData.Name
		lastRecipe = currentRecipe
		
