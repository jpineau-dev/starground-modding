class_name InventorySlot extends Control


var path
var scaleOffset = Vector2(0, 0)
var previewPath

@export var placeholderPath = ""

@export var filter = false

var itemID: String = ""
var placeholderID: String = ""

var amount: int = 0

var canShift = true
var mouseHovered = false

@export var disabled = false

var clickDelay = 0

var canDisplayInfo = false

func _ready():
	$NameLabel.hide()

	if placeholderPath != "":
		$Node2D / Placeholder.texture = load(placeholderPath)


func _process(delta):
	if Global.inputType == Global.INPUT.CONTROLLER:
		if has_focus():
			mouseHovered = true
			highlight()
			$ColorRect.visible = true
		else:
			mouseHovered = false
			release_highlight()
			$ColorRect.visible = false

	$InfoPanel.size = Vector2.ZERO

	if disabled:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

	if mouseHovered:
		check_input()

	if clickDelay > 0:
		clickDelay -= 1 * delta

	if !is_visible_in_tree() || (placeholderID == "" && itemID == ""):
		scaleOffset = Vector2(0, 0)
		$NameLabel.hide()

	$Node2D / Placeholder.visible = itemID == ""
	$Node2D / Frame / AmountPlaceholder.visible = $Node2D / Placeholder.visible

	if !Input.is_action_pressed("shift"):
		canShift = true

	$Node2D.scale = $Node2D.scale.lerp(Vector2(1, 1) + (scaleOffset * 1.5), 1 - pow(0.001, delta))
	$InfoPanel.visible = $NameLabel.visible && canDisplayInfo


func update():
	var activeID
	if itemID != "":
		activeID = itemID
	elif placeholderID != "":
		activeID = placeholderID

	var itemData = ModAPI.get_item_data(activeID)

	if amount > 1:
		$Node2D / Frame / Amount.text = str(amount)
	else:
		$Node2D / Frame / Amount.text = ""

	if ((itemID == "" || itemID != placeholderID) && placeholderID != ""):
		$Node2D / Frame.texture = load("res://Sprites/slot_frame_red.png")
	elif itemData.get("Artifact"):
		$Node2D / Frame.texture = load("res://Sprites/slot_frame_gold.png")
	else:
		$Node2D / Frame.texture = load("res://Sprites/slot_frame.png")


func set_item_id(newID):
	itemID = newID
	update_info_panel()
	update()


func set_placeholder_id(newID):
	placeholderID = newID
	update_info_panel()
	update()


func update_info_panel():
	var activeID
	if itemID != "":
		activeID = itemID
	elif placeholderID != "":
		activeID = placeholderID

	var itemData = ModAPI.get_item_data(activeID)
	var keys = ["Damage", "Cooldown", "Knockback", "Reach", "Range", "Stability", "CritChance", "Fuel"]
	var higherBetter = [true, false, true, true, true, true, true, true]
	var icons = [
	"res://Sprites/icon_weapons.png", 
	"res://Sprites/icon_cooldown.png", 
	"res://Sprites/icon_knockback.png", 
	"res://Sprites/icon_reach.png", 
	"res://Sprites/icon_reach.png", 
	"res://Sprites/icon_stability.png", 
	"res://Sprites/icon_crit_chance.png", 
	"res://Sprites/icon_fuel.png", ]

	var panelText = ""
	var description = itemData.get("Description")
	$NameLabel.text = itemData.Name

	if itemData.get("Exclusive"):
		panelText += "[color=#FF7792][img]res://Sprites/icon_exclusive.png[/img] "
		panelText += tr("Exclusive")
		panelText += "\n[/color]"

	if itemData.get("Farmable"):
		panelText += "[color=#7FC675][img]res://Sprites/icon_plant.png[/img] "
		panelText += tr("Farmable")
		panelText += "\n[/color]"

	var healAmount = itemData.get("Heal")
	if healAmount:
		panelText += "[color=#7FC675][img]res://Sprites/icon_heart.png[/img] "
		panelText += str(healAmount)
		panelText += "\n[/color]"

	for j in range(keys.size()):
		var result = itemData.get(keys[j], null)
		if result:
			if higherBetter[j] && result > 0:
				panelText += "[color=#7FC675]"
			elif !higherBetter[j] && result < 0:
				panelText += "[color=#7FC675]"
			else:
				panelText += "[color=#FF7792]"
			panelText += "[img]" + icons[j] + "[/img] "
			panelText += str(result)
			panelText += "\n"
			panelText += "[/color]"

	var craftingBuildings = Global.createdInTable.get(activeID)
	if craftingBuildings:
		if craftingBuildings.size() > 0:
			panelText += tr("Created In") + "\n"
			for buildingID in craftingBuildings:
				var building = Global.buildingsTree.search_building_by_id(buildingID)
				panelText += "[img=24]" + building.Sprite.resource_path + "[/img] "

	canDisplayInfo = false
	$InfoPanel / MarginContainer / HBoxContainer / Description.visible = false
	$InfoPanel / MarginContainer / HBoxContainer / VSeparator.visible = false
	$InfoPanel / MarginContainer / HBoxContainer / Stats.visible = false

	if panelText:
		$InfoPanel / MarginContainer / HBoxContainer / Stats.text = panelText
		canDisplayInfo = true
		$InfoPanel / MarginContainer / HBoxContainer / Stats.visible = true

	if description:
		$InfoPanel / MarginContainer / HBoxContainer / Description.text = description
		$InfoPanel / MarginContainer / HBoxContainer / Description.visible = true
		canDisplayInfo = true
		if panelText:
			$InfoPanel / MarginContainer / HBoxContainer / VSeparator.visible = true

	$NameLabel.update_position()


func check_input():
	if is_multiplayer_authority():
		if !disabled:
			if previewPath != null:
				var preview = get_node(previewPath)

				if clickDelay <= 0:
					if filter:
						if Input.is_action_pressed("ui_click"):
							preview.set_filter.rpc_id(1, path, name.to_int())
						return

					if Input.is_action_pressed("shift"):
						if Input.is_action_just_pressed("ui_click"):
							canShift = true

						if canShift:
							if Input.is_action_pressed("ui_click") || Input.is_action_pressed("ui_click_right"):
								canShift = false
								preview.slot_clicked.rpc_id(1, path, name.to_int(), false, true)

					elif Input.is_action_just_pressed("inventory_shift_click"):
						preview.slot_clicked.rpc_id(1, path, name.to_int(), false, true)

					elif Input.is_action_just_pressed("middle_click"):
						preview.sort_inventory.rpc_id(1, path)
						clickDelay = 0.1
					elif Input.is_action_just_pressed("ui_click"):
						preview.slot_clicked.rpc_id(1, path, name.to_int())
						clickDelay = 0.1
						force_highlight()
					elif Input.is_action_just_pressed("ui_click_right"):
						preview.slot_clicked.rpc_id(1, path, name.to_int(), true)
						clickDelay = 0.1
						force_highlight()
					elif Input.is_action_just_pressed("quick_select"):
						preview.quick_select(path, name.to_int())
						clickDelay = 0.1


func force_highlight():
	grab_click_focus()
	$NameLabel.visible = true
	scaleOffset = Vector2(0.2, 0.2)
	canShift = true
	update_info_panel()


func highlight():
	if Global.controllerActive:
		var screen_coord = get_viewport().get_screen_transform() * (global_position + size / 2)
		Input.warp_mouse(screen_coord)

	if itemID != "" || placeholderID != "":
		force_highlight()


func _on_mouse_entered():
	mouseHovered = true
	highlight()


func _on_mouse_exited():
	mouseHovered = false
	release_highlight()


func release_highlight():
	scaleOffset = Vector2(0, 0)
	$NameLabel.visible = false
	release_focus()
	$InfoPanel.visible = false
