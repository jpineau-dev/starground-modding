extends Button

@export var node: Control

func _ready():
	node.visibility_changed.connect(change_highlight)


func change_highlight():
	if node.visible:
		self_modulate = Color(1.5, 1.5, 1.5, 1)
	else:
		self_modulate = Color(1, 1, 1, 1)


func hide_tabs():
	var children = get_node("../../Tabs/Buttons/Grids/ScrollContainer").get_children()

	for child in children:
		child.visible = false

func _on_pressed():
	hide_tabs()
	node.visible = true


func _on_visibility_changed():
	if visible:
		if get_index() == 0:
			grab_focus()
