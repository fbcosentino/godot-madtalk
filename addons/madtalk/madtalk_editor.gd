@tool
extends Control

@export var dialog_data: Resource = preload("res://addons/madtalk/runtime/madtalk_data.tres")
var current_sheet = null

# Scene templates
var DialogNode_template = preload("res://addons/madtalk/components/DialogNode.tscn")
var SideBar_SheetItem_template = preload("res://addons/madtalk/components/SideBar_SheetItem.tscn")

# Scene nodes
@onready var graph_area = get_node("GraphArea")


@onready var sidebar_sheetlist = get_node("SideBar/Content/SheetsScroll/VBox")
@onready var sidebar_current_panel = get_node("SideBar/Content/CurrentPanel")
@onready var SideBar_sheet_id = get_node("SideBar/Content/CurrentPanel/SheetIDLabel")
@onready var SideBar_sheet_desc = get_node("SideBar/Content/CurrentPanel/DescEdit")
@onready var SideBar_search = get_node("SideBar/Content/SearchEdit")

@onready var graph_area_popup = get_node("PopupMenu")

@onready var popup_delete_node = get_node("DialogDeleteNodePopup")

@onready var dialog_sheet_edit = get_node("DialogSheetEdit")
@onready var dialog_sheet_rename_error_popup = get_node("DialogSheetRenameError")
@onready var dialog_sheet_create_popup = get_node("DialogSheetCreated")
@onready var dialog_export = get_node("DialogExport")
@onready var dialog_import = get_node("DialogImport")

# Maps sequence ids to graph nodes
var sequence_map: Dictionary = {}

# Holds the node being deleted when user presses X
var deleting_node = null

# Holds the item object being dragged
var dragging_object = null
var hovering_object = null


func _ready() -> void:
	pass
	call_deferred("setup")

func setup():
	if dialog_data.sheets.size() == 0:
		create_new_sheet()
	
	else:
		open_sheet(dialog_data.sheets.keys()[0])
	
	dialog_export.setup(dialog_data, current_sheet)
	dialog_import.setup(dialog_data, current_sheet)
	
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
			
	graph_area.scroll_offset.y -= 1
	update_sidebar()
	rebuild_connections()
	
	await get_tree().process_frame
	graph_area.scroll_offset.y += 1
	graph_area.queue_redraw()

func reopen_current_sheet():
	open_sheet(current_sheet)

# Creates the visual representation of a node
# Does not modify the data structure
func create_node_instance(node_data: Resource, update_now: bool = true) -> DialogGraphNode:
	var new_node: GraphNode = DialogNode_template.instantiate()
	new_node.name = "DialogNode_ID%d" % node_data.sequence_id
	new_node.main_editor = self
	graph_area.add_child(new_node)
	new_node.position_offset = node_data.position
	new_node.connections_changed.connect(_on_node_connections_changed)
	new_node.mouse_entered.connect(_on_sequence_mouse_entered.bind(new_node))
	new_node.mouse_exited.connect(_on_sequence_mouse_exited.bind(new_node))
	#new_node.connect("close_request", Callable(self, "_on_node_close_request").bind(new_node))
	new_node.data = node_data 	# Assign the reference, not a copy
								# Any changes to this node will reflect back in
								# the main Resource
	#new_node.show_close = (node_data.sequence_id != 0)
	if (node_data.sequence_id != 0):
		var new_close_btn = Button.new()
		new_close_btn.text = " X "
		new_close_btn.focus_mode = Control.FOCUS_NONE
		new_node.get_titlebar_hbox().add_child(new_close_btn)
		new_close_btn.pressed.connect(_on_node_close_request.bind(new_node))
	
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
	new_data.resource_scene_unique_id = Resource.generate_scene_unique_id()
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
	new_sheet_data.resource_scene_unique_id = Resource.generate_scene_unique_id()
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
		# If there is no search, or search shows up in either id or description:
		if (search_term == "") or (search_term in this_sheet_id) or (search_term in new_item_data.sheet_description):
			var new_item = SideBar_SheetItem_template.instantiate()
			sidebar_sheetlist.add_child(new_item)
			new_item.get_node("Panel/SheetLabel").text = new_item_data.sheet_id
			new_item.get_node("Panel/DescriptionLabel").text = new_item_data.sheet_description
			new_item.get_node("Panel/BtnOpen").connect("pressed", Callable(self, "_on_SideBar_Item_open").bind(new_item_data.sheet_id))
	
	
func _save_external_data():
	var res_path = dialog_data.resource_path
	ResourceSaver.save(dialog_data, res_path, 0)

# ==============================================================================
# UI CALLBACKS


## Distributes the input event to the appropriate method
func _on_GraphEdit_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton) and (event.pressed):
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_on_GraphEdit_left_click(event)
				
			MOUSE_BUTTON_RIGHT:
				_on_GraphEdit_right_click(event)
	#if (event is InputEventMouseMotion):
	#	print( (graph_area.get_local_mouse_position() + graph_area.scroll_offset)/graph_area.zoom )


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

	var cursor_position =  Vector2(get_viewport().get_mouse_position() if get_viewport().gui_embed_subwindows else DisplayServer.mouse_get_position())
	graph_area_popup.popup(Rect2(cursor_position, Vector2(10,10)))


# When a node item (message, condition, effect) is mouse-hovered
# Also happens if dragging started on another object
func _on_item_mouse_entered(obj: Control) -> void:
	hovering_object = obj
	if (dragging_object != null) and (dragging_object != obj):
		obj.modulate.a = 0.7
		obj.dragdrop_line.show()

# When a node item (message, condition, effect) loses mouse hover
# Also happens if dragging started on another object
func _on_item_mouse_exited(obj: Control) -> void:
	if hovering_object == obj:
		hovering_object = null
	if dragging_object != null:
		obj.modulate.a = 1.0
		obj.dragdrop_line.hide()


func _on_sequence_mouse_entered(obj: Control):
	hovering_object = obj
	if dragging_object != null:
		obj.modulate.a = 0.7

func _on_sequence_mouse_exited(obj: Control):
	if hovering_object == obj:
		hovering_object = null
	if dragging_object != null:
		obj.modulate.a = 1.0


# When the mouse is pressed down on a node item, which counts as 
# start dragging it.
func _on_item_drag_started(obj: Control) -> void:
	dragging_object = obj


# When the mouse is released after dragging an item. The obj argument
# contains the object being dragged, not the one under the cursor
func _on_item_drag_ended(obj: Control) -> void:
	if (dragging_object != hovering_object):
		move_item_by_instance(dragging_object, hovering_object)
		
	if hovering_object and is_instance_valid(hovering_object):
		hovering_object.modulate.a = 1.0
		if not hovering_object is DialogGraphNode:
			hovering_object.dragdrop_line.hide()
	
	hovering_object = null
	dragging_object = null


func move_item_by_instance(source_inst: Control, dest_inst):
	if (not source_inst) or (not is_instance_valid(source_inst)):
		return
	if (not dest_inst) or (not is_instance_valid(dest_inst)):
		return
	
	var source_seq = source_inst.sequence_node
	var data_seq_origin = source_seq.data
	var source_index = data_seq_origin.items.find(source_inst.data)
	var source_item_data = data_seq_origin.items[source_index]
	
	var dest_seq
	var data_seq_dest
	var dest_index

	if dest_inst is DialogGraphNode:
		# Dragging onto a sequence header
		dest_seq = dest_inst
		data_seq_dest = dest_seq.data
		dest_index = data_seq_dest.items.size()
	
	else:
		# Dragging onto another item
		dest_seq = dest_inst.sequence_node
		data_seq_dest = dest_seq.data
		dest_index = data_seq_dest.items.find(dest_inst.data)
	
	# There are special cases if the node is being reordered inside the same sequence
	if (data_seq_origin == data_seq_dest):
		if (dest_index == (source_index+1)):
			# If the user dropped on the item immediately below, no operation is needed
			return
		
		elif (dest_index > source_index):
			# If item is being moved below, removing it first will shift indices
			# below that point, causing the reinsert to have an unintended
			# extra offset of 1. So counteract is needed
			dest_index -= 1
	
	data_seq_origin.items.remove_at(source_index)
	data_seq_dest.items.insert(dest_index, source_item_data)
	
	source_seq.update_from_data()
	dest_seq.update_from_data()
	
	await get_tree().create_timer(0.02).timeout
	call_deferred("rebuild_connections")



func _on_GraphArea_connection_request(from, from_slot, to, to_slot):
	# Get the required data
	var from_node = graph_area.get_node(NodePath(from))
	var from_data = from_node.get_data_by_port(from_slot)
	var to_node = graph_area.get_node(NodePath(to))
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
	var from_node = graph_area.get_node(NodePath(from))
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
			#var cursor_position =  Vector2(graph_area_popup.position)
			#var graph_position = Vector2(cursor_position) + Vector2(graph_area.scroll_offset)
			#var graph_position = Vector2(graph_area_popup.position) + Vector2(graph_area.scroll_offset)
			var graph_position = Vector2((graph_area.get_local_mouse_position() + graph_area.scroll_offset)/graph_area.zoom)

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
	ResourceSaver.save(dialog_data, res_path, 0)


func _on_ImportExport_BtnExport_pressed() -> void:
	dialog_export.set_current_sheet(current_sheet, true)
	dialog_export.refresh_export_sheet_list()
	dialog_export.popup_centered()


func _on_ImportExport_BtnImportSheet_pressed() -> void:
	dialog_import.set_current_sheet(current_sheet)
	dialog_import.reset_and_show()


func _on_dialog_import_import_executed(destination_sheet: String) -> void:
	if destination_sheet != "":
		open_sheet(destination_sheet)
	else:
		reopen_current_sheet()
