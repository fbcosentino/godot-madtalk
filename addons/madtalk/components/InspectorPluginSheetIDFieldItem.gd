extends EditorProperty
class_name InspectorPluginSheetIDFieldItem

signal sheet_selected(sheet_id)

var search_box_template = preload("res://addons/madtalk/components/DialogSearchSheet.tscn")
var search_item_template = preload("res://addons/madtalk/components/DialogSearchSheetItem.tscn")

var property_editor_object = preload("res://addons/madtalk/components/DialogSearchInspectorSheetIDField.tscn").instance()

var dialog_data : Resource = preload("res://madtalk/madtalk_data.tres")

var updating = false

func _init():
	add_child(property_editor_object)
	# To remember focus when selected back:
	add_focusable(property_editor_object.get_node("ValueLineEdit"))
	property_editor_object.get_node("ValueLineEdit").connect("text_changed", self, "_on_text_changed")
	property_editor_object.get_node("BtnSearch").connect("pressed", self, "_on_search_requested")


func _on_text_changed(text):
	if (updating):
		return
	emit_changed(get_edited_property(), text)
	
func update_property():
	var new_text = get_edited_object()[get_edited_property()]
	updating = true
	property_editor_object.get_node("ValueLineEdit").set_text(new_text)
	updating = false
	
func _on_search_requested():
	var text = get_edited_object()[get_edited_property()]
	var new_search_box = set_search_window(text)

	new_search_box.popup_centered()
	search(text, new_search_box)

	var result = yield(self, "sheet_selected")
	if result and (result is String):
		updating = true
		property_editor_object.get_node("ValueLineEdit").set_text(result)
		emit_changed(get_edited_property(), result)
		updating = false

func set_search_window(text):
	var new_search_box = search_box_template.instance()
	add_child(new_search_box)
	new_search_box.get_node("Panel/BottomBar/BtnCancel").connect("pressed", self, "_on_BtnCancel_pressed", [new_search_box])
	new_search_box.get_node("Panel/SearchEdit").connect("text_changed", self, "search", [new_search_box])

	new_search_box.get_node("Panel/SearchEdit").text = text
	
	return new_search_box



func add_item(sheet_id, window_object):
	if not sheet_id in dialog_data.sheets:
		return
	if not window_object:
		return
		
	var new_item = search_item_template.instance()
	window_object.get_node("Panel/SearchResultsPanel/Scroll/VBoxResults").add_child(new_item)
	
	new_item.get_node("SheetIDLabel").text = sheet_id
	new_item.get_node("DescLabel").text = dialog_data.sheets[sheet_id].sheet_description
	new_item.get_node("BtnPick").connect("pressed", self, "_on_SheetItem_pick", [sheet_id, window_object])


func _on_SheetItem_pick(sheet_id, window_object):
	if not window_object:
		return

	window_object.hide()
	emit_signal("sheet_selected", sheet_id)
	window_object.queue_free()
	
func _on_BtnCancel_pressed(window_object):
	if not window_object:
		return

	window_object.hide()
	emit_signal("sheet_selected", null)
	window_object.queue_free()

func search(search_term, window_object):
	var vbox_results = window_object.get_node("Panel/SearchResultsPanel/Scroll/VBoxResults")
	
	var old_items = vbox_results.get_children()
	for item in old_items:
		vbox_results.remove_child(item)
		item.queue_free()
		
	for this_sheet_id in dialog_data.sheets:
		var desc = dialog_data.sheets[this_sheet_id].sheet_description
		# If there is no search, or search shows up in eiter id or description:
		if (search_term == "") or (search_term.is_subsequence_ofi(this_sheet_id)) or (search_term.is_subsequence_ofi(desc)):
			add_item(this_sheet_id, window_object)
