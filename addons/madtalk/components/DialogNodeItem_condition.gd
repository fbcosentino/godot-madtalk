@tool
extends Control
class_name DialogNodeItem_condition

signal remove_requested(requester)
signal move_up_requested(requester)
signal move_down_requested(requester)
signal drag_started(requester)
signal drag_ended(requester)



@export var data: Resource


enum PopupOptions {
	Edit,
	MoveUp,
	MoveDown,
	Remove
}
#@onready var dialog_edit = get_node("DialogEdit")
var edit_condition_type
var edit_specificlist
var edit_btntip

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

@onready var condition_conditionlabel = get_node("ConditionLabel")

var template_DialogEdit: PackedScene = preload("res://addons/madtalk/components/popups/Condition_DialogEdit.tscn")
var dialog_edit: Window

var template_PopupMenu: PackedScene = preload("res://addons/madtalk/components/popups/DialogNodeItem_PopupMenu.tscn")
var popup_menu: PopupMenu

@onready var dragdrop_line := $DragDropLine

var sequence_node = null

func _ready():
	if data:
		set_data(data)

func set_data(new_data):
	data = new_data
	update_from_data()
	
func update_from_data():
	if data:
		var mtdefs = MTDefs.new()
		condition_conditionlabel.text = mtdefs.Condition_PrintFail(data.condition_type, data.condition_values)



func create_dialog_edit():
	if not dialog_edit:
		dialog_edit = template_DialogEdit.instantiate() as Window
		add_child(dialog_edit)
		dialog_edit.get_node("Panel/BtnConditionType").item_selected.connect(_on_DialogEdit_BtnConditionType_item_selected)
		dialog_edit.get_node("Panel/BottomBar/BtnSave").pressed.connect(_on_DialogEdit_BtnSave_pressed)
		dialog_edit.get_node("Panel/BottomBar/BtnCancel").pressed.connect(_on_DialogEdit_BtnCancel_pressed)
	
		edit_condition_type = dialog_edit.get_node("Panel/BtnConditionType")
		edit_specificlist = dialog_edit.get_node("Panel/SpecificFields")
		edit_btntip = dialog_edit.get_node("Panel/BtnTip")

		for item in edit_specificlist.get_children():
			item.hide()

func dispose_dialog_edit():
	if dialog_edit:
		dialog_edit.queue_free()
		dialog_edit = null


func create_popup_menu():
	if not popup_menu:
		popup_menu = template_PopupMenu.instantiate() as PopupMenu
		add_child(popup_menu)
		popup_menu.id_pressed.connect(_on_PopupMenu_id_pressed)

func dispose_popup_menu():
	if popup_menu:
		popup_menu.queue_free()
		popup_menu = null


func _on_DialogNodeItem_condition_gui_input(event):
	if (event is InputEventMouseButton):
		if (event.pressed):
			if (event.button_index == MOUSE_BUTTON_LEFT):
				if event.double_click:
					_on_PopupMenu_id_pressed(PopupOptions.Edit)
				else:
					drag_started.emit(self)
				
			if (event.button_index == MOUSE_BUTTON_RIGHT):
				var cursor_position =  get_viewport().get_mouse_position() if get_viewport().gui_embed_subwindows else DisplayServer.mouse_get_position()
				create_popup_menu()
				popup_menu.popup(Rect2(cursor_position,Vector2(10,10)))
		else:
			if (event.button_index == MOUSE_BUTTON_LEFT):
				drag_ended.emit(self)


func _on_PopupMenu_id_pressed(id):
	dispose_popup_menu()
	match id:
		PopupOptions.Edit:
			create_dialog_edit()
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
	dispose_dialog_edit()


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
			TYPE_FLOAT:
				data.condition_values[i] = float(value)
			TYPE_STRING:
				data.condition_values[i] = value
	
	update_from_data()
	dispose_dialog_edit()



func update_DialogEdit_contents(condition):
	var fieldboxes = edit_specificlist.get_children()
	for i in range(fieldboxes.size()):
		if i == condition:
			fieldboxes[i].show()
		else:
			fieldboxes[i].hide()
	edit_btntip.tip_title = MTDefs.ConditionData[condition]["description"] #edit_condition_type.get_item_text(edit_condition_type.selected)
	edit_btntip.tip_text = MTDefs.ConditionData[condition]["help"]
