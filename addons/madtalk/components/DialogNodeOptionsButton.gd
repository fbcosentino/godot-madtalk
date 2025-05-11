@tool
extends Control

const MIN_SIZE_CLOSED := 36
const MIN_SIZE_OPEN := 160

var connected_id = -1

var item_data = null # Reference, not a copy - DO NOT MODIFY IN THIS SCRIPT (use as if read-only)

@onready var cond_panel = $Condition
@onready var cond_op_button = $Condition/ButtonOperation
@onready var cond_auto_disable = $Condition/BtnOptionAutodisable
@onready var inactive_mode = $Condition/BtnOptionInactiveMode

func _ready():
	cond_panel.visible = false
	update_condition_visible()

func _on_BtnOptionCondition_pressed() -> void:
	cond_panel.visible = not cond_panel.visible
	update_condition_visible()
	
func update_condition_visible() -> void:
	custom_minimum_size.y = MIN_SIZE_OPEN if cond_panel.visible else MIN_SIZE_CLOSED
	size.y = custom_minimum_size.y
	
func select_operator(op_text: String) -> void:
	for i in range(cond_op_button.get_item_count()):
		if cond_op_button.get_item_text(i) == op_text:
			cond_op_button.select(i)
			return
	cond_op_button.select(0)

func get_selected_operator() -> String:
	return cond_op_button.get_item_text(cond_op_button.selected)
