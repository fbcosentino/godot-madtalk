tool
extends Control

export(Resource) var dialog_data = preload("res://madtalk/madtalk_data.tres")
var current_sheet = null

# Scene templates
var DialogNode_template = preload("res://addons/madtalk/components/DialogNode.tscn")
var SideBar_SheetItem_template = preload("res://addons/madtalk/components/SideBar_SheetItem.tscn")

# Scene nodes
onready var graph_area = get_node("GraphArea")


onready var sidebar_sheetlist = get_node("SideBar/Content/SheetsScroll/VBox")
onready var sidebar_current_panel = get_node("SideBar/Content/CurrentPanel")
onready var SideBar_sheet_id = get_node("SideBar/Content/CurrentPanel/SheetIDLabel")
onready var SideBar_sheet_desc = get_node("SideBar/Content/CurrentPanel/DescEdit")
onready var SideBar_search = get_node("SideBar/Content/SearchEdit")

onready var graph_area_popup = get_node("PopupMenu")

onready var popup_delete_node = get_node("DialogDeleteNodePopup")

onready var dialog_sheet_edit = get_node("DialogSheetEdit")
onready var dialog_sheet_rename_error_popup = get_node("DialogSheetRenameError")
onready var dialog_sheet_create_popup = get_node("DialogSheetCreated")

# Maps sequence ids to graph nodes
var sequence_map: Dictionary = {}

# Holds the node being deleted when user presses X
var deleting_node = null


func _ready() -> void:
	
	#current_sheet = dialog_data.sheets[0]
	open_sheet("first_sheet")
	
# Opens a sheet for the first time, or reopens (updates area content)
func open_sheet(sheet_id: String) -> void:
	# FAILSAFE: We ignore this call if the sheet id is invalid
	if not sheet_id in dialog_data.sheets:
		print("Invalid sheet id \"%s\"" % sheet_id)
		return
		
	# Clear all current content in the graph area
	for dialog_node in graph_area.get_children():
		if dialog_node is DialogGraphNode:
			graph_area.remove_child(dialog_node)
			dialog_node.queue_free()
			
	sequence_map.clear()
	
	# Prepare new sheet
	current_sheet = sheet_id
	var sheet_data = dialog_data.sheets[sheet_id]
	
	# First we build all nodes *without* updating them
	for node_data in sheet_data.nodes:
		var new_node = create_node_instance(node_data, false)
		sequence_map[node_data.sequence_id] = new_node
	
	# After we have all node instances available for connections,
	# we update them 
	for sequence_id in sequence_map:
		sequence_map[sequence_id].update_from_data()
			
	update_sidebar()
	rebuild_connections()
	

# Creates the visual representation of a node
# Does not modify the data structure
func create_node_instance(node_data: Resource, update_now: bool = true) -> DialogGraphNode:
	var new_node = DialogNode_template.instance()
	new_node.name = "DialogNode_ID%d" % node_data.sequence_id
	graph_area.add_child(new_node)
	new_node.offset = node_data.position
	new_node.connect("connections_changed", self, "_on_node_connections_changed")
	new_node.connect("close_request", self, "_on_node_close_request", [new_node])
	new_node.data = node_data # Assign the reference, not a copy
							  # Any changes to this node will reflect back in
							  # the main Resource
	new_node.show_close = (node_data.sequence_id != 0)
	
	# During sheet building not all nodes are ready so updating connections
	# will fail. In such a case we skip this task and update all nodes at once
	# later
	if (update_now):
		new_node.update_from_data()
	
	return new_node
	
# Creates a new node, optionally creating the visual GraphNode
func create_new_node(graph_position: Vector2 = Vector2(0,0), create_visual_instance = false) -> DialogNodeData:
	if not current_sheet:
		return null
		
	var sheet_data = dialog_data.sheets[current_sheet]
	
	# Find next available sequence id
	var next_available_id = sheet_data.next_sequence_id
	for this_node in sheet_data.nodes:
		if this_node.sequence_id >= next_available_id:
			next_available_id = this_node.sequence_id+1

	var new_data = DialogNodeData.new()
	new_data.position = graph_position
	new_data.sequence_id = next_available_id
	new_data.items = [] # New Array to avoid sharing references
	new_data.options = [] # New Array to avoid sharing references
	
	sheet_data.nodes.append(new_data)
	sheet_data.next_sequence_id = next_available_id+1
	
	# create_visual_instance is true when the node is created from user
	# interaction ("New sequence" button). It is false when the data is being
	# created procedurally and instances will be created later by open_sheet()
	#     DEPRECATED: now all methods call here with create_visual_instance=false
	#     and call open_sheet() afterwards
	if create_visual_instance:
		create_node_instance(new_data, true)
		rebuild_connections() # Should not be needed but reduntant calls are harmless
	
	return new_data

# Creates a new sheet, set as current, and returns the name of the sheet
func create_new_sheet() -> String:
	# Find a suitable available name
	var sheet_num = 1
	var new_sheet_name = "new_sheet_1"
	while new_sheet_name in dialog_data.sheets:
		sheet_num += 1
		new_sheet_name = "new_sheet_%d" % sheet_num
		
	# Create the new sheet
	var new_sheet_data = DialogSheetData.new() # default next_sequence_id=0
	new_sheet_data.sheet_id = new_sheet_name
	new_sheet_data.nodes = [] # Forces a new array to avoid reference sharing
	dialog_data.sheets[new_sheet_name] = new_sheet_data
	current_sheet = new_sheet_name
	
	# All sheets need at least one node with ID=0
	# Create a node data item without creating the GraphNode instance, as
	# it will be created later by open_sheet()
	create_new_node(Vector2(0,0), false)
	
	# Update sidebar and open sheet
	update_sidebar()
	open_sheet(new_sheet_name)
	#rebuild_connections()
	
	return new_sheet_name
	

# Connections are not build directly from UI
# Instead they are rebuilt from the Resource data objects every time
# This is the safest way to make sure there is never any difference between
# the visual representation and the underlying data
func rebuild_connections() -> void:
	
	graph_area.clear_connections()
	
	for sequence_id in sequence_map:
		var dialog_node = sequence_map[sequence_id]
			
			
		var sequence_data = dialog_node.data
		
		# For each item in this sequence
		for item_data in sequence_data.items:
			# Do we have a connection?
			if (item_data.connected_to_id > -1) and (item_data.port_index > -1):
				var target_node = get_dialognode_by_id(item_data.connected_to_id)
				if target_node:
					graph_area.connect_node(dialog_node.name, item_data.port_index, target_node.name, 0)
					
		# For each option in this sequence
		for opt_data in sequence_data.options:
			# Do we have a connection?
			if (opt_data.connected_to_id > -1) and (opt_data.port_index > -1):
				var target_node = get_dialognode_by_id(opt_data.connected_to_id)
				if target_node:
					graph_area.connect_node(dialog_node.name, opt_data.port_index, target_node.name, 0)
		
		# If we have a continue option at the end
		if sequence_data.continue_sequence_id > -1:
			var target_node = get_dialognode_by_id(sequence_data.continue_sequence_id)
			if target_node:
				graph_area.connect_node(dialog_node.name, sequence_data.continue_port_index, target_node.name, 0)
		

	

# Given a sequence id, returns the corresponding GraphNode object
func get_dialognode_by_id(id: int) -> DialogGraphNode:
	if not id in sequence_map:
		print("Error: node ID %s not found in sequence map" % id)
		return null
		
	return sequence_map[id]
	
func update_sidebar():
	# === Update current sheet
	if current_sheet:
		var sheet_data = dialog_data.sheets[current_sheet]
		SideBar_sheet_id.text = sheet_data.sheet_id
		SideBar_sheet_desc.text = sheet_data.sheet_description
		sidebar_current_panel.show()
		
	else:
		sidebar_current_panel.hide()
	
	# === Update list
	
	# Remove old items
	for old_item in sidebar_sheetlist.get_children():
		sidebar_sheetlist.remove_child(old_item)
		old_item.queue_free()
	
	# Add new items
	var search_term = SideBar_search.text
	for this_sheet_id in dialog_data.sheets:
		var new_item_data = dialog_data.sheets[this_sheet_id]
		# If there is no search, or search shows up in eiter id or description:
		if (search_term == "") or (search_term.is_subsequence_ofi(this_sheet_id)) or (search_term.is_subsequence_ofi(new_item_data.sheet_description)):
			var new_item = SideBar_SheetItem_template.instance()
			sidebar_sheetlist.add_child(new_item)
			new_item.get_node("Panel/SheetLabel").text = new_item_data.sheet_id
			new_item.get_node("Panel/DescriptionLabel").text = new_item_data.sheet_description
			new_item.get_node("Panel/BtnOpen").connect("pressed", self, "_on_SideBar_Item_open", [new_item_data.sheet_id])
	
	
func save_external_data():
	var res_path = dialog_data.resource_path
	ResourceSaver.save(res_path, dialog_data, 0)

# ==============================================================================
# UI CALLBACKS


## Distributes the input event to the appropriate method
func _on_GraphEdit_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton) and (event.pressed):
		match event.button_index:
			BUTTON_LEFT:
				_on_GraphEdit_left_click(event)
				
			BUTTON_RIGHT:
				_on_GraphEdit_right_click(event)

## Handles left clicks
func _on_GraphEdit_left_click(event: InputEvent) -> void:
	# event.position is screen coordinate, not taking scroll into account
	# graph_position is in node local coordinates
	var graph_position = event.position + graph_area.scroll_offset
	
	#print("LEFT CLICK: " + str(graph_position))
	#print(graph_area.scroll_offset)

## Handles right clicks
func _on_GraphEdit_right_click(event: InputEvent) -> void:
	# event.position is screen coordinate, not taking scroll into account
	# graph_position is in node local coordinates
	var graph_position = event.position + graph_area.scroll_offset

	graph_area_popup.popup(Rect2(event.position + graph_area.rect_global_position, Vector2(10,10)))


func _on_GraphArea_connection_request(from, from_slot, to, to_slot):
	# Get the required data
	var from_node = graph_area.get_node(from)
	var from_data = from_node.get_data_by_port(from_slot)
	var to_node = graph_area.get_node(to)
	# to_slot is always 0 in this application
	var to_sequence_id = to_node.data.sequence_id
	
	# Make the connection in the underlying data resources
	if from_data is DialogNodeData:
		# This is a simple continue
		from_data.continue_sequence_id = to_sequence_id
	
	else:
		# This is a branching
		from_data.connected_to_id = to_sequence_id
	
	rebuild_connections()


func _on_GraphArea_disconnection_request(from, from_slot, to, to_slot):
	# Get the required data
	var from_node = graph_area.get_node(from)
	var from_data = from_node.get_data_by_port(from_slot)
	
	# Make the connection in the underlying data resources
	if from_data is DialogNodeData:
		# This is a simple continue
		from_data.continue_sequence_id = -1
	
	else:
		# This is a branching
		from_data.connected_to_id = -1
	
	rebuild_connections()


func _on_node_connections_changed() -> void:
	rebuild_connections()

func _on_node_close_request(node_object) -> void:
	deleting_node = node_object
	popup_delete_node.popup_centered()
	

func _on_SideBar_SearchEdit_text_changed(new_text) -> void:
	update_sidebar()


func _on_GraphArea_PopupMenu_id_pressed(id) -> void:
	match id:
		0:
			# Create new node
			
			# graph_area_popup.rect_position is screen coordinate, not taking scroll into account
			# graph_position is in node local coordinates
			var graph_position = graph_area_popup.rect_position + graph_area.scroll_offset

			create_new_node(graph_position - Vector2(100,10), false)
			open_sheet(current_sheet)


func _on_DialogDeleteNodePopup_confirmed() -> void:
	if (not current_sheet) or (not deleting_node):
		return
	
	var sheet_data = dialog_data.sheets[current_sheet]
	var node_data = deleting_node.data
	
	sheet_data.nodes.erase(node_data)
	
	# Reopens the sheet to update area
	open_sheet(current_sheet)


func _on_BtnEditSheet_pressed() -> void:
	if not current_sheet:
		return
		
	var sheet_data = dialog_data.sheets[current_sheet]
	dialog_sheet_edit.open(sheet_data)
	
func _on_DialogSheetEdit_sheet_saved(sheet_id, sheet_desc, delete_word) -> void:
	if not current_sheet:
		return

	# Is the user requesting to delete the sheet?
	if delete_word == "delete":
		dialog_data.sheets[current_sheet].nodes = [] # Discards references to node data
		dialog_data.sheets[current_sheet] = null
		dialog_data.sheets.erase(current_sheet)
		
		# If this was the last sheet, we create a new one
		if dialog_data.sheets.size() == 0:
			# This method creates a new sheet, sets as current and returns the 
			# new sheet name
			var _new_sheet = create_new_sheet()

		# Otherwise select some other sheet
		else:
			current_sheet = dialog_data.sheets.keys()[0]
			open_sheet(current_sheet)
		
		# Hide the window
		dialog_sheet_edit.hide()
		
		update_sidebar()
		# Stop here since the old sheet is no longer valid
		return

	# Otherwise the user is editting the sheet
	
	var sheet_data = dialog_data.sheets[current_sheet]

	# Check if the sheet is being renamed and if the name does not collide
	if sheet_id != sheet_data.sheet_id:
		# User wants to rename
		# Check if this id is invalid or being used
		if (sheet_id == "") or (sheet_id in dialog_data.sheets):
			# Show an error message instead
			dialog_sheet_rename_error_popup.popup_centered()
			# Stop here and don't make any changes
			return
			
		else:
			# Rename the sheet
			dialog_data.sheets.erase(current_sheet)
			sheet_data.sheet_id = sheet_id
			dialog_data.sheets[sheet_id] = sheet_data
			current_sheet = sheet_id
	
	# Change description
	sheet_data.sheet_description = sheet_desc
	
	# Editting sheet details (ID, description) does not change node content
	# so calling open_sheet() is not required
	
	# Update current sheet panel and listing
	update_sidebar()
	# Hide window
	dialog_sheet_edit.hide()
	
	#var mtdefs = MTDefs.new()
	#mtdefs.debug_resource(dialog_data)

func _on_SideBar_Item_open(sheet_id) -> void:
	open_sheet(sheet_id)

func _on_BtnNewSheet_pressed() -> void:
	create_new_sheet()
	
	# Open sheet edit window
	_on_BtnEditSheet_pressed()
	
	# Inform user about successful sheet creation and edit window
	dialog_sheet_create_popup.popup_centered()


func _on_BtnSaveDB_pressed():
	var res_path = dialog_data.resource_path
	ResourceSaver.save(res_path, dialog_data, 0)




