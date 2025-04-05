extends Node

var itemsTable: Dictionary = {}
var buildingsTree: Resource = load("res://Resources/buildings_tree.tres")
var researchTable: Dictionary = {}
var recipeTable: Dictionary = {}
var cacheTable: Array = []
var lootTable: Dictionary = {}
var effectsTable: Dictionary = {}
var regionsTable: Dictionary = {}
var spawnerTable: Array = []
var uiSpawnerTable: Array = []
var createdInTable: Dictionary = {}
var commandsTable: Dictionary = {}
var shopTable: Dictionary = {}
var unlocksTable: Dictionary = {}
var playerUIScenes: Array = []
var questsTable: Dictionary[String, Dictionary] = {}
var entitiesTable: Dictionary[String, Dictionary] = {}
var skinsTable: Dictionary[String, Dictionary] = {}

var lastLoadedSave: Dictionary = {}
var unlockedSkins: PackedStringArray = []




var unlockedThings = []

var activeSkinID = "starground:skin_default"
signal skin_changed

var cachedResources = {}
var preloader: ResourcePreloader

var spawnedTyriaRuins = false

var skateboardTricks = [
	"360 Kickflip", 
	"900", 
	"1080", 
	"1260", 
	"Aerial", 
	"Benihana", 
	"Bertslide", 
	"Caballerial", 
	"Casper", 
	"Caveman", 
	"Christ Air", 
	"Dropping In", 
	"Flip Trick", 
	"Nosegrind", 
	"Noseslide", 
	"Boardslide", 
	"Bluntslide", 
	"Heelslide", 
	"Heelflip", 
	"Hill Bomb", 
	"Indy Grab", 
	"Kickflip", 
	"Kickturn", 
	"Lip trick", 
	"Manual Roll", 
	"Method Grab", 
	"Misty Flip", 
	"Nightmare Flip", 
	"No Comply", 
	"Nollie", 
	"Ollie", 
	"Pole Jam", 
	"Pump", 
	"Shove-it", 
	"Slide", 
	"Wallride", 
	"Front Flip", 
	"Back Flip", 
	"Coffin", 
	"Powerslide", 
]

var colors = {
	"Green": Color("#7FC675FF"), 
	"Red": Color("#FF99A7FF"), 
	"White": Color(1, 1, 1, 1)
}



var currentConvertFormat = 3

var foundConvertFormat = currentConvertFormat

var virtualKeyboard


signal fullscreen_changed
signal menu_loaded
signal input_type_changed
signal language_changed
signal mods_loaded


signal noise_generated
signal autotiling_finished
signal resources_generated
signal world_generated
signal buildings_loaded
signal fully_loaded
signal collision_changed
signal day_changed

signal starting_host(savePath)
signal starting_connect



signal level_changed
signal region_changed
signal player_entered_room
signal rain_changed

var fuelIDs = []

var disconnected = false
var disconnectMessage = "Unknown"
var username = "Player"
var UIScale = 4
var mouseInWindow = true
var lobbyID: int = 0
var lobbyType = 0
var basicsComplete = false
var completedTooltips = []
var hideChat = false
var rainActive = false
var rainInterval = Vector2(400, 2400)
var noclip = false
var commandsEnabled = false

var enabledMods = []
var loadedMods = []

var closeMenuDelay = 2
var currentCloseMenuDelay = 0


var inputType = INPUT.KEYBOARD
enum INPUT{KEYBOARD, CONTROLLER}

@onready var gameVersion = ProjectSettings.get_setting("application/config/version", "error")

var overlayObject
var hideUI = false

var buttonHoverSound
var buttonClickSound


var generationInfoDefaults = {
	"Seed": str(randi()), 
	"TerrainScale": 0.02, 
	"Size": 128, 
	"WaterLevel": 0.5, 
}

var generationInfo = generationInfoDefaults.duplicate(true)


var guideOpen: bool = false
var showFPS: bool = false
var showOverlay: bool = false
var fontType = 0
var vsyncMode = 0
var screenshake = 1.0
var tutorial: bool = true
var hidePlayerNames = false
var hideRain: bool = false
var hitFirst: bool = false
var minimapSize = 192
var minimapTransparency = 0.75
var showUnderwaterEffect: bool = true
var healthTransparency = 1.0
var smoothMining = true

var modWarningAcknowledged = false

var controllerActive = false

var ingame = false

var dayCycle = true

@onready var currentRegion = regionsTable.get("starground:region_veridian")
@onready var currentRegionID

var currentTilemap: TileMapLayer
var currentLevel = 0

var manualDisconnect = false

var multiplayerID = 1

var elevatorList = []

var fullyLoaded = false




var musicPlayer
var ambiencePlayer
var musicDelay = false

var activePlayer: Player = null
var main: Main

var heldItem
var voices = DisplayServer.tts_get_voices_for_language("en")
var voice_id = null
var activeLocation = ""
var userDataTimer = 10
var currentUserDataTimer = userDataTimer
var activeResearch = ""
var playerIsUnderwater = false


func toggle_underwater(underwater, playEffects):
	var sfxBus = AudioServer.get_bus_index("Sound Effects World")

	playerIsUnderwater = underwater

	var water = get_node_or_null("/root/Multiplayer/World/level/WaterOverlay")
	if water && Global.showUnderwaterEffect:
		water.visible = underwater

	if underwater:
		AudioServer.set_bus_effect_enabled(sfxBus, 1, true)
		AudioServer.set_bus_effect_enabled(sfxBus, 2, true)
		AudioServer.set_bus_effect_enabled(sfxBus, 3, true)
		AudioServer.set_bus_effect_enabled(sfxBus, 4, true)
	else:
		AudioServer.set_bus_effect_enabled(sfxBus, 1, false)
		AudioServer.set_bus_effect_enabled(sfxBus, 2, false)
		AudioServer.set_bus_effect_enabled(sfxBus, 3, false)
		AudioServer.set_bus_effect_enabled(sfxBus, 4, false)


func set_region(regionID: String):
	currentRegion = regionsTable.get(regionID)
	currentRegionID = regionID

	var sfxBus = AudioServer.get_bus_index("Sound Effects World")

	if regionID == "starground:region_veridian":
		if Global.ingame:
			currentTilemap = get_node("/root/Multiplayer/World/level/Tiles/Terrain")


	if regionID == "starground:region_tyria":
		if Global.ingame:
			currentTilemap = get_node("/root/Multiplayer/World/level/TilesGem/Terrain")
		toggle_underwater(true, false)
	else:
		toggle_underwater(false, false)

	AudioServer.set_bus_effect_enabled(sfxBus, 0, Global.is_in_dungeon())

	region_changed.emit()


func set_level(newLevel):
	currentLevel = newLevel
	level_changed.emit()


func read_mod_info(modFile):
	var info
	var reader = ZIPReader.new()

	var err = reader.open(modFile)
	if err == OK:
		if reader.file_exists("info.json"):
			var modInfo = reader.read_file("info.json")
			if modInfo:
				var convertedData = modInfo.get_string_from_utf8()
				if convertedData:
					info = JSON.parse_string(convertedData)

		reader.close()

	return info


func validate_mod(modFile):
	var reader = ZIPReader.new()

	var bannedKeywords = [
		"OS.", 
		"DirAccess.", 
		"ResourceLoader.", 
		"ResourceSaver.", 
		"IP.", 
		"FileAccess.", 
		"Steam.", 
	]


	var err = reader.open(modFile)
	if err == OK:
		var files = reader.get_files()
		for i in files:
			if i.get_extension() == "gdc":
				printerr("Mod uses binary tokenization for GDScript! Change this in the export settings to text only.\n")
				return false

			if i == "global.gd":
				printerr("Replacement of global.gd is restricted. Remove global.gd to allow loading.\n")
				return false

			if i.get_extension() == "gd":
				var file = reader.read_file(i)
				var readableFile = file.get_string_from_utf8()

				for j in bannedKeywords:
					if readableFile.find(j) > 0:
						printerr("Usage of " + j + " in " + i + " is restricted. Use ModAPI instead.\n")
						return false

		reader.close()
	return true


func load_text_from_file(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return content


func check_mod_file(modFile, subFile):
	var hasFile = false
	var reader = ZIPReader.new()

	var err = reader.open(modFile)
	if err == OK:
		hasFile = reader.file_exists(subFile)
		reader.close()
	return hasFile


func load_mods():
	var dir = DirAccess.open("user://mods")
	var mods = {}

	if dir:
		dir.list_dir_begin()
		var modFile = dir.get_next()
		while modFile != "":
			var modPath = "user://mods/" + modFile

			var info = read_mod_info(modPath)
			if info:
				if enabledMods.has(info.Data.ID):
					mods[info.Data.ID] = [info, modPath]
			else:
				printerr("Failed to load mod at " + modPath + ": No info.json file found!")

			modFile = dir.get_next()


	for i in Global.enabledMods:
		var modData = mods.get(i)

		if modData:
			var info = modData[0]
			var modPath = modData[1]

			print("Loading mod " + info.Data.ID)
			if validate_mod(modPath):
				var success = ProjectSettings.load_resource_pack(modPath, true)
				if success:
					print("Loaded mod " + info.Data.ID)
					Global.loadedMods.push_back(info.Data.ID)

					var scriptPath = info.get("Script")
					if scriptPath:
						if ResourceLoader.exists(scriptPath):
							var node = Node.new()
							node.name = info.Data.ID
							node.set_script(load(scriptPath))
							ModAPI.add_child.call_deferred(node, true)
							print("Ran " + scriptPath + " and created node for " + info.Data.ID)
						else:
							printerr("Script at " + scriptPath + " not found!")
				else:
					printerr("Assets for " + info.Data.ID + " failed to integrate!")


	for i in Global.enabledMods:
		if !loadedMods.has(i):
			enabledMods.erase(i)

	mods_loaded.emit()


func _unhandled_input(event):
	if event is InputEventJoypadButton:
		if inputType != INPUT.CONTROLLER:
			inputType = INPUT.CONTROLLER
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			controllerActive = true
			input_type_changed.emit()
	elif event is InputEventKey:
		if inputType != INPUT.KEYBOARD:
			inputType = INPUT.KEYBOARD
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			controllerActive = false
			input_type_changed.emit()


func save_user_settings():
	var file = FileAccess.open("user://userdata.dat", FileAccess.WRITE)

	var keybinds = {}

	for i in InputMap.get_actions():
		if !i.begins_with("ui_"):
			if InputMap.action_get_events(i).size() >= 1:
				keybinds.merge({i: InputMap.action_get_events(i)})

	if file != null:
		var userData = {
			"MasterVolume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")), 
			"MusicVolume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), 
			"SoundEffectsVolume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sound Effects")), 
			"Username": username, 
			"UIScale": get_window().content_scale_factor, 
			"GuideOpen": guideOpen, 
			"ShowFPS": showFPS, 
			"Language": TranslationServer.get_locale(), 
			"FontType": fontType, 
			"VSyncMode": vsyncMode, 
			"MaxFPS": Engine.max_fps, 
			"Screenshake": screenshake, 
			"Keybinds": keybinds, 
			"HideChat": hideChat, 
			"HidePlayerNames": hidePlayerNames, 
			"MusicDelay": musicDelay, 
			"HideRain": hideRain, 
			"HitFirst": hitFirst, 
			"Fullscreen": DisplayServer.window_get_mode(), 
			"Tutorial": tutorial, 
			"MinimapSize": minimapSize, 
			"MinimapTransparency": minimapTransparency, 
			"EnabledMods": enabledMods, 
			"ModWarningAcknowledged": modWarningAcknowledged, 
			"ShowUnderwaterEffect": showUnderwaterEffect, 
			"HealthTransparency": healthTransparency, 
			"SmoothMining": smoothMining, 
			"LastLoadedSave": lastLoadedSave, 
			"UnlockedSkins": unlockedSkins, 
			"ActiveSkinID": activeSkinID, 
		}

		file.store_var(userData, true)

	else:
		printerr("Error saving user data!")


var lastWindowType = DisplayServer.window_get_mode()

func window_change(mode):
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		lastWindowType = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if lastWindowType == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

	fullscreen_changed.emit(mode)


func load_user_settings():
	var file = FileAccess.open("user://userdata.dat", FileAccess.READ)

	if file != null:
		var userData = file.get_var(true)

		if userData:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), userData.get("MasterVolume", 0.0))
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), userData.get("MusicVolume", 0.0))
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound Effects"), userData.get("SoundEffectsVolume", 0.0))
			username = userData.get("Username", "Player")
			get_window().content_scale_factor = userData.get("UIScale", 1)
			guideOpen = userData.get("GuideOpen", true)
			showFPS = userData.get("ShowFPS", false)

			var language = userData.get("Language", "en")
			TranslationServer.set_locale(language)

			fontType = userData.get("FontType", 0)
			set_font(fontType)
			vsyncMode = userData.get("VSyncMode", 0)
			Engine.max_fps = userData.get("MaxFPS", 0)
			screenshake = userData.get("Screenshake", 1.0)
			hideChat = userData.get("HideChat", false)
			hidePlayerNames = userData.get("HidePlayerNames", false)
			hideRain = userData.get("HideRain", false)
			musicDelay = userData.get("MusicDelay", false)
			hitFirst = userData.get("HitFirst", false)
			tutorial = userData.get("Tutorial", true)
			minimapSize = userData.get("MinimapSize", 192)
			minimapTransparency = userData.get("minimapTransparency", 0.75)
			enabledMods = userData.get("EnabledMods", [])
			modWarningAcknowledged = userData.get("ModWarningAcknowledged", false)
			showUnderwaterEffect = userData.get("ShowUnderwaterEffect", true)
			healthTransparency = userData.get("HealthTransparency", 1.0)
			smoothMining = userData.get("SmoothMining", true)
			lastLoadedSave = userData.get("LastLoadedSave", {})
			unlockedSkins = userData.get("UnlockedSkins", [])
			activeSkinID = userData.get("ActiveSkinID", "starground:skin_default")

			var window = userData.get("Fullscreen", DisplayServer.WINDOW_MODE_WINDOWED)
			if window != DisplayServer.WINDOW_MODE_WINDOWED:
				window_change(window)

			var keybinds = userData.get("Keybinds", null)

			if keybinds:
				for i in keybinds:
					var event = keybinds.get(i)
					InputMap.action_erase_events(i)

					for j in event:
						InputMap.action_add_event(i, j)

			print("Loaded user data")
	else:
		var setLanguage = OS.get_locale_language()

		if TranslationServer.get_loaded_locales().has(setLanguage):
			TranslationServer.set_locale(setLanguage)

		printerr("Userdata not found!")


func set_font(type = 0):
	fontType = type
	if type == 0:
		ThemeDB.get_project_theme().default_font = load("res://Fonts/LycheeSoda.ttf")
		ThemeDB.get_project_theme().default_font_size = 16

		ThemeDB.get_project_theme().set_font_size("font_size", "HeaderLarge", 32)
		ThemeDB.get_project_theme().set_font_size("font_size", "HeaderMedium", 24)
	else:
		ThemeDB.get_project_theme().default_font = load("res://Fonts/NotoSans-SemiBold.ttf")
		ThemeDB.get_project_theme().default_font_size = 12

		ThemeDB.get_project_theme().set_font_size("font_size", "HeaderLarge", 24)
		ThemeDB.get_project_theme().set_font_size("font_size", "HeaderMedium", 18)


func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		mouseInWindow = true
	elif what == NOTIFICATION_WM_MOUSE_EXIT:
		mouseInWindow = false


func is_in_dungeon() -> bool:
	if currentRegion:
		return currentRegion.RegionType == ModAPI.REGION.DUNGEON
	return false

func is_in_automation() -> bool:
	if currentRegion:
		return currentRegion.RegionType == ModAPI.REGION.AUTOMATION
	return false

func is_in_space() -> bool:
	if currentRegion:
		return currentRegion.RegionType == ModAPI.REGION.SPACE
	return false


func _process(delta):
	if currentCloseMenuDelay > 0:
		currentCloseMenuDelay -= 1

	if controllerActive:
		if !get_viewport().gui_get_focus_owner():
			if virtualKeyboard.visible:
				var newFocus = virtualKeyboard.find_next_valid_focus()
				if !newFocus.is_in_group("NoAutofocus"):
					newFocus.grab_focus()
			else:
				for i in get_tree().get_nodes_in_group("CanvasFocus"):
					if i.visible:
						for j in i.get_children():
							if j is Control:
								var newFocus = j.find_next_valid_focus()
								if is_instance_valid(newFocus):
									if !(newFocus is RichTextLabel):
										if !newFocus.is_in_group("NoAutofocus"):
											newFocus.grab_focus()
		elif get_viewport().gui_get_focus_owner() is RichTextLabel:
			get_viewport().gui_get_focus_owner().release_focus()
	elif virtualKeyboard.visible:
		virtualKeyboard.close()

	if currentUserDataTimer <= 0:
		currentUserDataTimer = userDataTimer
		save_user_settings()
	else:
		currentUserDataTimer -= 1 * delta


func stop_ambience(newFadeTime = 2.0, force = false):
	ambiencePlayer.fadeTime = newFadeTime

	if force:
		ambiencePlayer.stop()
	else:
		ambiencePlayer.fade = true


func stop_music(newFadeTime = 1.0, force = false):
	only_stop_music(newFadeTime, force)
	stop_ambience(newFadeTime, force)
	set_music_override(null)


func only_stop_music(newFadeTime = 1.0, force = false):
	musicPlayer.fadeTime = newFadeTime
	if force:
		musicPlayer.stop()
	else:
		musicPlayer.fade = true


func set_music_override(track):
	musicPlayer.override = track


func get_preloaded_resource(filepath: String):
	var resource = cachedResources.get(filepath)
	if resource:
		return resource
	return null


func cache_resources():
	for i in cacheTable:
		var resource = ResourceLoader.load(i, "", ResourceLoader.CACHE_MODE_REUSE)
		cachedResources.merge({i: resource})


func _ready():
	set_process(false)
	OS.set_environment("SteamAppID", str(2793380))
	OS.set_environment("SteamGameID", str(2793380))
	var a = Steam.steamInitEx(false, 2793380, true)
	print(a)

	fully_loaded.connect(func(): fullyLoaded = true)

	if !DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_absolute("user://saves")

	if !DirAccess.dir_exists_absolute("user://mods"):
		DirAccess.make_dir_absolute("user://mods")

	if !DirAccess.dir_exists_absolute("user://screenshots"):
		DirAccess.make_dir_absolute("user://screenshots")

	load_user_settings()
	load_mods()

	await get_tree().process_frame


	var cache = load("res://Resources/caching_table.tres")
	cacheTable.append_array(cache.cacheTable)

	var loot = load("res://Resources/loot_table.tres")
	for i in loot.lootTable.keys():
		var lootArray = loot.lootTable.get(i)
		if lootTable.has(i):
			for j in lootArray:
				lootTable[i].push_back(j)
		else:
			lootTable.merge({i: lootArray})
	
	# Reorganization of categories and buildings
	buildingsTree.reorder_by_position()
	for i:String in buildingsTree.tree:
		buildingsTree.tree[i].reorder_by_position()

	var research = load("res://Resources/research_table.tres")
	researchTable.merge(research.researchTable)
	research.researchTable = researchTable
	research.build()

	var items = load("res://Resources/items_table.tres")
	itemsTable.merge(items.itemsTable)
	items.itemsTable = itemsTable
	items.build()

	var entities = load("res://Resources/entities_table.tres")
	entitiesTable.merge(entities.entitiesTable)
	entities.entitiesTable = entitiesTable
	entities.build()

	var regions = load("res://Resources/regions_table.tres")
	regionsTable.merge(regions.regionsTable)
	regions.regionsTable = regionsTable
	regions.build()

	for i in itemsTable.keys():
		var item = itemsTable.get(i)
		if item.get("Fuel"):
			fuelIDs.push_back(i)

	var recipe = load("res://Resources/recipe_table.tres")
	recipeTable.merge(recipe.recipeTable)

	var effects = load("res://Resources/effects_table.tres")
	effectsTable.merge(effects.effectsTable)

	var commands = load("res://Resources/commands_table.tres")
	commandsTable.merge(commands.commandsTable)

	var skins = load("res://Resources/skins_table.tres")
	skinsTable.merge(skins.skinsTable)

	var shop = load("res://Resources/shop_table.tres")
	shopTable.merge(shop.shopTable)

	var unlock = load("res://Resources/unlocks_table.tres")
	unlocksTable.merge(unlock.unlocksTable)

	var spawner = load("res://Resources/spawner_table.tres")
	spawnerTable.append_array(spawner.spawnerTable)
	uiSpawnerTable.append_array(spawner.uiSpawnerTable)

	var quest = load("res://Resources/quests_table.tres")
	questsTable.merge(quest.questsTable)

	cache_resources()

	musicPlayer = load("res://Scenes/music_player.tscn").instantiate()
	musicPlayer.volume_db = -59
	add_child(musicPlayer)

	ambiencePlayer = load("res://Scenes/music_player.tscn").instantiate()
	ambiencePlayer.type = 1
	ambiencePlayer.volume_db = -59
	add_child(ambiencePlayer)

	var canvasKeyboard = load("res://keyboard_canvas.tscn").instantiate()
	add_child(canvasKeyboard)
	virtualKeyboard = canvasKeyboard.get_node("VirtualKeyboard")











	for i in voices:
		voice_id = i

	print("Creating CreatedIn table....")
	var createdInTableTime = Time.get_ticks_msec()
	for i in itemsTable:
		var itemID = i
		var createdIn = []

		for buildingID in Global.recipeTable:
			var buildingRecipes = Global.recipeTable.get(buildingID)
			for recipeID in buildingRecipes:
				var recipeData = buildingRecipes.get(recipeID)
				if recipeData.Output is Dictionary:
					if recipeData.Output.ID == itemID:
						if !createdIn.has(buildingID):
							createdIn.push_back(buildingID)
				else: for j in recipeData.Output:
					if j.ID == itemID:
						if !createdIn.has(buildingID):
							createdIn.push_back(buildingID)

		createdInTable.get_or_add(itemID, createdIn)
	print("Done! - took " + str(Time.get_ticks_msec() - createdInTableTime) + "ms")

	await ModAPI.get_tree().process_frame

	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	set_process(true)


func convert_name(itemName):
	var newID = "starground:" + itemName.replace("starground:", "").to_lower().replace(" ", "_")
	if itemName != newID:
		return newID
	return itemName


var music = {
	"main_menu": [
		load("res://Sounds/Music/bedtime.ogg"), 
		load("res://Sounds/Music/dark_side_of_the_moon.ogg"), 
		load("res://Sounds/Music/grass_roots.ogg"), 
	], 

	"starground:region_veridian": [
		load("res://Sounds/Music/nice_day.ogg"), 
		load("res://Sounds/Music/new_life.ogg"), 
		load("res://Sounds/Music/twinkling_void.ogg"), 
		load("res://Sounds/Music/outside.ogg"), 
		load("res://Sounds/Music/beautiful_moment.ogg"), 
		load("res://Sounds/Music/research.ogg"), 
		load("res://Sounds/Music/blueprint.ogg"), 
		load("res://Sounds/Music/frontier.ogg")
	], 
	"starground:region_tyria": [
		load("res://Sounds/Music/signals_in_the_distance.ogg"), 
		load("res://Sounds/Music/crystal_ocean.ogg"), 
		load("res://Sounds/Music/cobalt.ogg"), 
		load("res://Sounds/Music/sedna's_gift.ogg"), 
		load("res://Sounds/Music/research.ogg"), 
	], 
	"starground:region_enceladus_0": [
		load("res://Sounds/Music/mold.ogg"), 
		load("res://Sounds/Music/symbiotic_machine.ogg"), 
		load("res://Sounds/Music/lair.ogg"), 
	], 
	"starground:region_enceladus_1": [
		load("res://Sounds/Music/yuck_puddle.ogg"), 
		load("res://Sounds/Music/temple_lab.ogg"), 
		load("res://Sounds/Music/deep_corruption.ogg"), 
	], 
	"starground:region_space_hub": [
		load("res://Sounds/Music/rewind.ogg"), 
		load("res://Sounds/Music/lounge.ogg"), 
		load("res://Sounds/Music/fountain_wishes.ogg"), 
		load("res://Sounds/Music/prep_time.ogg"), 
		load("res://Sounds/Music/browser.ogg"), 
	], 
}

var ambience = {
	"main_menu": [], 

	"starground:region_veridian": [
		load("res://Sounds/Sound Effects/nature_ambience.ogg"), 
	], 
	"starground:region_tyria": [
		load("res://Sounds/Sound Effects/ocean_ambience.ogg"), 
	], 
	"starground:region_enceladus_0": [
		load("res://Sounds/Sound Effects/dungeon_1_ambience.wav"), 
	], 

	"starground:region_enceladus_1": [
		load("res://Sounds/Sound Effects/dungeon_1_ambience.wav"), 
	], 

	"starground:region_space_hub": [
		{"Stream": load("res://Sounds/Sound Effects/space_hub_ambience.ogg"), "Volume": -18}, 
	]
}




var buildingsTabs = [
	["Production", load("res://Sprites/icon_production.png")], 
	["Logistics", load("res://Sprites/icon_production.png")], 
	["Power", load("res://Sprites/icon_production.png")], 
	["Miscellaneous", load("res://Sprites/icon_production.png")]
]


func set_active_skin(id: String) -> void :
	activeSkinID = id
	skin_changed.emit()


func get_input_icon_path(input: InputEvent):
	if input is InputEventKey:
		var keystring = ""

		if input.physical_keycode:
			keystring = OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(input.physical_keycode)).to_lower()
		else:
			keystring = OS.get_keycode_string(input.keycode).to_lower()

		if keystring == "slash":
			keystring = "slash_forward"

		var path = "res://Sprites/Input Prompts/Keyboard & Mouse/keyboard_" + keystring + ".png"

		if ResourceLoader.exists(path):
			return path
		return "res://Sprites/Input Prompts/Keyboard & Mouse/keyboard_question.png"

	elif input is InputEventMouse:
		return mouseButton[input.button_index]
	elif input is InputEventJoypadButton:
		if input.button_index < controllerButtons.size():
			return controllerButtons[input.button_index]

		return "Button " + str(input.button_index)
	elif input is InputEventJoypadMotion:
		if input.axis == 0:
			if input.axis_value < 0:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_l_left.png"
			else:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_l_right.png"

		if input.axis == 1:
			if input.axis_value < 0:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_l_up.png"
			else:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_l_down.png"

		if input.axis == 2:
			if input.axis_value < 0:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_r_left.png"
			else:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_r_right.png"

		if input.axis == 3:
			if input.axis_value < 0:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_r_up.png"
			else:
				return "res://Sprites/Input Prompts/Xbox Series/xbox_stick_r_down.png"

		return controllerMotion[input.axis]
	else:
		return "res://Sprites/Input Prompts/Keyboard & Mouse/keyboard_question.png"


func get_input_string(input: InputEvent):
	if input is InputEventKey:
		if input.physical_keycode:
			var keycode = OS.get_keycode_string(input.get_physical_keycode_with_modifiers())
			if keycode == "Slash":
				keycode = "/"
			return keycode

		return OS.get_keycode_string(input.keycode)
	elif input is InputEventJoypadButton:
		return controllerButtonString[input.button_index]
	elif input is InputEventJoypadMotion:
		if input.axis == 0:
			if input.axis_value < 0:
				return "LS LEFT"
			else:
				return "LS RIGHT"

		if input.axis == 1:
			if input.axis_value < 0:
				return "LS UP"
			else:
				return "LS DOWN"

		if input.axis == 2:
			if input.axis_value < 0:
				return "RS LEFT"
			else:
				return "RS RIGHT"

		if input.axis == 3:
			if input.axis_value < 0:
				return "RS UP"
			else:
				return "RS DOWN"

		return controllerMotionString[input.axis]
	elif input is InputEventMouse:
		return mouseButtonString[input.button_index]

	return ""


var controllerMotion = [
	"res://Sprites/Input Prompts/Xbox Series/xbox_ls.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_ls.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_rs.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_rs.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_lt.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_rt.png", 
]

var controllerMotionString = [
	"LS", 
	"LS", 
	"RS", 
	"RS", 
	"LT", 
	"RT", 
]

var controllerButtons = [
	"res://Sprites/Input Prompts/Xbox Series/xbox_button_color_a.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_button_color_b.png", 
	 "res://Sprites/Input Prompts/Xbox Series/xbox_button_color_x.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_button_color_y.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_button_back_icon.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_guide.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_button_start.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_ls.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_rs.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_lb.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_rb.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_dpad_up.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_dpad_down.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_dpad_left.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_dpad_right.png", 
	"res://Sprites/Input Prompts/Xbox Series/xbox_button_share.png", 
]

var controllerButtonString = [
	"A", 
	"B", 
	"X", 
	"Y", 
	"BACK", 
	"GUIDE", 
	"START", 
	"LS", 
	"RS", 
	"LB", 
	"RB", 
	"DPAD UP", 
	"DPAD DOWN", 
	"DPAD LEFT", 
	"DPAD RIGHT", 
	"SHARE", 
]

var mouseButton = [
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_left.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_right.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_scroll.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_scroll_up.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_scroll_down.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_scroll.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_scroll.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_horizontal.png", 
	"res://Sprites/Input Prompts/Keyboard & Mouse/mouse_horizontal.png", 
]

var mouseButtonString = [
	"Error", 
	"LMB", 
	"RMB", 
	"MMB", 
	"Scroll Up", 
	"Scroll Down", 
	"Mouse Wheel Left", 
	"Mouse Wheel Right", 
	"Mouse Left Side Button", 
	"Mouse Right Side Button"
]
