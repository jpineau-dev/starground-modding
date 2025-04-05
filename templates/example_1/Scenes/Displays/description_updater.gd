extends HBoxContainer

var buildingID = ""
var lastBuildingID = ""

@export var gridContainer: Control

func _ready() -> void :
	var isFirstIteration: bool = true
	for i in Global.buildingsTree.tree:
		# Construct buildings tabs from tree categories
		var tabsContainer = $Grids/ScrollContainer
		var newTab: GridContainer = load("res://Scenes/BuildTab.tscn").instantiate()
		newTab.name = i + "Tab"
		newTab.visible = true if isFirstIteration else false
		tabsContainer.add_child(newTab)
		
		# Now construct buildings tabs buttons
		var tabNode = gridContainer.get_node_or_null(i + "Tab")
		var buttonsContainer = $"../../VerticalBox"
		var newBtn: Button = load("res://Scenes/BuildTabButton.tscn").instantiate()
		newBtn.name = i
		newBtn.tooltip_text = i
		newBtn.icon = Global.buildingsTree.tree[i].icon
		newBtn.node = tabNode
		buttonsContainer.add_child(newBtn)
		
		# Then we add buildings to the tab
		for j: String in Global.buildingsTree.tree[i].buildings:
			var buildButton = load("res://Scenes/BuildButton.tscn").instantiate()
			buildButton.objectID = j
			tabNode.add_child(buildButton)
		
		isFirstIteration = false

func _process(_delta):
	if buildingID != lastBuildingID:
		clear_ingredients()

		if buildingID == "":
			if $Details / VBoxContainer.visible:
				$Details / VBoxContainer.visible = false
		else:
			var buildingData = Global.buildingsTree.search_building_by_id(buildingID)

			$Details / VBoxContainer.visible = true
			$Details / VBoxContainer / Name.text = buildingData.ObjectName
			$Details / VBoxContainer / Description.text = buildingData.Description
			$Details / VBoxContainer / TagsBar.visible = buildingData.UsesFuel || buildingData.PowerStatus
			$Details / VBoxContainer / TagsLabel.clear()

			if buildingData.UsesFuel:
				$Details / VBoxContainer / TagsLabel.append_text("{0}{1}\n".format([tr("Consumes"), "[img]res://Sprites/icon_fuel.png[/img]"]))

			if buildingData.PowerStatus != 0:
				var powerstatus = tr("Consumes") if buildingData.PowerStatus < 0 else tr("Generates")
				var color = "FFB2B6FF" if buildingData.PowerStatus < 0 else Global.colors.Green.to_html()
				$Details / VBoxContainer / TagsLabel.append_text("[color={0}]{1}{2}{3}\n".format([color, powerstatus, "[img color=" + color + "]res://Sprites/icon_power.png[/img]", str(abs(buildingData.PowerStatus))]))

			if buildingData.Waterproof:
				$Details / VBoxContainer / TagsLabel.append_text("[color=0099DBFF]{0}{1}[/color]\n".format([tr("Waterproof"), "[img]res://Sprites/icon_water.png[/img]"]))

			for i in buildingData.Ingredients:
				var ingredient = load("res://Scenes/Displays/item_cost_indicator.tscn").instantiate()
				ingredient.itemID = i.ID
				ingredient.requiredAmount = i.Amount

				$Details / VBoxContainer / Items.add_child(ingredient)

	lastBuildingID = buildingID


func clear_ingredients():
	var children = $Details / VBoxContainer / Items.get_children()

	for i in children:
		i.queue_free()
