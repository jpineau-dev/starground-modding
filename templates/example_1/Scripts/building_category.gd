extends Resource
class_name BuildingCategory

@export var position: int
@export var icon: Resource
@export var buildings: Dictionary[String, BuildingEntry] = {}

func _init(_position: int = 0, _icon: Resource = null, _buildings: Dictionary[String, BuildingEntry] = {}) -> void:
	position = _position
	buildings = _buildings
	
	icon = _icon if _icon != null else load("res://Sprites/icon_info.png")

	if _buildings is Dictionary[String, BuildingEntry]:
		buildings = _buildings
	else:
		push_error("Wrong _buildings type!")


func reorder_by_position() -> void:
	var buildings_array = buildings.keys().map(func(key): return [key, buildings[key]])

	buildings_array.sort_custom(func(a, b): return a[1].position < b[1].position)

	var ordered_dict: Dictionary[String, BuildingEntry] = {}
	for item in buildings_array:
		ordered_dict.set(item[0], item[1])
	
	buildings = ordered_dict
