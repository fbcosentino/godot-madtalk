tool
extends Control
class_name DialogNodeItem_condition

signal remove_requested(requester)
signal move_up_requested(requester)
signal move_down_requested(requester)



export(Resource) var data


onready var popup_menu = get_node("PopupMenu")
enum PopupOptions {
	Edit,
	MoveUp,
	MoveDown,
	Remove
}
onready var dialog_edit = get_node("DialogEdit")
onready var edit_condition_type = get_node("DialogEdit/Panel/BtnConditionType")
onready var edit_specificlist = get_node("DialogEdit/Panel/SpecificFields")
onready var edit_btntip = get_node("DialogEdit/Panel/BtnTip")

# names of the nodes holding the controls in edit box
const edit_specificlist_items = [
	"Random",
	"VarBool",
	"VarAtLeast",
	"VarUnder",
	"VarString",
	"Time",
	"DayWeek",
	"DayMonth",
	"Date",
	"ElapsedVar",
	"Custom"
]

onready var condition_conditionlabel = get_node("ConditionLabel")

func _ready():
	for item in edit_specificlist.get_children():
		item.hide()
	if data:
		set_data(data)

func set_data(new_data):
	data = new_data
	update_from_data()
	
func update_from_data():
	if data:
		var mtdefs = MTDefs.new()
		condition_conditionlabel.text = mtdefs.Condition_PrintFail(data.condition_type, data.condition_values)
		#mtdefs.free()


func _on_DialogNodeItem_condition_gui_input(event):
	if (event is InputEventMouseButton) and (event.pressed) and (event.button_index == BUTTON_RIGHT):
		var position = get_viewport().get_mouse_position()
		popup_menu.popup(Rect2(position,Vector2(10,10)))

func _on_PopupMenu_id_pressed(id):
	match id:
		PopupOptions.Edit:
			edit_condition_type.selected = data.condition_type 
			var values_size = data.condition_values.size()
			# Nodes not commonly used so get_node is used directly for simplicity
			# (They are only used here and when saving)
			
			
			for j in range(edit_specificlist_items.size()):
				var num_args = MTDefs.ConditionData[j]["num_args"]
				var node_name = edit_specificlist_items[j]
			
				for i in range(num_args):
					var data_type = MTDefs.ConditionData[j]["data_types"][i]
					var print_type = MTDefs.ConditionData[j]["print_types"][i] if MTDefs.ConditionData[j]["print_types"].size() > i else TYPE_STRING
					var value = data.condition_values[i] if (values_size > i) else MTDefs.ConditionData[j]["default"][i]
					
					if print_type == MTDefs.TYPE_WEEKDAY:
						var node = get_node_or_null("DialogEdit/Panel/SpecificFields/%s/Option%d" % [node_name, i])
						if node:
							value = int(value)
							while value > 6:
								value -= 7
							while value < 0:
								value += 7
							node.select(int(value))
					elif print_type == MTDefs.TYPE_CHECK:
						var node = get_node_or_null("DialogEdit/Panel/SpecificFields/%s/Option%d" % [node_name, i])
						if node:
							value = float(value)
							if value != 0:
								node.select(0)
							else:
								node.select(1)
						
					elif print_type != null:
						var node = get_node_or_null("DialogEdit/Panel/SpecificFields/%s/EditValue%d" % [node_name, i])
						if node:
							node.text = str(value)

			update_DialogEdit_contents(data.condition_type)
			dialog_edit.popup_centered()

		PopupOptions.MoveUp:
			emit_signal("move_up_requested", self)

		PopupOptions.MoveDown:
			emit_signal("move_down_requested", self)

		PopupOptions.Remove:
			emit_signal("remove_requested", self)
			




func _on_DialogEdit_BtnConditionType_item_selected(index):
	update_DialogEdit_contents(edit_condition_type.selected)
	
func _on_DialogEdit_BtnCancel_pressed():
	dialog_edit.hide()


func _on_DialogEdit_BtnSave_pressed():
	data.condition_type = edit_condition_type.selected

	
	var num_args = MTDefs.ConditionData[data.condition_type]["num_args"]
	var node_name = edit_specificlist_items[data.condition_type]
	data.condition_values.resize(num_args)
	
	for i in range(num_args):
		var data_type = MTDefs.ConditionData[data.condition_type]["data_types"][i]
		var print_type = MTDefs.ConditionData[data.condition_type]["print_types"][i] if MTDefs.ConditionData[data.condition_type]["print_types"].size() > i else TYPE_STRING
		var value
		if print_type == MTDefs.TYPE_WEEKDAY:
			value = get_node("DialogEdit/Panel/SpecificFields/%s/Option%d" % [node_name, i]).selected
		elif print_type == MTDefs.TYPE_CHECK:
			value = 1 if get_node("DialogEdit/Panel/SpecificFields/%s/Option%d" % [node_name, i]).selected == 0 else 0
		else:
			value = get_node("DialogEdit/Panel/SpecificFields/%s/EditValue%d" % [node_name, i]).text

		# Data type is not the same as print type
		# data type is usually int, float or string, even if the print type is
		# something else such as checks or day of week 
		# (as those are stored as integers)
		match data_type:
			TYPE_INT:
				data.condition_values[i] = int(value)
			TYPE_REAL:
				data.condition_values[i] = float(value)
			TYPE_STRING:
				data.condition_values[i] = value
	
	update_from_data()
	dialog_edit.hide()


func update_DialogEdit_contents(condition):
	var fieldboxes = edit_specificlist.get_children()
	for i in range(fieldboxes.size()):
		if i == condition:
			fieldboxes[i].show()
		else:
			fieldboxes[i].hide()
	edit_btntip.tip_title = MTDefs.ConditionData[condition]["description"] #edit_condition_type.get_item_text(edit_condition_type.selected)
	edit_btntip.tip_text = MTDefs.ConditionData[condition]["help"]
