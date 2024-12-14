@tool
extends Control
class_name DialogNodeItem_effect

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

var edit_effect_type
var edit_specificlist
var edit_btntip

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

@onready var effect_effectlabel = get_node("EffectLabel")

var template_DialogEdit: PackedScene = preload("res://addons/madtalk/components/popups/Effect_DialogEdit.tscn")
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
		effect_effectlabel.text = mtdefs.Effect_PrintShort(data.effect_type, data.effect_values)
		#mtdefs.free()


func create_dialog_edit():
	if not dialog_edit:
		dialog_edit = template_DialogEdit.instantiate() as Window
		add_child(dialog_edit)
		dialog_edit.get_node("Panel/BtnEffectType").item_selected.connect(_on_DialogEdit_BtnEffectType_item_selected)
		dialog_edit.get_node("Panel/BottomBar/BtnSave").pressed.connect(_on_DialogEdit_BtnSave_pressed)
		dialog_edit.get_node("Panel/BottomBar/BtnCancel").pressed.connect(_on_DialogEdit_BtnCancel_pressed)
	
		edit_effect_type = dialog_edit.get_node("Panel/BtnEffectType")
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


func _on_DialogNodeItem_effect_gui_input(event):
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
			




func _on_DialogEdit_BtnEffectType_item_selected(index):
	update_DialogEdit_contents(edit_effect_type.selected)
	
func _on_DialogEdit_BtnCancel_pressed():
	dispose_dialog_edit()


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
			TYPE_FLOAT:
				data.effect_values[i] = float(value)
			TYPE_STRING:
				data.effect_values[i] = value
	
	update_from_data()
	dispose_dialog_edit()


func update_DialogEdit_contents(effect):
	var fieldboxes = edit_specificlist.get_children()
	for i in range(fieldboxes.size()):
		if i == effect:
			fieldboxes[i].show()
		else:
			fieldboxes[i].hide()
	edit_btntip.tip_title = MTDefs.EffectData[effect]["description"] 
	edit_btntip.tip_text = MTDefs.EffectData[effect]["help"]
