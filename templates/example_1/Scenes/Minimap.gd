extends MarginContainer

@export var display: TextureRect
@export var noise: NoiseTexture2D
@export var gradient: Gradient

var timer = 5.0
var currentTimer = timer
var mapSize
var regionMaps: Dictionary = {}

var buildingColor = Color.hex(4276576767)
var logisticColor = Color.hex(3939805951)


var currentDungeonRooms = []
var currentRoom = Vector2.ZERO
var roomsVisited = []

var initialLoad = false
var activeIDs = []

func _ready():
	if is_multiplayer_authority():
		mapSize = Global.generationInfo.Size

		Global.fully_loaded.connect(setup_maps)
		Global.level_changed.connect(clear_dungeon_data)
		Global.region_changed.connect(update_texture)


func setup_maps():
	print("\nCreating minimaps....")
	var tiling_start = Time.get_ticks_msec()

	for i in Global.regionsTable:
		regionMaps.get_or_add(i, Image.create(mapSize, mapSize, false, Image.FORMAT_RGB8))

	for i in regionMaps:
		update_map(i)

	print("Done! - took " + str(Time.get_ticks_msec() - tiling_start) + "ms\n")


func _process(_delta):
	$MarginContainer.custom_minimum_size = Vector2(Global.minimapSize, Global.minimapSize)
	$MarginContainer.size = Vector2.ZERO

	visible = Global.is_in_automation() || Global.is_in_dungeon()
	modulate = Color(1, 1, 1, Global.minimapTransparency)

	if Global.is_in_dungeon():
		var dungeonTag = "{0}{1}".format([Global.currentRegionID, Global.currentLevel])
		if currentDungeonRooms == []:
			var dungeon = owner.get_parent().get_node_or_null("Dungeon")
			if dungeon:
				currentDungeonRooms = dungeon.allRooms.get(dungeonTag, [])
				if currentDungeonRooms != []:
					build_dungeon_minimap(dungeon, dungeonTag)


	if Global.is_in_automation():
		var ids = multiplayer.get_peers()
		$MarginContainer / Automation.visible = true
		$MarginContainer / RoomGrid.visible = false

		for i in range(activeIDs.size() - 1, -1, -1):
			var id = activeIDs[i]

			if !ids.has(id):
				var icon = get_node_or_null("MarginContainer/Automation/" + str(id))
				if icon:
					icon.queue_free()
					activeIDs.erase(id)

		for id in ids:
			if !activeIDs.has(id):
				var icon = load("res://player_map_icon.tscn").instantiate()
				icon.player = owner.get_parent().get_node(str(id))

				icon.name = str(id)
				$MarginContainer / Automation.add_child(icon)
				activeIDs.push_back(id)


func clear_dungeon_data():
	currentDungeonRooms = []


func build_dungeon_minimap(dungeon, dungeonTag):
	roomsVisited = [Vector2.ZERO]
	var grid: GridContainer = $MarginContainer / RoomGrid

	$MarginContainer / Automation.visible = false
	grid.visible = true

	currentDungeonRooms = dungeon.allRooms[dungeonTag]

	var minWidth = dungeon.dungeonData[dungeonTag].MinWidth
	var maxWidth = dungeon.dungeonData[dungeonTag].MaxWidth
	var minHeight = dungeon.dungeonData[dungeonTag].MinHeight
	var maxHeight = dungeon.dungeonData[dungeonTag].MaxHeight

	for i in grid.get_children():
		i.queue_free()

	grid.columns = abs(minWidth) + maxWidth + 1
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	for y in range(minHeight, maxHeight + 1):
		for x in range(minWidth, maxWidth + 1):
			var makeSpacer = true

			for k in currentDungeonRooms:
				if k.has(Vector2(x, y)):
					var texture = load("res://Scenes/dungeon_minimap_room.tscn").instantiate()
					texture.minimap = self
					texture.coord = Vector2(x, y)
					texture.texture = load("res://Sprites/room_unknown.png")
					grid.add_child(texture)
					makeSpacer = false

			if makeSpacer:
				var spacer = TextureRect.new()
				grid.add_child(spacer)
				spacer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				spacer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				spacer.texture = load("res://Sprites/room_unknown.png")
				spacer.modulate.a = 0.0


func update_tile(regionID, tilePos, isLand):
	if !is_multiplayer_authority():
		return

	if regionID != "starground:region_veridian":
		return

	var tilemap: TileMapLayer = ModAPI.get_tilemap_from_id(regionID)
	if !tilemap:
		return

	var image: Image = regionMaps.get(regionID)

	var region = Global.regionsTable.get(regionID)
	var terrainColor = region.TerrainColor
	var shoreColor = region.ShoreColor
	var waterColor = region.WaterColor

	var tiles = [
		tilePos, 
		tilePos + Vector2i(1, 0), 
		tilePos + Vector2i(1, 1), 
		tilePos + Vector2i(0, 1), 
		tilePos + Vector2i(-1, 1), 
		tilePos + Vector2i(-1, 0), 
		tilePos + Vector2i(-1, -1), 
		tilePos + Vector2i(0, -1), 
		tilePos + Vector2i(1, -1), 
	]

	await Engine.get_main_loop().physics_frame

	for i in tiles:
		if i.x >= 0 && i.x < mapSize && i.y >= 0 && i.y < mapSize:
			var tileData = tilemap.get_cell_tile_data(i)
			if tileData:
				if tileData.get_custom_data(^"Solid"):
					if isLand && i == tilePos:
						image.set_pixel(i.x, i.y, terrainColor)
				else:
					image.set_pixel(i.x, i.y, shoreColor)
			else:
				image.set_pixel(i.x, i.y, waterColor)

	update_texture()


func update_map(regionID):
	var tilemap: TileMapLayer = ModAPI.get_tilemap_from_id(regionID)
	if !tilemap:
		return

	var tiles = tilemap.get_used_cells()
	var image: Image = regionMaps.get(regionID)

	var region = Global.regionsTable.get(regionID)
	var terrainColor = region.TerrainColor
	var shoreColor = region.ShoreColor
	var waterColor = region.WaterColor

	image.fill(waterColor)

	var customData = ^"Solid"

	Global.collision_changed.emit()

	for tile in tiles:
		if tile.x < 0 || tile.x >= mapSize || tile.y < 0 || tile.y >= mapSize:
			continue

		if regionID == "starground:region_veridian" && tilemap.get_cell_tile_data(tile).get_custom_data(customData):
			image.set_pixel(tile.x, tile.y, terrainColor)
		else:
			image.set_pixel(tile.x, tile.y, shoreColor)

	for i in get_tree().get_nodes_in_group("Buildable"):
		draw_building(i.global_position, i, false, true)

	initialLoad = true
	update_texture()


func update_texture():
	var image = regionMaps.get(Global.currentRegionID)
	if image:
		display.texture = ImageTexture.create_from_image(image)


func draw_building(pos, building, update = false, override = false):
	if initialLoad || override:
		var buildingReference = Global.buildingsTree.search_building_by_id(building.buildingID)
		if buildingReference:
			if building.is_in_group("Dungeon"):
				return

			var regionID = ModAPI.get_region_id_at_position(pos)
			var image = regionMaps.get(regionID)
			var regionPos = Global.regionsTable.get(regionID).Location
			var coord = floor((((pos - regionPos) - buildingReference.ObjectSize / 2.0) / 16.0) + Vector2(mapSize / 2.0, mapSize / 2.0))

			var customColor = buildingColor

			if !(building is Bounceable || building is Vehicle):
				if building is Conveyor || building is Mover || building is ConveyorTunnel:
					customColor = logisticColor

				var centerOffset = floor(buildingReference.ObjectSize / 2.0)
				centerOffset = Vector2(centerOffset.x - (1 - fmod(buildingReference.ObjectSize.x, 2)), centerOffset.y - (1 - fmod(buildingReference.ObjectSize.y, 2)))
				for x in range(0 - centerOffset.x, buildingReference.ObjectSize.x - centerOffset.x):
					for y in range(0 - centerOffset.y, buildingReference.ObjectSize.y - centerOffset.y):
						if coord.x + x < mapSize && coord.y + y < mapSize && coord.x + x >= 0 && coord.y + y >= 0:
							image.set_pixel(coord.x + x, coord.y + y, customColor)
				if update:
					update_texture()

				Global.collision_changed.emit()


func erase_building(pos, buildingObject, update = false):
	if initialLoad:
		var buildingReference = Global.buildingsTree.search_building_by_id(buildingObject.buildingID)

		if buildingReference:
			if buildingObject.is_in_group("Dungeon"):
				return

			var regionID = ModAPI.get_region_id_at_position(pos)
			var image = regionMaps.get(regionID)
			var region = Global.regionsTable.get(regionID)
			var regionPos = region.Location
			var tilemap = ModAPI.get_tilemap_from_id(regionID)

			var terrainColor = region.TerrainColor
			var waterColor = region.WaterColor

			var coord = floor((((pos - regionPos) - buildingReference.ObjectSize / 2.0) / 16.0) + Vector2(mapSize / 2.0, mapSize / 2.0))

			var centerOffset = floor(buildingReference.ObjectSize / 2.0)
			centerOffset = Vector2(centerOffset.x - (1 - fmod(buildingReference.ObjectSize.x, 2)), centerOffset.y - (1 - fmod(buildingReference.ObjectSize.y, 2)))

			for x in range(0 - centerOffset.x, buildingReference.ObjectSize.x - centerOffset.x):
				for y in range(0 - centerOffset.y, buildingReference.ObjectSize.y - centerOffset.y):
					pos = Vector2(coord.x + x, coord.y + y)

					if pos.x < mapSize && pos.y < mapSize && pos.x >= 0 && pos.y >= 0:
						var tile = tilemap.get_cell_tile_data(pos)
						if !tile:
							image.set_pixel(pos.x, pos.y, waterColor)
						else:
							image.set_pixel(pos.x, pos.y, terrainColor)
			if update:
				update_texture()

			Global.collision_changed.emit()
