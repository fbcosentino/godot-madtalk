@tool
extends Window

signal saved(source_dialog)
signal tab_changed

const DEFAULT_TAB_TITLE = "Default"

var button_template = preload("res://addons/madtalk/components/DialogNodeOptionsButton.tscn")

@onready var buttonlist = get_node("Panel/ScrollContainer/VBox")

@onready var locale_bar := $Panel/LocaleBar
@onready var panel_new_locale := $Panel/PanelNewLocale
@onready var locale_edit := $Panel/PanelNewLocale/LocaleEdit

var data_resource # holds reference to the node data

# This is a Dictonary of Dictionaries
# btn_temporary_locales {
#     button_node: {
#         "": "default text",
#         "locale": "text",
#         ...
#     }
# }
var btn_temporary_locales: Dictionary = {}
var locale_list: Array = []

var current_locale := ""

var is_updating_tabs := false

func _ready() -> void:
	pass
	# Hides the close button
	#get_close_button().hide()

func open(data: DialogNodeData) -> void:
	is_updating_tabs = true
	
	data_resource = data
	btn_temporary_locales.clear()
	locale_list.clear()
	locale_list.append("")
	
	# Remove previous items
	var old_items = buttonlist.get_children()
	for item in old_items:
		buttonlist.remove_child(item)
		item.queue_free()
	
	# Add new items
	for item in data.options:
		add_item(item)
		for locale in item.text_locales:
			if not locale in locale_list:
				locale_list.append(locale)
	
	locale_bar.clear_tabs()
	locale_bar.add_tab(DEFAULT_TAB_TITLE)
	for tab_name in locale_list:
		if tab_name != "":
			locale_bar.add_tab(tab_name)
	locale_bar.current_tab = 0
	
	current_locale = ""
	
	is_updating_tabs = false
	
	popup_centered()



func add_item(item_data: DialogNodeOptionData) -> void:
	var new_btn = button_template.instantiate()
	new_btn.item_data = item_data # Should be used as read-only there
	buttonlist.add_child(new_btn)
	
	btn_temporary_locales[new_btn] = {
		"": item_data.text
	}
	for locale in item_data.text_locales:
		btn_temporary_locales[new_btn][locale] = item_data.text_locales[locale]
	
	new_btn.connected_id = item_data.connected_to_id
	new_btn.get_node("Panel/ButtonTextEdit").text = item_data.text
	new_btn.get_node("Condition").visible = item_data.is_conditional
	new_btn.update_condition_visible()
	if item_data.is_conditional:
		new_btn.get_node("Condition/VariableEdit").text = item_data.condition_variable
		new_btn.get_node("Condition/ValueEdit").text = item_data.condition_value
		new_btn.select_operator(item_data.condition_operator)
		new_btn.get_node("Condition/BtnOptionAutodisable").selected = int(item_data.autodisable_mode)
		new_btn.get_node("Condition/BtnOptionInactiveMode").selected = int(item_data.inactive_mode)
	else:
		new_btn.get_node("Condition/VariableEdit").text = ""
		new_btn.get_node("Condition/ValueEdit").text = ""
		new_btn.select_operator("=")
		new_btn.get_node("Condition/BtnOptionAutodisable").selected = 0
		new_btn.get_node("Condition/BtnOptionInactiveMode").selected = 0
		
	
	new_btn.get_node("Panel/BtnUp").connect("pressed", Callable(self, "_on_Button_BtnUp").bind(new_btn))
	new_btn.get_node("Panel/BtnDown").connect("pressed", Callable(self, "_on_Button_BtnDown").bind(new_btn))
	new_btn.get_node("Panel/BtnRemove").connect("pressed", Callable(self, "_on_Button_BtnRemove").bind(new_btn))


func load_items_from_locale(locale: String):
	var items = buttonlist.get_children()
	for btn_item in items:
		if btn_item in btn_temporary_locales:
			var locale_data = btn_temporary_locales[btn_item]
		
			if locale in locale_data:
				btn_item.get_node("Panel/ButtonTextEdit").text = locale_data[locale]
			else:
				btn_item.get_node("Panel/ButtonTextEdit").text = ""
		
		else:
			btn_item.get_node("Panel/ButtonTextEdit").text = ""


func store_items_into_locale(locale: String):
	var items = buttonlist.get_children()
	for btn_item in items:
		if not btn_item in btn_temporary_locales:
			btn_temporary_locales[btn_item] = {"":""}
		
		btn_temporary_locales[btn_item][locale] = btn_item.get_node("Panel/ButtonTextEdit").text


func get_used_locales() -> Array:
	# Operates on temporary storage
	var used_locales := [""] # default can never be erased
	var items = buttonlist.get_children()
	for btn_item in items:
		if btn_item in btn_temporary_locales:
			for locale in btn_temporary_locales[btn_item]:
				if btn_temporary_locales[btn_item][locale] != "":
					if not locale in used_locales:
						used_locales.append(locale)
	
	return used_locales


func save_button_locale_data():
	store_items_into_locale(current_locale)
	locale_list.clear()
	var used_locales: Array = get_used_locales()
	
	var items = buttonlist.get_children()
	for btn_item in items:
		if btn_item in btn_temporary_locales:
			btn_item.item_data.text = btn_temporary_locales[btn_item][""]
			var locale_dict := {}
			for locale in btn_temporary_locales[btn_item]:
				if locale in used_locales:
					locale_dict[locale] = btn_temporary_locales[btn_item][locale]
					if not locale in locale_list:
						locale_list.append(locale)
			btn_item.item_data.text_locales = locale_dict



func _on_BtnAdd_pressed() -> void:
	add_item(DialogNodeOptionData.new())


func _on_Button_BtnUp(button) -> void:
	var current_order = button.get_index()
	if current_order > 0:
		buttonlist.move_child(button, current_order-1)
	
func _on_Button_BtnDown(button) -> void:
	var current_order = button.get_index()
	buttonlist.move_child(button, current_order+1)

func _on_Button_BtnRemove(button) -> void:
	button.hide()
	button.queue_free()



func _on_BtnCancel_pressed() -> void:
	hide()
	queue_free()


func _on_BtnSave_pressed() -> void:
	save_button_locale_data() # Updates locale_list
	
	var new_items = buttonlist.get_children()
	
	# If we reduced the number of options, delete unused resources
	#if new_items.size() < data_resource.options.size():
		#data_resource.options.resize(new_items.size())
	#
	# # If we increased the number of options, create new resources
	#while new_items.size() > data_resource.options.size():
		#data_resource.options.append( DialogNodeOptionData.new() )
	
	data_resource.options = []
	
	# Set resource to new data
	for i in range(new_items.size()):
		var item: DialogNodeOptionData = new_items[i].item_data
		item.connected_to_id = new_items[i].connected_id
		item.is_conditional = new_items[i].get_node("Condition").visible
		if item.is_conditional:
			item.condition_variable = new_items[i].get_node("Condition/VariableEdit").text
			item.condition_operator = new_items[i].get_selected_operator()
			item.condition_value = new_items[i].get_node("Condition/ValueEdit").text
			item.autodisable_mode = new_items[i].get_node("Condition/BtnOptionAutodisable").selected
			item.inactive_mode = new_items[i].get_node("Condition/BtnOptionInactiveMode").selected
		else:
			item.condition_variable = ""
			item.condition_operator = "="
			item.condition_value = ""
			item.autodisable_mode = item.AutodisableModes.NEVER
			item.inactive_mode = item.InactiveMode.DISABLED
		
		data_resource.options.append(item)
		
	
	emit_signal("saved", self)
	hide()
	queue_free()


func _on_locale_bar_tab_changed(tab: int) -> void:
	if is_updating_tabs:
		return
	
	store_items_into_locale(current_locale)
	current_locale = locale_bar.get_tab_title(tab)
	if current_locale == DEFAULT_TAB_TITLE:
		current_locale = ""
	load_items_from_locale(current_locale)
	
	tab_changed.emit()


func _on_btn_locale_new_pressed() -> void:
	locale_edit.text = ""
	panel_new_locale.show()


func _on_btn_locale_new_cancel_pressed() -> void:
	panel_new_locale.hide()


func _on_btn_locale_new_confirm_pressed() -> void:
	var new_locale = locale_edit.text
	if not new_locale in locale_list:
		locale_list.append(new_locale)
		locale_bar.add_tab(new_locale)
	panel_new_locale.hide()
