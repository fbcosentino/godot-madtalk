tool
extends Control

var connected_id = -1

onready var cond_panel = get_node("Condition")
onready var cond_op_button = get_node("Condition/ButtonOperation")

func _ready():
	cond_panel.visible = false
	update_condition_visible()

func _on_BtnOptionCondition_pressed() -> void:
	cond_panel.visible = not cond_panel.visible
	update_condition_visible()
	
func update_condition_visible() -> void:
	rect_min_size.y = 64 if cond_panel.visible else 36
	rect_size.y = rect_min_size.y
	
func select_operator(op_text: String) -> void:
	for i in range(cond_op_button.get_item_count()):
		if cond_op_button.get_item_text(i) == op_text:
			cond_op_button.select(i)
			return
	cond_op_button.select(0)

func get_selected_operator() -> String:
	return cond_op_button.get_item_text(cond_op_button.selected)
