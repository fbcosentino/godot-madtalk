@tool
extends Control
class_name DialogNodeItem_option

@export var text: String = "": set = text_set

func text_set(value: String) -> void:
	text = value
	get_node("OptionLabel").text = value

func set_conditional(is_conditional: bool) -> void:
	get_node("Condition").visible = is_conditional
