tool
extends Control
class_name DialogNodeItem_effect

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
onready var edit_effect_type = get_node("DialogEdit/Panel/BtnEffectType")
onready var edit_specificlist = get_node("DialogEdit/Panel/SpecificFields")
onready var edit_btntip = get_node("DialogEdit/Panel/BtnTip")

# names of the nodes holding the controls in edit box
const edit_specificlist_items = [
	"ChangeSheet",
	"SetVariable",
	"AddVariable",
	"RandomizeVariable",
	"StampTime",
	"SpendMinutes",
	"SpendDays",
	"SkipToTime",
	"SkipToWeekday",
	"WaitAnim",
	"Custom",
]

onready var effect_effectlabel = get_node("EffectLabel")

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
		effect_effectlabel.text = mtdefs.Effect_PrintShort(data.effect_type, data.effect_values)
		#mtdefs.free()


func _on_DialogNodeItem_effect_gui_input(event):
	if (event is InputEventMouseButton) and (event.pressed) and (event.button_index == BUTTON_RIGHT):
		var position = get_viewport().get_mouse_position()
		popup_menu.popup(Rect2(position,Vector2(10,10)))

func _on_PopupMenu_id_pressed(id):
	match id:
		PopupOptions.Edit:
			edit_effect_type.selected = data.effect_type 
			var values_size = data.effect_values.size()
			# Nodes not commonly used so get_node is used directly for simplicity
			# (They are only used here and when saving)


			for j in range(edit_specificlist_items.size()):
				var num_args = MTDefs.EffectData[j]["num_args"]
				var node_name = edit_specificlist_items[j]

				for i in range(num_args):
					var data_type = MTDefs.EffectData[j]["data_types"][i]
					var print_type = MTDefs.EffectData[j]["print_types"][i] if MTDefs.EffectData[j]["print_types"].size() > i else TYPE_STRING
					var value = data.effect_values[i] if (values_size > i) else MTDefs.EffectData[j]["default"][i]

					if print_type == MTDefs.TYPE_WEEKDAY:
						var node = get_node_or_null("DialogEdit/Panel/SpecificFields/%s/Option%d" % [node_name, i])
						if node:
							value = int(value)
							while value > 6:
								value -= 7
							while value < 0:
								value += 7
							node.select(int(value))
					elif print_type != null:
						var node = get_node_or_null("DialogEdit/Panel/SpecificFields/%s/EditValue%d" % [node_name, i])
						if node:
							node.text = str(value)
			
			update_DialogEdit_contents(data.effect_type)
			dialog_edit.popup_centered()

		PopupOptions.MoveUp:
			emit_signal("move_up_requested", self)

		PopupOptions.MoveDown:
			emit_signal("move_down_requested", self)

		PopupOptions.Remove:
			emit_signal("remove_requested", self)
			




func _on_DialogEdit_BtnConditionType_item_selected(index):
	update_DialogEdit_contents(edit_effect_type.selected)
	
func _on_DialogEdit_BtnCancel_pressed():
	dialog_edit.hide()


func _on_DialogEdit_BtnSave_pressed():
	data.effect_type = edit_effect_type.selected

	var num_args = MTDefs.EffectData[data.effect_type]["num_args"]
	var node_name = edit_specificlist_items[data.effect_type]
	data.effect_values.resize(num_args)

	for i in range(num_args):
		var data_type = MTDefs.EffectData[data.effect_type]["data_types"][i]
		var print_type = MTDefs.EffectData[data.effect_type]["print_types"][i] if MTDefs.EffectData[data.effect_type]["print_types"].size() > i else TYPE_STRING
		var value
		if print_type == MTDefs.TYPE_WEEKDAY:
			value = get_node("DialogEdit/Panel/SpecificFields/%s/Option%d" % [node_name, i]).selected
		else:
			value = get_node("DialogEdit/Panel/SpecificFields/%s/EditValue%d" % [node_name, i]).text

		match data_type:
			TYPE_INT:
				data.effect_values[i] = int(value)
			TYPE_REAL:
				data.effect_values[i] = float(value)
			TYPE_STRING:
				data.effect_values[i] = value
	
	update_from_data()
	dialog_edit.hide()


func update_DialogEdit_contents(effect):
	var fieldboxes = edit_specificlist.get_children()
	for i in range(fieldboxes.size()):
		if i == effect:
			fieldboxes[i].show()
		else:
			fieldboxes[i].hide()
	edit_btntip.tip_title = MTDefs.EffectData[effect]["description"] 
	edit_btntip.tip_text = MTDefs.EffectData[effect]["help"]





