@tool
extends GraphNode
class_name DialogGraphNode

signal connections_changed

# data is a live reference to the underlying data this GraphNode refers to
# changing properties in this script will affect the original data
@export var data: Resource

var DialogOptions_template = preload("res://addons/madtalk/components/DialogNode_DialogOptions.tscn")

var DialogNodeItem_message_template = preload("res://addons/madtalk/components/DialogNodeItem_message.tscn")
var DialogNodeItem_condition_template = preload("res://addons/madtalk/components/DialogNodeItem_condition.tscn")
var DialogNodeItem_effect_template = preload("res://addons/madtalk/components/DialogNodeItem_effect.tscn")
var DialogNodeItem_option_template = preload("res://addons/madtalk/components/DialogNodeItem_option.tscn")

@onready var topbar = get_node("TopBar")
@onready var add_menu = get_node("TopBar/AddMenu")
@onready var dialog_remove = get_node("TopBar/DialogRemove")

const COLOR_COND := Color(1.0, 0.5, 0.0, 1.0)
const COLOR_OPT := Color(0.0, 1.0, 1.0, 1.0)
const COLOR_CONT := Color(1.0, 1.0, 1.0, 1.0)

# Stores a port_index -> data resource map
var port_data_map := {}

# Stores a reference to the main editor
var main_editor: Control = null

func _ready():
	if data:
		update_from_data()

func clear():
	var itemlist = get_children()
	# Index 0 is always topbar, we ignore
	itemlist.remove_at(0)
	for item in itemlist:
		item.hide()
		item.queue_free()
	custom_minimum_size.y = 1
	size.y = 1
	# Clears the port_index -> data resource map
	port_data_map.clear()
	
func update_from_data():
	if data == null:
		return
		

	# === Clear
	clear()
	
	# === Header
	if data.sequence_id == 0:
		title = "ID: 0        START"
	else:
		title = "ID: %d" % data.sequence_id

	var i = 1 # Index 0 is topbar so we skip
	var final_size = 24 # accumulation variable
	var output_i = 0
	
	# === Items
	for item in data.items:
		
		# Type-specific actions:
		var new_item = null
		match item.item_type:
			DialogNodeItemData.ItemTypes.Message:
				item.port_index = -1
				
				new_item = DialogNodeItem_message_template.instantiate()
				clear_slot(i)
				
			DialogNodeItemData.ItemTypes.Condition:
				item.port_index = output_i
				port_data_map[output_i] = item
				output_i += 1
				
				new_item = DialogNodeItem_condition_template.instantiate()
				clear_slot(i)
				set_slot(i,      # index
					false,       # bool enable_left 
					0,           # int type_left
					Color.BLACK, # Color color_left
					true,        # bool enable_right
					0,           # int type_right
					COLOR_COND   # Color color_right
					#, Texture custom_left=null, Texture custom_right=null 
				)
				
			DialogNodeItemData.ItemTypes.Effect:
				item.port_index = -1

				new_item = DialogNodeItem_effect_template.instantiate()
				clear_slot(i)

		if new_item:
			new_item.sequence_node = self
			add_child(new_item)
			new_item.remove_requested.connect(_on_Item_remove_requested)
			new_item.move_up_requested.connect(_on_move_up_requested)
			new_item.move_down_requested.connect(_on_move_down_requested)
			new_item.mouse_entered.connect(main_editor._on_item_mouse_entered.bind(new_item))
			new_item.mouse_exited.connect(main_editor._on_item_mouse_exited.bind(new_item))
			new_item.drag_started.connect(main_editor._on_item_drag_started)
			new_item.drag_ended.connect(main_editor._on_item_drag_ended)
			new_item.set_data(item)
			final_size += new_item.custom_minimum_size.y
		
		i += 1
	
	# === Options
	# If we have options
	if data.options.size() > 0:
		# Delete the continue connection as it is invalid
		data.continue_sequence_id = -1
		data.continue_port_index = -1
		# Traverse options
		for option in data.options:
			option.port_index = output_i
			port_data_map[output_i] = option
			output_i += 1
			
			var new_opt = DialogNodeItem_option_template.instantiate()
			add_child(new_opt)
			new_opt.text = option.text
			new_opt.set_conditional(option.is_conditional)
			set_slot(i,      # index
				false,       # bool enable_left 
				0,           # int type_left
				Color.BLACK, # Color color_left
				true,        # bool enable_right
				0,           # int type_right
				COLOR_OPT   # Color color_right
				#, Texture custom_left=null, Texture custom_right=null 
			)
			final_size += new_opt.custom_minimum_size.y
			
			i += 1
	
	# If no options, continue is the single option
	else:
		data.continue_port_index = output_i
		output_i += 1
		
		var new_opt = DialogNodeItem_option_template.instantiate()
		add_child(new_opt)
		new_opt.text = "(Continue)"
		set_slot(i,      # index
			false,       # bool enable_left 
			0,           # int type_left
			Color.BLACK, # Color color_left
			true,        # bool enable_right
			0,           # int type_right
			COLOR_CONT   # Color color_right
			#, Texture custom_left=null, Texture custom_right=null 
		)
		final_size += new_opt.custom_minimum_size.y
		
		i += 1
		
	# === UPDATING SIZE
	if is_inside_tree() and get_tree():
		# We yield one frame to allow all resizing methods to be called properly
		# before we apply the final size to the node
		await get_tree().process_frame
		# This works fine when the MadTalk editor is exported in a project 
		# (such as in-game dialog editting)
		size.y = final_size
		
		# However, if the MadTalk editor is running as a plugin in the Godot Editor
		# (and only in this situation), waiting just one frame is not enough, and
		# the node resizing suffers from random-like errors. If you ever find out
		# the reason, please don't hesitate to send a PR.
		# Currently we wait a second frame and then fix the size manually again
		# A visual glitch can be seen for one frame
		await get_tree().process_frame
	
		final_size = 0
		for item in get_children():
			final_size += item.size.y
	
		size.y = final_size
		
# Given an output port index, returns the corresponding data resource
# return value can be either DialogNodeItemData or DialogNodeOptionData
func get_data_by_port(port_index: int) -> Resource:
	# first check if this is a continue port
	if port_index == data.continue_port_index:
		return data
	
	# otherwise check if invalid port
	if not port_index in port_data_map:
		return null
	
	# Finally get the data for the port
	return port_data_map[port_index]
	
# =======================================
# ADD MENU

enum AddMenuItems {
	Message,
	Condition,
	Effect
}
	
func _on_BtnAdd_pressed():
	var cursor_position =  get_viewport().get_mouse_position() if get_viewport().gui_embed_subwindows else DisplayServer.mouse_get_position()
	add_menu.popup(Rect2(cursor_position, Vector2(1,1)))
	
func _on_AddMenu_id_pressed(id):
	match id:
		AddMenuItems.Message:
			var new_data_item = DialogNodeItemData.new()
			new_data_item.resource_scene_unique_id = Resource.generate_scene_unique_id()
			new_data_item.item_type = DialogNodeItemData.ItemTypes.Message
			new_data_item.message_speaker_id = ""
			new_data_item.message_text = ""
			data.items.append(new_data_item)
			update_from_data()

		AddMenuItems.Condition:
			var new_data_item = DialogNodeItemData.new()
			new_data_item.resource_scene_unique_id = Resource.generate_scene_unique_id()
			new_data_item.item_type = DialogNodeItemData.ItemTypes.Condition
			new_data_item.condition_type = MTDefs.ConditionTypes.Random
			new_data_item.condition_values = [50]
			data.items.append(new_data_item)
			update_from_data()

		AddMenuItems.Effect:
			var new_data_item = DialogNodeItemData.new()
			new_data_item.resource_scene_unique_id = Resource.generate_scene_unique_id()
			new_data_item.item_type = DialogNodeItemData.ItemTypes.Effect
			new_data_item.effect_type = MTDefs.EffectTypes.ChangeSheet
			new_data_item.effect_values = ["",0]
			data.items.append(new_data_item)
			update_from_data()
	
	# Adding items always causes connection rebuild since the options come
	# after all the items (or the "Continue" if there are no options)
	emit_signal("connections_changed")

# =======================================
# OPTION LIST

func _on_BtnOptions_pressed():
	var dialog_opt = DialogOptions_template.instantiate()
	
	# has to be added to topbar and not to self, since all children
	# added to self will be considered a connection in the node
	topbar.add_child(dialog_opt)
	dialog_opt.connect("saved", Callable(self, "_on_DialogOptions_saved"))
	
	dialog_opt.open(data)
	
func _on_DialogOptions_saved(source_dialog):
	update_from_data()
	
	# If options changed we have to rebuild connections
	emit_signal("connections_changed")	


# =======================================
# MOVE UP/DOWN
func _on_move_up_requested(requester):
	var cur_index = data.items.find(requester.data)
	if cur_index > 0:
		var item_data = data.items[cur_index]
		data.items.remove_at(cur_index)
		data.items.insert(cur_index-1, item_data)
	update_from_data()
	emit_signal("connections_changed")
	
func _on_move_down_requested(requester):
	var cur_index = data.items.find(requester.data)
	if cur_index < (data.items.size()-1):
		var item_data = data.items[cur_index]
		data.items.remove_at(cur_index)
		data.items.insert(cur_index+1, item_data)
	update_from_data()
	emit_signal("connections_changed")

# =======================================
# REMOVE  BUTTON
var deleting_item = null
func _on_Item_remove_requested(requester):
	deleting_item = requester
	dialog_remove.popup_centered()



func _on_DialogRemove_confirmed():
	if deleting_item:
		data.items.erase(deleting_item.data)
		deleting_item.data = null
		update_from_data()
		emit_signal("connections_changed")



# =======================================
# UI events

func _on_DialogNode_dragged(from, to):
	data.position = to
