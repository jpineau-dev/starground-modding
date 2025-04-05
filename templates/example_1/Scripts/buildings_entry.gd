extends Resource
class_name BuildingEntry

@export var position: int
@export var building: Dictionary

func _init(
	_position: int = 0,
	objectName: String = "Default building",
	description: String = "This is a default building",
	objectPath: String = "res://Scenes/sample.tscn",
	ingredients: Array[BuildingIngredient] = [],
	sprite: Resource = load("res://Sprites/furnace.png"),
	spriteArray: Array[Resource] = [], 
	spriteOffset: Vector2 = Vector2(0, 0),
	objectSize: Vector2 = Vector2(1, 1), 
	usesFuel: bool = false, 
	waterproof: bool = true, 
	powerStatus: int = 0, 
	canRotate: bool = false, 
	canPlaceLand: bool = true, 
	canPlaceWater: bool = false, 
	canPlaceShore: bool = false, 
	playerCollision: bool = true,  
	positionOffset: Vector2 = Vector2(0, 0), 
	bannedRegions: Array = [],
) -> void:
	position = _position
	
	building = {
		"ObjectName": objectName, 
		"Description": description, 
		"ObjectPath": objectPath, 
		"Ingredients": buildIngredientsArray(ingredients),
		"UsesFuel": usesFuel, 
		"CanPlaceLand": canPlaceLand, 
		"CanPlaceWater": canPlaceWater, 
		"CanPlaceShore": canPlaceShore, 
		"PowerStatus": powerStatus, 
		"PlayerCollision": playerCollision, 
		"Sprite": sprite, 
		"SpriteArray": spriteArray, 
		"SpriteOffset": spriteOffset, 
		"PositionOffset": positionOffset, 
		"ObjectSize": objectSize, 
		"CanRotate": canRotate, 
		"Waterproof": waterproof, 
		"BannedRegions": bannedRegions,
	}


func buildIngredientsArray(ingredients: Array[BuildingIngredient]) -> Array[Dictionary]:
	var ingredientsArray: Array[Dictionary] = []
	
	for ingredient in ingredients:
		ingredientsArray.append({
			"ID": ingredient.id,
			"Amount": ingredient.amount
		})
	
	return ingredientsArray
