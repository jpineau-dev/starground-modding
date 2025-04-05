extends Node2D
 
var canPlaceColor = Color(0, 0.5, 1, 0.75)
var cannotPlaceColor = Color(1, 0.5, 0.5, 0.75)
var replaceColor = Color(0, 1, 0.5, 0.75)
var spriteOffset = Vector2(0, 0)
 
var object = null
var objectSize = Vector2i(1, 1)
var objectRotation = 0
var nodeType = ""
var objectID = ""
var connection = null
 
var tempPos
var tempIndex
var hasItems = false
var canPlaceWater = false
var canPlaceLand = false
var tile
var showLastIndicators = false
var usesPower = false
var bannedRegions = []
 
var unshadedShader = load("res://building_unshaded.tres")
 
func _ready():
	visible = false
 
 
func get_sprite(newObject):
	if !newObject.SpriteArray.is_empty():
		$Sprite.rotation = 0
		return newObject.SpriteArray[roundi(objectRotation / 90.0)]
 
	return newObject.Sprite
 
 
func select_new_object(newObjectID):
	if showLastIndicators:
		for i in get_tree().get_nodes_in_group(nodeType):
			i.set_indicator_visibility(false)
 
	object = Global.buildingsTree.search_building_by_id(newObjectID)
 
	if object:
		objectID = newObjectID
		if is_instance_valid(owner.lastHoveredObject):
			owner.lastHoveredObject.hovered = false
			owner.lastHoveredObject.set_indicator_visibility(false)
			owner.lastHoveredObject = null
 
		canPlaceWater = object.get("CanPlaceWater", false)
		canPlaceLand = object.get("CanPlaceLand", false)
 
		bannedRegions = object.BannedRegions
 
		if object.CanRotate:
			$Sprite.rotation = deg_to_rad(objectRotation)
		else:
			objectRotation = 0
 
		for i in $Ingredients.get_children():
			i.free()
 
		$Ingredients.size = Vector2(0, 0)
 
		for i in object.Ingredients:
			var resource = load("res://Scenes/Displays/item_cost_indicator.tscn").instantiate()
			resource.itemID = i.ID
			resource.requiredAmount = i.Amount
			$Ingredients.add_child(resource)
 
		$Sprite.texture = get_sprite(object)
 
		if roundi(objectRotation / 90.0) % 2 == 0:
			objectSize.x = object.ObjectSize.x
			objectSize.y = object.ObjectSize.y
		else:
			objectSize.x = object.ObjectSize.y
			objectSize.y = object.ObjectSize.x
 
		spriteOffset = object.SpriteOffset
		$Area2D / Collider.shape.size = Vector2(15, 15) * Vector2(objectSize)
		$Sprite.offset = spriteOffset
		$Area2D.set_collision_mask_value(2, object.PlayerCollision)
		$Area2D.set_collision_mask_value(1, !object.CanPlaceShore)
 
		if !Global.currentRegion.Underwater && canPlaceWater && !canPlaceLand:
			$Area2D.set_collision_mask_value(13, true)
		else:
			$Area2D.set_collision_mask_value(13, false)
 
		var oldIndicator = get_node_or_null("areaIndicator")
		if oldIndicator:
			oldIndicator.free()
 
		var loadedObj = load(object.ObjectPath).instantiate()
		var test = loadedObj.get_node_or_null("areaIndicator")
		var undergroundRay = loadedObj.get_node_or_null("UndergroundCheck")
 
		nodeType = loadedObj.get_custom_class()
		showLastIndicators = loadedObj.showSameIndicators
 
		usesPower = object.PowerStatus != 0 || nodeType == "Battery"
 
		if showLastIndicators:
			for i in get_tree().get_nodes_in_group(nodeType):
				i.set_indicator_visibility(true)
 
		if usesPower:
			for i in get_tree().get_nodes_in_group("TeslaCoil"):
				i.set_indicator_visibility(true)
 
		if undergroundRay:
			$UndergroundRay.collision_mask = undergroundRay.collision_mask
 
		if test:
			var indicator = test.duplicate()
			indicator.visible = true
			if object.CanRotate:
				indicator.rotation = deg_to_rad(objectRotation)
			indicator.set_material(unshadedShader)
			for i in indicator.get_children():
				i.set_material(unshadedShader)
 
			add_child(indicator, true)
 
		$UndergroundRay.shape.b = Vector2(0, -128).rotated(deg_to_rad(objectRotation))
		loadedObj.queue_free()
		visible = true
 
		return true
 
	return false
 
 
var lineOffset = Vector2(0, 16)
 
func _draw():
	if nodeType == "TeslaCoil":
		for i in get_tree().get_nodes_in_group("TeslaCoil"):
			if global_position.distance_squared_to(i.global_position - (global_position.direction_to(i.global_position) * (objectSize * 8.0))) < i.areaSize:
				draw_line(global_position - global_position - lineOffset, i.global_position - global_position - lineOffset, Color(0.0, 0.5, 1.0, 0.75), 1.0)
 
 
func _physics_process(_delta):
	if Global.ingame:
		if is_multiplayer_authority():
			if object != null && visible:
				var location = get_parent().get_parent().global_position
 
				if Global.controllerActive:
					location = get_parent().get_parent().miningTargetPos
				else:
					location = get_global_mouse_position()
 
				if objectSize.x % 2 != 0:
					global_position.x = snapped(location.x + 8, 16) - 8
				else:
					global_position.x = snapped(location.x, 16)
 
				if objectSize.y % 2 != 0:
					global_position.y = snapped(location.y + 8, 16) - 8
				else:
					global_position.y = snapped(location.y, 16)
 
				if Global.currentTilemap:
					tile = Global.currentTilemap.get_cell_tile_data(Global.currentTilemap.local_to_map(Global.currentTilemap.to_local(global_position)))
 
				if connection && (global_position.x == connection.global_position.x || global_position.y == connection.global_position.y):
					$"../Line2D".visible = true
					$"../Line2D".points[0] = global_position
					$"../Line2D".points[1] = connection.global_position
					$"../Line2D".visible = visible
				else:
					$"../Line2D".visible = false
 
				hasItems = false
				var checkAllItems = true
 
				for i in object.Ingredients:
					var amount = get_parent().get_parent().get_node("inventory_component").get_count(i.ID)
					if amount < i.Amount:
						checkAllItems = false
						break
 
				hasItems = checkAllItems
				$Ingredients.position = Vector2(( - $Ingredients.size.x / 2) * $Ingredients.scale.x, ((objectSize.y / 2.0) * 16) + 2)
 
				if object.CanRotate:
					if Input.is_action_just_pressed("rotate_building"):
						if Input.is_action_pressed("shift"):
							objectRotation = (objectRotation - 90) % 360
						else:
							objectRotation = (objectRotation + 90) % 360
 
						if !object.CanRotate || roundi(objectRotation / 90.0) % 2 == 0:
							objectSize.x = object.ObjectSize.x
							objectSize.y = object.ObjectSize.y
						else:
							objectSize.x = object.ObjectSize.y
							objectSize.y = object.ObjectSize.x
 
						$Area2D / Collider.shape.size = Vector2(15, 15) * Vector2(objectSize)
						$UndergroundRay.shape.b = Vector2(0, -128).rotated(deg_to_rad(objectRotation))
 
						if object.SpriteArray.is_empty():
							$Sprite.rotation = deg_to_rad(objectRotation)
 
						$Sprite.texture = get_sprite(object)
 
						var indicator = get_node_or_null("areaIndicator")
 
						if indicator:
							indicator.rotation = deg_to_rad(objectRotation)
				else:
					objectRotation = 0
					$Sprite.rotation = 0
 
				queue_redraw()
				if usesPower:
					$NoConnection.position = Vector2(0, - ((objectSize.y / 2.0) * 16) - 8)
					var closestTesla = ModAPI.get_closest_node(global_position, "TeslaCoil")
 
					if closestTesla && global_position.distance_squared_to(closestTesla.global_position - (global_position.direction_to(closestTesla.global_position) * (objectSize * 8.0))) < closestTesla.areaSize:
						$NoConnection.visible = false
					else:
						$NoConnection.visible = true
				else:
					$NoConnection.visible = false
 
				connection = null
				var undergrounds = []
				for i in $UndergroundRay.collision_result:
					if is_instance_valid(i.collider):
						undergrounds.push_back(i.collider)
 
				undergrounds.sort_custom(sort_closest)
				if nodeType == "UndergroundConveyor":
					for i in undergrounds:
						var test = i
						if is_instance_valid(test):
							var vec = Vector2.DOWN.rotated(deg_to_rad(objectRotation))
							if test.dir == Vector2(roundi(vec.x), roundi(vec.y)):
								if test.entrance:
									connection = test
								else:
									break
 
				var surroundCheck = true
				if nodeType == "LandTile":
					for i in $landtile_check.get_overlapping_bodies():
						if i is Buildable:
							var size = i.buildingData.ObjectSize / 2.0
							var space_state: PhysicsDirectSpaceState2D = owner.get_parent().get_world_2d().direct_space_state
							var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(i.global_position - (size * 16) + Vector2(1, 1), i.global_position + (size * 16) - Vector2(1, 1), 4096)
							query.collide_with_bodies = true
							query.hit_from_inside = true
							var result: Dictionary = space_state.intersect_ray(query)
							if !result:
								surroundCheck = false
								break
 
				var waterPlaceable = false
				if nodeType == "LandTile":
					var tilemap = ModAPI.get_tilemap_at_position(global_position)
					if tilemap:
						var cellData = tilemap.get_cell_tile_data(tilemap.local_to_map(tilemap.to_local(global_position)))
						if cellData:
							waterPlaceable = !cellData.get_custom_data("Solid")
						else:
							waterPlaceable = true
				else:
					waterPlaceable = (( !object.CanPlaceWater && $LandChecker.has_overlapping_bodies()) || object.CanPlaceWater)
 
				var mapEdge = ((Global.generationInfo.Size / 2.0) + 8.0) * 16
				var locOffset = Global.currentRegion.Location
				var insideBoundries = global_position.x > - mapEdge + locOffset.x && global_position.x < mapEdge + locOffset.x && global_position.y > - mapEdge + locOffset.y && global_position.y < mapEdge + locOffset.y
 
				var canPlace = ((nodeType == "LandTile" && surroundCheck) || nodeType != "LandTile") && hasItems && (Global.is_in_automation() || nodeType == "Skateboard")\
&& global_position.distance_to(get_parent().get_parent().global_position) < get_parent().get_parent().interactRange\
&& waterPlaceable && visible && insideBoundries && !bannedRegions.has(Global.currentRegionID)
 
				if canPlace && ( !$Area2D.has_overlapping_bodies() || nodeType == "Conveyor"):
					$Sprite.modulate = canPlaceColor
 
					if Input.is_action_pressed("ui_click"):
						var data = {
							"BuildingID": objectID, 
							"Object": object, 
							"Rotation": deg_to_rad(objectRotation), 
							"Size": objectSize, 
							"Connection": connection, 
							"Type": nodeType, 
						}
 
						Global.main.build_object.rpc_id(1, global_position, data)
				else:
					$Sprite.modulate = cannotPlaceColor
 
				if $Area2D.has_overlapping_bodies() && nodeType == "Conveyor":
					var bod = $Area2D.get_overlapping_bodies()[0]
					if bod is Buildable:
						if bod is Conveyor:
							$Sprite.modulate = replaceColor
						else:
							$Sprite.modulate = cannotPlaceColor
					else:
						$Sprite.modulate = cannotPlaceColor
 
 
func sort_closest(a, b):
	if global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position):
		return true
	return false
 
 
func _on_visibility_changed():
	if !visible:
		if showLastIndicators:
			for i in get_tree().get_nodes_in_group(nodeType):
				i.set_indicator_visibility(false)
 
		for i in get_tree().get_nodes_in_group("TeslaCoil"):
			i.set_indicator_visibility(false)
