extends Resource
class_name BuildingIngredient

@export var id: String
@export var amount: int

func _init(_id: String, _amount: int) -> void:
	id = _id
	amount = _amount
