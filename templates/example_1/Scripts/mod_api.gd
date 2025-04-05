extends Node





















enum RESEARCH_TYPES{INFINITE, SINGLE, TIERED}
enum DAMAGE{SHARP, BLUNT, MAGIC}
enum REGION{AUTOMATION, SPACE, DUNGEON}
enum ENTITY_TYPES{ENTITY, ANIMAL, ENEMY}

























func add_building_entry(categoryID: String, buildingID : String, entry : BuildingEntry) -> void:
	var category = Global.buildingsTree.tree.get(categoryID)
	
	if category is not BuildingCategory:
		print("Invalid building category: " + categoryID)
		return
	
	var buildingEntry = category.buildings.get_or_add(buildingID, entry)
	# We want to override the existing building
	buildingEntry = entry;





func add_effect_entry(effectID: String, entry: Dictionary) -> void :
	Global.effectsTable.merge({effectID: entry}, true)





func add_shop_entry(shopID: String, entry: Dictionary) -> void :
	Global.shopTable.merge({shopID: entry}, true)






func add_recipe_entry(buildingID: String, recipeID: String, entry: Dictionary) -> void :
	if Global.recipeTable.has(buildingID):
		Global.recipeTable[buildingID].merge({recipeID: entry}, true)
	else:
		Global.recipeTable[buildingID] = {recipeID: entry}





func add_region_entry(regionID: String, entry: Dictionary) -> void :
	Global.regionsTable.merge({regionID: entry}, true)





func add_research_entry(researchID: String, entry: Dictionary) -> void :
	Global.researchTable.merge({researchID: entry}, true)






func add_item_entry(itemID: String, entry: Dictionary) -> void :
	Global.itemsTable.merge({itemID: entry}, true)





func add_cache_entry(resourcePath: String) -> void :
	Global.cacheTable.push_back(resourcePath)







func add_loot_entry(lootID: String, entry: Array) -> void :
	if Global.lootTable.has(lootID):
		Global.lootTable[lootID].push_back(entry)
	else:
		Global.lootTable[lootID] = [entry]








func add_player_ui(scenePath) -> void :
	Global.playerUIScenes.push_back(scenePath)





func add_spawner_entry(resourcePath: String) -> void :
	Global.spawnerTable.push_back(resourcePath)





func add_ui_spawner_entry(resourcePath: String) -> void :
	Global.uiSpawnerTable.push_back(resourcePath)





func add_command(command: String, scriptPath: String) -> void :
	Global.commandsTable.merge({command: {"Resource": scriptPath}}, true)










































func create_research_entry(researchName: String, inputItems: Array, unlocks: Array, specialTags: Dictionary) -> Dictionary:
	var entry: Dictionary = {
		"Name": researchName, 
		"Input": inputItems, 
		"Unlocks": unlocks, 
	}

	entry.merge(specialTags)

	return entry









func create_item_dict(itemID: String, amount: int):
	return {
		"ID": itemID, 
		"Amount": amount, 
		"Held": false, 
	}





func create_effect_entry(effectName, effectScriptPath) -> Dictionary:
	var entry: Dictionary = {
		"Name": effectName, 
		"Resource": effectScriptPath, 
	}

	return entry








func create_item_entry(Name: String, Sprite: Object, specialTags: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = {
		"Name": Name, 
		"Sprite": Sprite, 
	}

	entry.merge(specialTags)

	return entry





func sin_range(minNum: float, maxNum: float, t: float) -> float:
	var halfRange: float = (maxNum - minNum) / 2.0
	return minNum + halfRange + sin(t) * halfRange



func get_closest_player_target(position: Vector2) -> Variant:
	var dist: float = INF
	var node: Variant

	for i in get_tree().get_nodes_in_group("Players"):
		if !i.hasDied:
			var newDist: float = position.distance_squared_to(i.global_position)
			if newDist < dist:
				node = i
				dist = newDist
	return node



func get_closest_node(position: Vector2, groupName: String) -> Variant:
	var dist: float = INF
	var node: Variant

	for i in get_tree().get_nodes_in_group(groupName):
		var newDist: float = position.distance_squared_to(i.global_position)
		if newDist < dist:
			node = i
			dist = newDist
	return node


@rpc("call_local", "any_peer")
func set_rain(rainTimer: float, rainLength: float):
	Global.main.rainTimer = rainTimer
	Global.main.rainLength = rainLength


@rpc("call_local", "any_peer")
func set_time(time: float) -> void :
	Global.main.time = time



func get_closest_player_target_and_dist(position: Vector2) -> Array:
	var dist: float = INF
	var node: Player

	for i in get_tree().get_nodes_in_group("Players"):
		if !i.hasDied:
			var newDist: float = position.distance_to(i.global_position)
			if newDist < dist:
				node = i
				dist = newDist

	return [node, dist]



func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)



func get_item_data(itemID) -> Dictionary:
	return Global.itemsTable.get(itemID, Global.itemsTable["starground:nai"])






func replace_path(oldPath: String, newPath: String) -> void :
	if newPath.contains("global.gd"):
		printerr("Invalid overriding of global.gd!")
		return

	load(newPath).take_over_path(oldPath)




func choose_weighted_loot(lootID: String, randGen: RandomNumberGenerator = RandomNumberGenerator.new()) -> Array:
	var sum: float = 0.0
	for i: Array in Global.lootTable.get(lootID):
		sum += i[0]

	var rand: float = randGen.randf_range(0, sum)

	for i: Array in Global.lootTable.get(lootID):
		if rand < i[0]:
			return i
		rand -= i[0]
	return []



func get_region_at_position(position: Vector2) -> Dictionary:
	return Global.regionsTable.get(get_region_id_at_position(position), {})



func get_region_id_at_position(position: Vector2) -> String:
	var dist: float = INF
	var regionID: String

	for i in Global.regionsTable:
		var newDist: float = position.distance_squared_to(Global.regionsTable[i].Location)
		if newDist < dist:
			dist = newDist
			regionID = i

	return regionID



func get_region_from_id(regionID) -> Dictionary:
	var region = Global.regionsTable.get(regionID)
	return region



func get_tilemap_at_position(position: Vector2) -> TileMapLayer:
	var tilemap: TileMapLayer
	var selectedRegion: Dictionary = get_region_at_position(position)
	var tilemapPath = selectedRegion.get("Tilemap")
	if tilemapPath:
		tilemap = get_node_or_null("/root/Multiplayer/World/" + selectedRegion.Tilemap)

	return tilemap



func get_tilemap_from_id(regionID) -> TileMapLayer:
	var tilemap: TileMapLayer
	var region = Global.regionsTable.get(regionID)
	var tilemapPath = region.get("Tilemap")

	if tilemapPath:
		tilemap = get_node_or_null("/root/Multiplayer/World/" + region.Tilemap)

	return tilemap



func get_decoration_tilemap_at_position(position: Vector2) -> TileMapLayer:
	var tilemap: TileMapLayer
	var selectedRegion: Dictionary = get_region_at_position(position)
	tilemap = get_node("/root/Multiplayer/World/" + selectedRegion.DecorationTilemap)

	return tilemap



func build_gun_sprite(invdata: Array) -> Dictionary:
	var parts: Array[Image] = []

	var height: int = 0
	var bottomHeight: int = 0
	var width: int = 0

	var returnData: Dictionary = {
		"Sprite": null, 
		"RotationOffset": Vector2(0, 0), 
		"LeftHandPos": Vector2(0, 0), 
		"RightHandPos": Vector2(0, 0), 
		"BarrelTip": Vector2(0, 0), 
	}

	for i in range(3, invdata.size()):
		if invdata[i]:
			var itemData: Dictionary = ModAPI.get_item_data(invdata[i].ID)
			var img: Image = itemData.Sprite.get_image()
			img.convert(Image.FORMAT_RGBA8)
			parts.push_back(img)

			if i < 6:
				var subNum: int = 1

				match (i):
					3: subNum = 1
					4: subNum = 0
					5: subNum = 1

				width += itemData.Sprite.get_image().get_width() - subNum

				if bottomHeight < itemData.Sprite.get_image().get_height():
					bottomHeight = itemData.Sprite.get_image().get_height()
		else:
			parts.push_back(Image.create_empty(1, 1, false, Image.FORMAT_RGBA8))

	if parts[1].get_height() <= 1:
		parts[1].crop(1, max(bottomHeight, 1))
		width += 1



	height = max(bottomHeight / 2.0 + parts[1].get_height() / 2.0, bottomHeight) + parts[3].get_height() - 1

	var scopeLeft = parts[3].get_width() / 2.0 > parts[0].get_width() - 1 + parts[1].get_width() / 2.0
	var scopeRight = parts[3].get_width() / 2.0 > parts[2].get_width() - 1 + parts[1].get_width() / 2.0

	if scopeLeft && scopeRight:
		width = parts[3].get_width()
	elif scopeLeft:
		width = parts[3].get_width() / 2.0 + parts[1].get_width() / 2.0 + parts[2].get_width() - 1
	elif scopeRight:
		width = parts[0].get_width() - 1 + parts[1].get_width() / 2.0 + parts[3].get_width() / 2.0



	if width > 0 && height > 0:
		var img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0))


		var pos0
		var pos1
		var pos2
		var pos3

		if scopeLeft:
			pos1 = Vector2i(parts[3].get_width() / 2.0 - parts[1].get_width() / 2.0, max(parts[3].get_height() - 1, bottomHeight / 2.0 - parts[1].get_height() / 2.0))
			pos0 = Vector2i(pos1.x - parts[0].get_width() + 1, pos1.y + parts[1].get_height() / 2.0 - parts[0].get_height() / 2.0)
			pos2 = Vector2i(pos1.x + parts[1].get_width() - 1, pos1.y + parts[1].get_height() / 2.0 - parts[2].get_height() / 2.0)
			pos3 = Vector2i(0, pos1.y - parts[3].get_height() + 1)
		else:
			pos0 = Vector2i(0, height - floor(bottomHeight / 2.0) - parts[0].get_height() / 2.0)
			pos1 = Vector2i(parts[0].get_width() - 1, height - floor(bottomHeight / 2.0) - parts[1].get_height() / 2.0)
			pos2 = Vector2i(parts[0].get_width() + parts[1].get_width() - 2, height - floor(bottomHeight / 2.0) - parts[2].get_height() / 2.0)
			pos3 = Vector2i(pos1.x + parts[1].get_width() / 2.0, pos1.y) - Vector2i(parts[3].get_width() / 2.0, parts[3].get_height() - 1)

		img.blit_rect_mask(parts[0], parts[0], Rect2i(Vector2i.ZERO, Vector2i(parts[0].get_width(), parts[0].get_height())), pos0)
		img.blit_rect_mask(parts[2], parts[2], Rect2i(Vector2i.ZERO, Vector2i(parts[2].get_width(), parts[2].get_height())), pos2)
		img.blit_rect_mask(parts[3], parts[3], Rect2i(Vector2i.ZERO, Vector2i(parts[3].get_width(), parts[3].get_height())), pos3)
		img.blit_rect_mask(parts[1], parts[1], Rect2i(Vector2i.ZERO, Vector2i(parts[1].get_width(), parts[1].get_height())), pos1)



		returnData.RotationOffset = Vector2(parts[1].get_width() / 2.0, - (height / 2.0 - bottomHeight / 2.0))
		returnData.BarrelTip = Vector2( - ((width / 2.0) - pos2.x - returnData.RotationOffset.x - parts[2].get_width()), 0)
		returnData.Sprite = ImageTexture.create_from_image(img)
		var handHeight = - bottomHeight / 2.0 + bottomHeight / 1.25
		returnData.LeftHandPos = Vector2( - ((width / 2.0) - pos0.x - returnData.RotationOffset.x - parts[0].get_width() / 2.0), handHeight)
		returnData.RightHandPos = Vector2(returnData.BarrelTip.x - parts[2].get_width(), handHeight)

	return returnData



func build_melee_sprite(invdata: Array) -> ImageTexture:
	var parts: Array[Image] = []
	var totalHeight: int = 0
	var maxWidth: int = 0

	for i in range(0, 3):
		if invdata[i]:
			var itemData: Dictionary = ModAPI.get_item_data(invdata[i].ID)
			parts.push_back(itemData.Sprite.get_image())
			parts[i].convert(Image.FORMAT_RGBA8)
			totalHeight += parts[i].get_height()
			var width = parts[i].get_width()
			if width > maxWidth:
				maxWidth = width
		else:
			parts.push_back(null)

	if maxWidth > 0 && totalHeight > 0:
		var img = Image.create_empty(maxWidth, totalHeight, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0))
		var lastHeight = 0

		for i in range(parts.size() - 1, -1, -1):
			if parts[i] != null:
				var pos = Vector2i(roundi((maxWidth / 2.0)) - (roundi(parts[i].get_width() / 2.0)), lastHeight)
				lastHeight += parts[i].get_height()

				if i == 0:
					parts[i].flip_y()

				img.blit_rect_mask(parts[i], parts[i], Rect2i(Vector2i.ZERO, Vector2i(parts[i].get_width(), parts[i].get_height())), pos)

		return ImageTexture.create_from_image(img)
	return null


func get_current_events() -> PackedStringArray:
	var date = Time.get_datetime_dict_from_system()
	var events: PackedStringArray = []

	if date.day == 1 && date.month == 4:
		events.push_back("starground:event_april_fools'")

	return events


func generate_skin_preview(id):
	var uv: Image = load("res://Sprites/player_preview_uv.png").get_image()
	var skin: Image = Global.skinsTable.get(id).Sprite.get_image()
	var final: Image = load("res://Sprites/player_skin_outline.png").get_image()

	for x in range(0, 16):
		for y in range(17):
			var uvCol = uv.get_pixel(x, y)
			if uvCol.a > 0:
				final.set_pixel(x + 1, y, skin.get_pixel(uvCol.r8, uvCol.g8))

	return ImageTexture.create_from_image(final)
