@tool
extends Window

signal import_executed(destination_sheet: String) # destination_sheet = "" when not collapsing

var mt_ie := MadTalkImportExport.new()
var dialog_data: DialogData
var current_sheet_id: String = ""

var template_CheckBoxLocale := preload("res://addons/madtalk/components/CheckBoxLocale.tscn")

@onready var panel_input := $PanelInput
@onready var panel_options := $PanelOptions

@onready var btn_importer := $PanelInput/BtnImporter
@onready var input_edit  := $PanelInput/InputEdit
@onready var importer_desc := $PanelInput/ImporterDesc

@onready var import_summary := $PanelOptions/ImportSummary

@onready var btn_destination := $PanelOptions/BtnDestination
@onready var label_sheets := $PanelOptions/BtnDestination/LabelSheets
@onready var locale_listbox := $PanelOptions/LocaleListScroll/LocaleList

var prepared_data := {}
var resource_map := {}
var sheet_info := {}

func setup(data: DialogData, sheet_id: String):
	dialog_data = data
	current_sheet_id = sheet_id
	
	mt_ie.refresh_list_importers()
	
	# mt_ie.importers_list = { "absolute path to .gd": "Friendly Name", }
	
	btn_importer.clear()
	for path in mt_ie.importers_list:
		btn_importer.add_item(mt_ie.importers_list[path])
	btn_importer.select(-1)
	
	resource_map.clear()
	sheet_info.clear()
	
	input_edit.text = ""
	panel_input.show()
	panel_options.hide()


func set_current_sheet(sheet: String):
	current_sheet_id = sheet
	update_resource_map()


func reset_and_show():
	panel_input.show()
	panel_options.hide()
	popup_centered()


func update_resource_map(extra_sheets: Array = []):
	resource_map.clear()
	sheet_info.clear()
	
	if (not dialog_data):
		return
	
	var sheet_list := [current_sheet_id]
	sheet_list.append_array(extra_sheets)
	
	for sheet_id in sheet_list:
		if sheet_id in dialog_data.sheets:
			var sheet_data = dialog_data.sheets[sheet_id]
			resource_map[sheet_id] = {}
			sheet_info[sheet_id] = {}
			
			for dialog_node: DialogNodeData in sheet_data.nodes:
				resource_map[sheet_id][dialog_node.resource_scene_unique_id] = dialog_node
				sheet_info[sheet_id][dialog_node.resource_scene_unique_id] = {
					"type": "sequence",
					"sequence_id": dialog_node.sequence_id
				}
				
				for item_index in range(dialog_node.items.size()):
					var dialog_item: DialogNodeItemData = dialog_node.items[item_index]
					
					if dialog_item.item_type == DialogNodeItemData.ItemTypes.Message:
						resource_map[sheet_id][dialog_item.resource_scene_unique_id] = dialog_item
						sheet_info[sheet_id][dialog_item.resource_scene_unique_id] = {
							"type": "message",
							"item_index": item_index,
							"sequence_id": dialog_node.sequence_id,
						}


func _resource_map_append_sheet(sheet_id: String):
	# Only appends the sheet itself, not the contents
	var sheet_data = dialog_data.sheets[sheet_id]
	resource_map[sheet_id] = {}
	sheet_info[sheet_id] = {}


func _resource_map_append_sequence(sheet_id: String, dialog_node: DialogNodeData):
	# Only appends the sequence itself, not the items
	resource_map[sheet_id][dialog_node.resource_scene_unique_id] = dialog_node
	sheet_info[sheet_id][dialog_node.resource_scene_unique_id] = {
		"type": "sequence",
		"sequence_id": dialog_node.sequence_id
	}


func _resource_map_append_message(sheet_id: String, sequence_uid: String, item_index: int, dialog_item: DialogNodeItemData):
	if not sequence_uid in resource_map[sheet_id]:
		return
	
	if not dialog_item.item_type == DialogNodeItemData.ItemTypes.Message:
		return
	
	var dialog_node: DialogNodeData = resource_map[sheet_id][sequence_uid]
	
	resource_map[sheet_id][dialog_item.resource_scene_unique_id] = dialog_item
	sheet_info[sheet_id][dialog_item.resource_scene_unique_id] = {
		"type": "message",
		"item_index": item_index,
		"sequence_id": dialog_node.sequence_id,
	}



func _on_btn_close_pressed() -> void:
	hide()

# ---------------------------------------


func _mark_locale_as_mentioned(locale: String):
	if not locale in prepared_data["locales_mentioned"]:
		prepared_data["locales_mentioned"].append(locale)


func _refresh_locale_listbox(locales: Array):
	for child in locale_listbox.get_children():
		child.queue_free()
	
	# Default is always included
	var new_checkbox := template_CheckBoxLocale.instantiate()
	new_checkbox.locale = ""
	new_checkbox.text = "Default locale"
	locale_listbox.add_child(new_checkbox)
	new_checkbox.toggled.connect(_on_check_box_locale_toggled)
	
	for locale in locales:
		if locale != "":
			new_checkbox = template_CheckBoxLocale.instantiate()
			new_checkbox.locale = locale
			new_checkbox.text = locale
			locale_listbox.add_child(new_checkbox)
			new_checkbox.toggled.connect(_on_check_box_locale_toggled)



func prepare(text: String, restricted_locales: Array = []):
	var restrict_locales: bool = (restricted_locales.size() > 0)
	prepared_data.clear()
	
	if (not dialog_data) or (not current_sheet_id in dialog_data.sheets) or (btn_importer.selected < 0) or (btn_importer.selected >= mt_ie.importers_list.size()):
		print("MadTalk importer error")
		return false
	
	var importer_script = mt_ie.importers_list.keys()[ btn_importer.selected ]
	var importer = load(importer_script).new()
	
	var imported_data = importer.import(dialog_data, text)
	
	if (not "status" in imported_data) or (imported_data["status"] != importer.ImportResults.OK):
		print("MadTalk importer error")
		return false
	
	# Sort destination sheets and make sure they exist
	var collapse_destination := false
	var destination_sheet := "" # Only used if sollapsing destination
	var destination_desc := ""
	match btn_destination.selected:
		0:
			# Respect original sheets
			collapse_destination = false
		1:
			collapse_destination = true
			destination_sheet = current_sheet_id
		2:
			collapse_destination = true
			destination_sheet = _make_sheet_name()
			destination_desc = "(Sheet created while importing dialog data - please rename and change description)"
		_:
			return false
	
	prepared_data["collapse_destination"] = collapse_destination
	prepared_data["destination_sheet"] = destination_sheet
	prepared_data["to_modify"] = {} # sheet_id: { sequence_uid: { message_uid: message_item, ... } }
	prepared_data["to_append"] = {} # sheet_id: { sequence_uid: [ message_item, message_item, ... ] }
	prepared_data["new"] = {} # sheet_id: { array (sequence) of array (message) }
	prepared_data["stats"] = {
		"modified_sequences": 0,
		"modified_messages": 0,
		"appended_sequences": 0,
		"appended_messages": 0,
		"new_sequences": 0,
		"new_messages": 0,
		"missing_sequences": 0,
		"missing_messages": 0,
	}
	prepared_data["locales_mentioned"] = []
	prepared_data["affected_sheets"] = []
	prepared_data["sheet_info"] = {}
	
	var original_sheet_list: Array = imported_data["sheets"].keys().duplicate()
	
	if collapse_destination:
		prepared_data["affected_sheets"] = [destination_sheet]
		prepared_data["sheet_info"] = { destination_sheet: {
			"sheet_id": destination_sheet,
			"sheet_desc": destination_desc,
		}}
	
	else:
		prepared_data["affected_sheets"] = original_sheet_list
		for sheet_id in imported_data["sheets"]:
			prepared_data["sheet_info"][sheet_id] = {
				"sheet_id": imported_data["sheets"][sheet_id]["sheet_id"],
				"sheet_desc": imported_data["sheets"][sheet_id]["sheet_desc"]
			}
	
	update_resource_map(prepared_data["affected_sheets"])
	
	if collapse_destination:
		if not destination_sheet in resource_map:
			resource_map[destination_sheet] = {} # Just so key access doesn't crash - it's ok to be empty
		if not destination_sheet in prepared_data["to_modify"]:
			prepared_data["to_modify"][destination_sheet] = {}
		if not destination_sheet in prepared_data["to_append"]:
			prepared_data["to_append"][destination_sheet] = {}
		if not destination_sheet in prepared_data["new"]:
			prepared_data["new"][destination_sheet] = []

	
	for source_sheet_id in imported_data["sheets"]:
		var sheet_id: String = destination_sheet if collapse_destination else source_sheet_id
		# source_sheet_id is used when reading source (imported_data)
		# sheet_id is used when writing to prepateddata or checking resource_map
		
		if not collapse_destination:
			if not sheet_id in resource_map:
				resource_map[sheet_id] = {} # Just so key access doesn't crash - it's ok to be empty
			if not sheet_id in prepared_data["to_modify"]:
				prepared_data["to_modify"][sheet_id] = {}
			if not sheet_id in prepared_data["to_append"]:
				prepared_data["to_append"][sheet_id] = {}
			if not sheet_id in prepared_data["new"]:
				prepared_data["new"][sheet_id] = []
		
		for node: Dictionary in imported_data["sheets"][source_sheet_id]["nodes"]:
			if (node["sequence_uid"] != ""):
				if node["sequence_uid"] in resource_map[sheet_id]:
					node["sequence_resource"] = resource_map[sheet_id][node["sequence_uid"]]
					#prepared_data["stats"]["modified_sequences"] += 1
				else:
					node["sequence_uid"] = ""
					prepared_data["stats"]["missing_sequences"] += 1
				
			
			# Existing sequence
			if (node["sequence_uid"] != "") and (node["sequence_uid"] in resource_map[sheet_id]):
				# Sequence exists in this sheet
				prepared_data["to_modify"][sheet_id][node["sequence_uid"]] = {}
				prepared_data["to_append"][sheet_id][node["sequence_uid"]] = []
				
				var sequence_message_modified_count := 0
				for item: Dictionary in node["items"]:
					# Locales mentioned is recorded even if message is discarded
					for locale in item["locales"]:
						_mark_locale_as_mentioned(locale)
					
					if restrict_locales and (not "" in restricted_locales):
						var has_at_least_one_locale := false
						for locale in restricted_locales:
							if locale in item["locales"]:
								has_at_least_one_locale = true
								break
						if not has_at_least_one_locale:
							continue
					
					# Delete unwanted locales - except default
					if restrict_locales:
						item = item.duplicate(true)
						var orig_locales = item["locales"].keys().duplicate()
						for locale in orig_locales:
							if not locale in restricted_locales:
								item["locales"].erase(locale)
					
					if (item["message_uid"] != ""):
						if item["message_uid"] in resource_map[sheet_id]:
							item["message_resource"] = resource_map[sheet_id][item["message_uid"]]
							prepared_data["stats"]["modified_messages"] += 1
							prepared_data["to_modify"][sheet_id][node["sequence_uid"]][item["message_uid"]] = item
						
						else:
							item["message_uid"] = ""
							prepared_data["stats"]["missing_messages"] += 1
							prepared_data["stats"]["new_messages"] += 1
							prepared_data["to_append"][sheet_id][node["sequence_uid"]].append(item)
					
					else:
						prepared_data["stats"]["new_messages"] += 1
						prepared_data["to_append"][sheet_id][node["sequence_uid"]].append(item)
					
					sequence_message_modified_count += 1
					
				if sequence_message_modified_count > 0:
					prepared_data["stats"]["modified_sequences"] += 1
			
			# New sequence
			else:
				# Either it's a new sequence, or the sequence was specified, but not found
				# this happens when importing a file exported from a different sheet
				# should be treated as a new sequence
				var new_sequence_array := []
				for item: Dictionary in node["items"]:
					# Locales mentioned is recorded even if message is discarded
					for locale in item["locales"]:
						_mark_locale_as_mentioned(locale)
					
					if restrict_locales and (not "" in restricted_locales):
						var has_at_least_one_locale := false
						for locale in restricted_locales:
							if locale in item["locales"]:
								has_at_least_one_locale = true
								break
						if not has_at_least_one_locale:
							continue
					
					if restrict_locales:
						item = item.duplicate(true)
						var orig_locales = item["locales"].keys().duplicate()
						for locale in orig_locales:
							if not locale in restricted_locales:
								item["locales"].erase(locale)
				
					prepared_data["stats"]["new_messages"] += 1
					new_sequence_array.append(item)
					
				if new_sequence_array.size() > 0:
					prepared_data["new"][sheet_id].append(new_sequence_array)
					prepared_data["stats"]["new_sequences"] += 1
	
	# Sanitize empty lists:
	var sheet_ids = prepared_data["to_modify"].keys()
	for sheet_id in sheet_ids:
		var seq_ids: Array = prepared_data["to_modify"][sheet_id].keys()
		for sequence_uid: String in seq_ids:
			if prepared_data["to_modify"][sheet_id][sequence_uid].size() == 0:
				prepared_data["to_modify"][sheet_id].erase(sequence_uid)
		if prepared_data["to_modify"][sheet_id].size() == 0:
			prepared_data["to_modify"].erase(sheet_id)
	
	sheet_ids = prepared_data["to_append"].keys()
	for sheet_id in sheet_ids:
		var seq_ids: Array = prepared_data["to_append"][sheet_id].keys()
		for sequence_uid: String in seq_ids:
			if prepared_data["to_append"][sheet_id][sequence_uid].size() == 0:
				prepared_data["to_append"][sheet_id].erase(sequence_uid)
		if prepared_data["to_append"][sheet_id].size() == 0:
			prepared_data["to_append"].erase(sheet_id)
	
	sheet_ids = prepared_data["new"].keys()
	for sheet_id in sheet_ids:
		if prepared_data["new"][sheet_id].size() == 0:
			prepared_data["new"].erase(sheet_id)
	
	import_summary.text = generate_summary(restricted_locales)


func reload(restrict_locales: bool = false):
	if restrict_locales:
		var restricted_locales := []
		var is_restricted := false
		for checkbox in locale_listbox.get_children():
			if checkbox.button_pressed:
				restricted_locales.append(checkbox.locale)
			else:
				is_restricted = true
		if not is_restricted:
			restricted_locales.clear()
		
		prepare(input_edit.text, restricted_locales)
	else:
		prepare(input_edit.text)
	
	_update_destination_text(btn_destination.selected)



func _cardinal_number(value: int) -> String:
	match value:
		0:
			return "1st"
		1:
			return "2nd"
		2:
			return "3rd"
		_:
			return str(value)+"th"


func _print_message_item(item: Dictionary, show_default_locale: bool = true) -> String:
	var result := ""
	
	result += "Speaker: \"[color=#ff9955]%s[/color]\"    Variant: \"[color=#ff9955]%s[/color]\"\nText:\n" % [item["speaker_id"], item["variant"]]
	if show_default_locale:
		result += "    [color=#aacc55][lb]default locale[rb][/color]\n"
		result += "    [color=#55ffff]%s[/color]\n" % item["message_text"]
	for locale in item["locales"]:
		result += "    [color=#aacc55][lb]%s[rb][/color]\n" % locale
		result += "    [color=#55ffff]%s[/color]\n" % item["locales"][locale]
	
	return result


func generate_summary(restricted_locales: Array = []) -> String:
	var show_default_locale: bool = (restricted_locales.size() == 0) or ("" in restricted_locales)
	
	var result := "[color=#ff3333][b]=== WARNING: THERE IS NO UNDO ===[/b][/color]\n\n"
	
	if prepared_data["stats"]["modified_sequences"] > 0:
		result += "[color=#ff5555][b]%d sequence(s) will be modified[/b][/color]\n" % prepared_data["stats"]["modified_sequences"]
	
	if prepared_data["stats"]["modified_messages"] > 0:
		result += "[color=#ff5555][b]%d message(s) items will be modified[/b][/color]\n" % prepared_data["stats"]["modified_messages"]
	
	if prepared_data["stats"]["appended_sequences"] > 0:
		result += "[color=#ff5555][b]%d sequence(s) will have new messages appended[/b][/color]\n" % prepared_data["stats"]["appended_sequences"]
	
	if prepared_data["stats"]["appended_messages"] > 0:
		result += "[color=#ff5555][b]%d message(s) items will be appended to existing sequences[/b][/color]\n" % prepared_data["stats"]["appended_messages"]
	
	if prepared_data["stats"]["missing_sequences"] > 0:
		result += "[color=#ffbb55][b]%d sequence(s) were supposed to be modified, but the codes they refer to were not found. They will be inserted as new sequences instead.[/b][/color]\n" % prepared_data["stats"]["missing_sequences"]
	
	if prepared_data["stats"]["missing_messages"] > 0:
		result += "[color=#ffbb55][b]%d message(s) items were supposed to be modified, but the codes they refer to were not found. They will be inserted as new messages instead.[/b][/color]\n" % prepared_data["stats"]["missing_messages"]
	
	if prepared_data["stats"]["new_sequences"] > 0:
		result += "[color=#55ff55][b]%d new sequence(s) will be created[/b][/color]\n" % prepared_data["stats"]["new_sequences"]
	
	if prepared_data["stats"]["new_messages"] > 0:
		result += "[color=#55ff55][b]%d new messages will be created[/b][/color]\n" % prepared_data["stats"]["new_messages"]
	
	
	# Modified messages:
	if prepared_data["stats"]["modified_messages"] > 0:
		result += "\n========================================================\n"
		result += "SEQUENCES/MESSAGES TO BE MODIFIED\n"
		result += "--------------------------------------------------------\n\n"
		
		for sheet_id in prepared_data["to_modify"]:
			if prepared_data["to_modify"][sheet_id].size() == 0:
				continue
			
			result += "[color=#9999ff]Sheet ID: [b]%s[/b][/color]\n\n" % (sheet_id if (sheet_id != "") else "(not specified)")
			
			for sequence_uid: String in prepared_data["to_modify"][sheet_id]:
				var node: Dictionary = prepared_data["to_modify"][sheet_id][sequence_uid]
				var node_resource: DialogNodeData = resource_map[sheet_id][sequence_uid]
				
				result += " === Sequence ID [b]%d[/b] ===\n\n" % node_resource.sequence_id
				
				for message_uid: String in node:
					var item: Dictionary = node[message_uid]
					var message_info: Dictionary = sheet_info[sheet_id][message_uid]
					
					result += "--- Item index %d (the %s item in the sequence) ---\n" % [
						message_info["item_index"],
						_cardinal_number(message_info["item_index"])
					]
					result += _print_message_item(item, show_default_locale)
					result += "\n---\n\n"
				
	
	if prepared_data["to_append"].size() > 0:
		result += "\n========================================================\n"
		result += "SEQUENCES TO HAVE MESSAGES APPENDED\n"
		result += "--------------------------------------------------------\n\n"
		
		for sheet_id in prepared_data["to_append"]:
			if prepared_data["to_append"][sheet_id].size() == 0:
				continue
			
			result += "[color=#9999ff]Sheet ID: [b]%s[/b][/color]\n\n" % (sheet_id if (sheet_id != "") else "(not specified)")

			for sequence_uid: String in prepared_data["to_append"][sheet_id]:
				var node: Array = prepared_data["to_append"][sheet_id][sequence_uid]
				var node_resource: DialogNodeData = resource_map[sheet_id][sequence_uid]
				
				result += " === Sequence ID [b]%d[/b] ===\n\n" % node_resource.sequence_id
				
				for item: Dictionary in node:
					result += _print_message_item(item, show_default_locale)
					result += "\n---\n\n"

	if prepared_data["new"].size() > 0:
		result += "\n========================================================\n"
		result += "NEW SEQUENCES/MESSAGES\n"
		result += "--------------------------------------------------------\n\n"
		
		for sheet_id in prepared_data["new"]:
			if prepared_data["new"][sheet_id].size() == 0:
				continue
			
			result += "[color=#9999ff]Sheet ID: [b]%s[/b][/color]\n\n" % (sheet_id if (sheet_id != "") else "(not specified)")
		
			for node: Array in prepared_data["new"][sheet_id]:
				result += " === New sequence ===\n\n"
			
				for item: Dictionary in node:
					result += _print_message_item(item, show_default_locale)
					result += "\n---\n\n"

	
	return result


func execute(restricted_locales: Array = []) -> bool:
	var include_default_locale: bool = (restricted_locales.size() == 0) or ("" in restricted_locales)
	
	if prepared_data["stats"]["modified_messages"] > 0:
		for sheet_id in prepared_data["to_modify"]:
			for sequence_uid: String in prepared_data["to_modify"][sheet_id]:
				var node: Dictionary = prepared_data["to_modify"][sheet_id][sequence_uid]
				
				for message_uid: String in node:
					var item: Dictionary = node[message_uid]
					_execute_modify_message(sheet_id, sequence_uid, message_uid, item, include_default_locale)
	
	if prepared_data["to_append"].size() > 0:
		for sheet_id in prepared_data["to_append"]:
			for sequence_uid: String in prepared_data["to_append"][sheet_id]:
				var node: Array = prepared_data["to_append"][sheet_id][sequence_uid]
				
				for item: Dictionary in node:
					_execute_create_message(sheet_id, sequence_uid, item, include_default_locale)

	if prepared_data["new"].size() > 0:
		for sheet_id in prepared_data["new"]:
			var sheet_desc: String = prepared_data["sheet_info"][sheet_id]["sheet_desc"] if sheet_id in prepared_data["sheet_info"] else ""
			_execute_create_sheet_if_needed(sheet_id, sheet_desc, false)
			
			for node: Array in prepared_data["new"][sheet_id]:
				var dialog_node: DialogNodeData = _execute_create_sequence(sheet_id, false)
				var sequence_uid: String = dialog_node.resource_scene_unique_id
				
				for item: Dictionary in node:
					_execute_create_message(sheet_id, sequence_uid, item, include_default_locale)
	
	var signal_sheet_id := ""
	if prepared_data["collapse_destination"]:
		signal_sheet_id = prepared_data["destination_sheet"]
	
	import_executed.emit(signal_sheet_id)
	
	return true


func _make_sheet_name() -> String:
	var sheet_num = 1
	var new_sheet_name = "new_imported_sheet_1"
	while new_sheet_name in dialog_data.sheets:
		sheet_num += 1
		new_sheet_name = "new_imported_sheet_%d" % sheet_num
	return new_sheet_name


func _execute_create_sheet_if_needed(sheet_id: String, desc: String = "", create_id_zero: bool = true) -> DialogSheetData:
	if not sheet_id in dialog_data.sheets:
		var new_sheet_data = DialogSheetData.new() # default next_sequence_id=0
		new_sheet_data.resource_scene_unique_id = Resource.generate_scene_unique_id()
		new_sheet_data.sheet_id = sheet_id
		new_sheet_data.sheet_description = desc
		new_sheet_data.nodes = [] # Forces a new array to avoid reference sharing
		dialog_data.sheets[sheet_id] = new_sheet_data
		_resource_map_append_sheet(sheet_id)
		
		if create_id_zero:
			# Sequence MUST have ID 0
			# this can only be bypassed if the code invoking this method
			# will take care of creating it externally
			_execute_create_sequence(sheet_id, false)
	
	return dialog_data.sheets[sheet_id]


func _execute_create_sequence(sheet_id: String, create_sheet_if_needed: bool = true) -> DialogNodeData:
	var sheet_data: DialogSheetData
	if create_sheet_if_needed:
		sheet_data = _execute_create_sheet_if_needed(sheet_id, "", false)
	elif sheet_id in dialog_data.sheets:
		sheet_data = dialog_data.sheets[sheet_id]
	else:
		return null
	
	# Find next available sequence id
	var next_available_id = sheet_data.next_sequence_id
	for this_node in sheet_data.nodes:
		if this_node.sequence_id >= next_available_id:
			next_available_id = this_node.sequence_id+1

	var new_data = DialogNodeData.new()
	new_data.resource_scene_unique_id = Resource.generate_scene_unique_id()
	new_data.position = Vector2(30,30) * next_available_id
	new_data.sequence_id = next_available_id
	new_data.items = [] # New Array to avoid sharing references
	new_data.options = [] # New Array to avoid sharing references
	
	_resource_map_append_sequence(sheet_id, new_data)
	
	sheet_data.nodes.append(new_data)
	sheet_data.next_sequence_id = next_available_id+1
	
	return new_data


func _execute_create_message(sheet_id: String, sequence_uid: String, dict: Dictionary = {}, include_default_locale: bool = true) -> DialogNodeItemData:
	if not sheet_id in dialog_data.sheets:
		return null
	
	if not sequence_uid in resource_map[sheet_id]:
		return null
	
	var sheet_data: DialogSheetData = dialog_data.sheets[sheet_id]
	var dialog_node: DialogNodeData = resource_map[sheet_id][sequence_uid]
	
	var new_data_item = DialogNodeItemData.new()
	new_data_item.resource_scene_unique_id = Resource.generate_scene_unique_id()
	new_data_item.item_type = DialogNodeItemData.ItemTypes.Message
	if dict.size() == 0:
		new_data_item.message_speaker_id = ""
		new_data_item.message_text = ""
	else:
		new_data_item.message_speaker_id = dict["speaker_id"]
		new_data_item.message_speaker_variant = dict["variant"]
		
		if include_default_locale:
			new_data_item.message_text = dict["message_text"]
		
		for locale in dict["locales"]:
			new_data_item.message_text_locales[locale] = dict["locales"][locale]
	
	dialog_node.items.append(new_data_item)
	
	var item_index = dialog_node.items.find(new_data_item)
	
	_resource_map_append_message(sheet_id, sequence_uid, item_index, new_data_item)
	
	return new_data_item




func _execute_modify_message(sheet_id: String, sequence_uid: String, message_uid: String, dict: Dictionary, include_default_locale: bool = true):
	if not sheet_id in dialog_data.sheets:
		return null
	
	if not sequence_uid in resource_map[sheet_id]:
		return null
	
	if not message_uid in resource_map[sheet_id]:
		return null
	
	var sheet_data: DialogSheetData = dialog_data.sheets[sheet_id]
	var dialog_node: DialogNodeData = resource_map[sheet_id][sequence_uid]
	var dialog_item: DialogNodeItemData = resource_map[sheet_id][message_uid]
	
	dialog_item.message_speaker_id = dict["speaker_id"]
	dialog_item.message_speaker_variant = dict["variant"]
	
	if include_default_locale:
		dialog_item.message_text = dict["message_text"]
	
	for locale in dict["locales"]:
		dialog_item.message_text_locales[locale] = dict["locales"][locale]



# ---------------------------------------


func _on_btn_importer_item_selected(index: int) -> void:
	if (btn_importer.selected < 0) or (btn_importer.selected >= mt_ie.importers_list.size()):
		print("MadTalk importer error")
		return
	
	var importer_script = mt_ie.importers_list.keys()[ btn_importer.selected ]
	var importer = load(importer_script).new()
	importer_desc.text = importer.description


func _on_btn_load_pressed() -> void:
	btn_destination.select(0)
	reload()
	_refresh_locale_listbox(prepared_data["locales_mentioned"])
	panel_input.hide()
	panel_options.show()


func _on_options_btn_back_pressed() -> void:
	panel_input.show()
	panel_options.hide()
	import_summary.text = ""
	prepared_data.clear()


func _on_btn_destination_item_selected(index: int) -> void:
	reload(true)


func _update_destination_text(index: int):
	var s := ""
	match index:
		0:
			s = "Destination sheets from the imported data will be respected. Messages with unspecified sheet ID will affect currenty selected sheet ([color=#ffcc55]%s[/color]).\n\nThe following sheets will be affected:\n" % current_sheet_id
			for sheet_id in prepared_data["affected_sheets"]:
				s += "[color=#ffcc55][b]%s[/b][/color]\n" % (sheet_id if sheet_id != "" else ("Current sheet (%s)" % current_sheet_id))
		
		1:
			s = "All content will be imported into current sheet ([color=#ffcc55]%s[/color]), ignoring the sheets mentioned in imported data.\n\nThe following sheets will be affected:\n" % current_sheet_id
			s += "[color=#ffcc55][b]%s[/b][/color]\n" % current_sheet_id
		
		2:
			s = "All content will be imported into a brand new sheet, ignoring the sheets mentioned in imported data.\n\nThe following sheets will be affected:\n"
			s += "[color=#ffcc55][b](new sheet will be created)[/b][/color]\n"
		
		
	label_sheets.text = s


func _on_check_box_locale_toggled(_toggled_on: bool) -> void:
	reload(true)


func _on_btn_import_pressed() -> void:
	var restricted_locales := []
	var is_restricted := false
	for checkbox in locale_listbox.get_children():
		if checkbox.button_pressed:
			restricted_locales.append(checkbox.locale)
		else:
			is_restricted = true
	if not is_restricted:
		restricted_locales.clear()
	
	execute(restricted_locales)
	hide()
