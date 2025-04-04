func _init() -> void:
	var newBuilding: BuildingEntry = BuildingEntry.new(
		"Funny Building",
		"A kneeslapper of a mod building!",
		"res://Scenes/funny_building.tscn",
		[
			BuildingIngredient.new("starground:stone", 1),
		],
		load("res://Sprites/mod_building_example.png"),
		[],
		Vector2(0, 0),
		Vector2(1,1),
	)
	
	ModAPI.add_building_entry("Power", "bbg_templatemod:building_funny", newBuilding)
	ModAPI.add_spawner_entry("res://Scenes/funny_building.tscn")
