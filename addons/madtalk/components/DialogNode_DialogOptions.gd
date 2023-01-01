tool
extends WindowDialog

signal saved(source_dialog)


var button_template = preload("res://addons/madtalk/components/DialogNodeOptionsButton.tscn")

onready var buttonlist = get_node("Panel/ScrollContainer/VBox")

var data_resource # holds reference to the node data

func _ready() -> void:
	# Hides the close button
	get_close_button().hide()

func open(data: DialogNodeData) -> void:
	data_resource = data
	# Remove previous items
	var old_items = buttonlist.get_children()
	for item in old_items:
		item.hide()
		item.queue_free()
	
	# Add new items
	for item in data.options:
		add_item(item)
		
	popup_centered()
	
	
func add_item(item_data) -> void:
	var new_btn = button_template.instance()
	buttonlist.add_child(new_btn)
	new_btn.connected_id = item_data.connected_to_id
	new_btn.get_node("Panel/ButtonTextEdit").text = item_data.text
	new_btn.get_node("Condition").visible = item_data.is_conditional
	new_btn.update_condition_visible()
	if item_data.is_conditional:
		new_btn.get_node("Condition/VariableEdit").text = item_data.condition_variable
		new_btn.get_node("Condition/ValueEdit").text = item_data.condition_value
		new_btn.select_operator(item_data.condition_operator)
	else:
		new_btn.get_node("Condition/VariableEdit").text = ""
		new_btn.get_node("Condition/ValueEdit").text = ""
		new_btn.select_operator("=")
		
	
	new_btn.get_node("Panel/BtnUp").connect("pressed", self, "_on_Button_BtnUp", [new_btn])
	new_btn.get_node("Panel/BtnDown").connect("pressed", self, "_on_Button_BtnDown", [new_btn])
	new_btn.get_node("Panel/BtnRemove").connect("pressed", self, "_on_Button_BtnRemove", [new_btn])

	


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
	var new_items = buttonlist.get_children()

	# If we reduced the number of options, delete unused resources
	if new_items.size() < data_resource.options.size():
		data_resource.options.resize(new_items.size())
		
	# If we increased the number of options, create new resources
	while new_items.size() > data_resource.options.size():
		data_resource.options.append( DialogNodeOptionData.new() )
	
	# Set resource to new data
	for i in range(new_items.size()):
		data_resource.options[i].text = new_items[i].get_node("Panel/ButtonTextEdit").text
		data_resource.options[i].connected_to_id = new_items[i].connected_id
		data_resource.options[i].is_conditional = new_items[i].get_node("Condition").visible
		if data_resource.options[i].is_conditional:
			data_resource.options[i].condition_variable = new_items[i].get_node("Condition/VariableEdit").text
			data_resource.options[i].condition_operator = new_items[i].get_selected_operator()
			data_resource.options[i].condition_value = new_items[i].get_node("Condition/ValueEdit").text
		else:
			data_resource.options[i].condition_variable = ""
			data_resource.options[i].condition_operator = "="
			data_resource.options[i].condition_value = ""
		
	
	emit_signal("saved", self)
	hide()
	queue_free()
