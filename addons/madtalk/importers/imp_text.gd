extends RefCounted

const name := "Text"

const description := """[b]Text Importer[/b]

This importer loads dialog in pure text output, containing [b]only messages[/b]. (It doesn't load conditions, effects, etc.)
It can load brand new dialog, as well as update messages into existing dialog. It can also be used to append new locale messages into existing message items.

The format supports very simple input, such as:

[color=#ffff77]
[lb]Sequence[rb]
alice: Hey bob! Did you ever use MadTalk?
bob: Uh... not yet. Is it good?
alice: It's awesome, it does a lot of things. [lb]i[rb]A lot![lb]/i[rb]
bob: Great! I'll check it out!
[/color]

(Notice the speakers before the colon are speaker IDs, not their display strings.)

But it also supports multiline messages, specifying speaker variants (between round brackets), locale text, and updating existing message items via their internal codes.
A more complex example, including messages which will be updated (where their codes are specified), and new sequences and messages appended to the sheet (where codes are not specified):

[color=#ffff77]
[Sheet: mary_meets_peter]
	Dialog when Mary meets Peter, on level 3 

[Sequence: ix5f6]

<jvHg7> mary: Who are you?
{pt}: Quem é você?
{jp}: 誰ですか?

<9x86f> peter(scared): Don't shoot! I'm a friend!

<g145a> peter(relieved): My name is Peter. I'm the innkeeper.
{pt}: Eu sou Pedro, o dono da estalagem.

mary: This message will be appended as a new item into the sequence above, because there is no existing code specified (the thing between <>).

[Sequence: xkj87]

<qe53y> mary: -=-=-
I'm leaving now. See you!

[lb]i[rb](Honestly, I hope I never come back!)[lb]/i[rb]
-=-=-

[Sequence]

mary: This message (and the one below) will be added into a brand new sequence, because the "Sequence" tag above doesn't specify the internal code for an existing sequence.

peter: Cool!
[/color]
"""

const MULTILINE_MARKER := "-=-=-"

var resource_map := {}

enum ImportResults {
	OK,
	INVALID_START
}

var re_speaker_without_resource := RegEx.new()
var re_speaker_with_resource := RegEx.new()
var re_locale_text := RegEx.new()


func _init():
	re_speaker_without_resource.compile("^(?<n>.*): (?<t>.+)")
	re_speaker_with_resource.compile("^<(?<r>\\w+)> (?<n>.*): (?<t>.+)")
	re_locale_text.compile("^{(?<l>[a-zA-Z0-9\\-]+)}: (?<t>.+)")

func refresh_resource_map(dialog_data: DialogData):
	resource_map.clear()
	resource_map["dialog_data"] = dialog_data


func append_resource_map(sheet_id: String):
	var dialog_data: DialogData = resource_map["dialog_data"]
	
	if sheet_id in dialog_data.sheets:
		var sheet_data: DialogSheetData = dialog_data.sheets[sheet_id]
	
		resource_map[sheet_id] = {}
		resource_map[sheet_id][sheet_data.resource_scene_unique_id] = sheet_data
		
		for dialog_node: DialogNodeData in sheet_data.nodes:
			resource_map[sheet_id][dialog_node.resource_scene_unique_id] = dialog_node
			for dialog_item: DialogNodeItemData in dialog_node.items:
				resource_map[sheet_id][dialog_item.resource_scene_unique_id] = dialog_item


func get_speaker_and_variant(input: String) -> Array:
	var result := ["", ""]
	
	if ("(" in input) and (input.ends_with(")")):
		var rpos: int = input.rfind("(")
		result[0] = input.left(rpos)
		result[1] = input.substr(rpos+1, input.length() - rpos - 2)
	
	else:
		result[0] = input
	
	return result


func get_multiline_text(input: Array) -> String:
	# input contains one string per item, the starting line with the MULTILINE_MARKER
	# is already removed - input[0] is already content
	# this function SHOULD remove consumed lines from the array (passed by reference)
	
	var result := ""
	
	# Line should not go through strip_edges() as extra spaces might be part of the content
	var line: String = input.pop_front()
	var i = 0
	while line and (not line.begins_with(MULTILINE_MARKER)):
		if result.length() > 0:
			result += "\n"
		result += line
		
		line = input.pop_front()
		
		i += 1
		if i > 1000:
			# Safeguard in case something goes wrong in the file
			break
		
	# Final line with MULTILINE_MARKER is discarded
	
	return result


func import(dialog_data: DialogData, input: String) -> Dictionary:
	var result := {
		"status": ImportResults.OK,
		"sheets": {
			# 	"sheet_id": {
			# 		"sheet_id": "...",
			# 		"sheet_desc": "...",
			# 		"nodes": [...],
			# 	}
		},
	}
	
	refresh_resource_map(dialog_data)
	
	var lines: Array = Array(input.split("\n"))
	
	
	# Sequences
	var sequence_unique_id := ""
	var current_node = null # from MadTalk dialog resource
	var current_tree_node = null # from result tree
	
	var message_unique_id := ""
	var current_message: DialogNodeItemData = null
	var current_tree_message = null
	
	var sheet_items := []
	var sheet_id := ""
	var sheet_desc := ""
	var line = lines.pop_front().strip_edges()
	
	var i = 0
	while line is String:
		i += 1
		if i > 99999:
			print("MadTalk importer: reached maximum loop iterations. File malformed?")
			break
		
		var line_clean = line.strip_edges()
		
		# Beginning of new Sheet ID
		if (line_clean.begins_with("[Sheet: ")) and (line_clean.ends_with("]")):
			
			# First, finish previous sheet_items
			if sheet_items.size() > 0:
				# Commits previous sheet data to result, and start new one
				if sheet_id in result["sheets"]:
					# If sheet is already in result, we merge
					result["sheets"][sheet_id]["nodes"].append_array(sheet_items)
				else:
					result["sheets"][sheet_id] = {
						"sheet_id": sheet_id,
						"sheet_desc": sheet_desc,
						"nodes": sheet_items,
					}
					
				sheet_items = [] # Assing new array, don't call .clear() !
			
			# else: sheet_items already empty, no action
			
			# Now start new sheet
			sheet_id = line_clean.substr(8, line_clean.length()-9)
			sheet_desc = ""
			append_resource_map(sheet_id)
		
			# Description
			line = lines.pop_front()
			while not line.begins_with("[Sequence"):
				if sheet_desc.length() > 0:
					sheet_desc += " " # Description is single-line. Line breaks are for text file readability only.
				sheet_desc += line.strip_edges()
				line = lines.pop_front()
			line_clean = line.strip_edges()
			# This block doesn't use `continue` because we already fetched
			# the next line, so we don't waste it and process it below
		
		if line_clean.strip_edges() == "[Sequence]":
			message_unique_id = ""
			current_message = null
			current_tree_message = null
			
			sequence_unique_id = ""
			current_node = null
			current_tree_node = {"sequence_uid": "", "items": []}
			sheet_items.append(current_tree_node)
			
			line = lines.pop_front()
			continue
		
		if line_clean.begins_with("[Sequence: ") and line_clean.ends_with("]"):
			message_unique_id = ""
			current_message = null
			current_tree_message = null
			
			sequence_unique_id = line_clean.substr(11, line_clean.length()-12)
			if sequence_unique_id in resource_map:
				current_node = resource_map[sequence_unique_id]
			else:
				#sequence_unique_id = ""
				current_node = null
				#current_tree_node = null
			current_tree_node = {"sequence_uid": sequence_unique_id, "items": []}
			sheet_items.append(current_tree_node)
			
			line = lines.pop_front()
			continue
		
		
		if (not ": " in line):
			# Line not relevant, skipping...
			line = lines.pop_front()
			continue
		
		var re_res = re_speaker_with_resource.search(line)
		if re_res is RegExMatch:
			# Message start
			message_unique_id = re_res.get_string("r")
			if message_unique_id in resource_map:
				current_message = resource_map[message_unique_id]
			else:
				current_message = null
			
			current_tree_message = {"message_uid": message_unique_id, "locales": {}}
			
			if (current_tree_node == null):
				# This usually happens if the user forgot to explicitly start a sequence
				# at the top of the file 
				current_tree_node = {"sequence_uid": "", "items": []}
				sheet_items.append(current_tree_node)
			
			current_tree_node["items"].append(current_tree_message)
			
			var speaker_variant: Array = get_speaker_and_variant(re_res.get_string("n"))
			var message_line: String = re_res.get_string("t").strip_edges()
			if message_line == MULTILINE_MARKER:
				message_line = get_multiline_text(lines)
			
			current_tree_message["speaker_id"] = speaker_variant[0]
			current_tree_message["variant"] = speaker_variant[1]
			current_tree_message["message_text"] = message_line
		
		else:
			re_res = re_locale_text.search(line)
			if re_res:
				# Locale
				if current_tree_message:
					var locale: String = re_res.get_string("l")
					var message_line: String = re_res.get_string("t")
					if message_line == MULTILINE_MARKER:
						message_line = get_multiline_text(lines)
					
					current_tree_message["locales"][locale] = message_line
			
			else:
				re_res = re_speaker_without_resource.search(line)
				if re_res:
					# New message, without resource uid
					var speaker_variant: Array = get_speaker_and_variant(re_res.get_string("n"))
					var message_line: String = re_res.get_string("t").strip_edges()
					if message_line == MULTILINE_MARKER:
						message_line = get_multiline_text(lines)
					
					current_tree_message = {"message_uid": "", "locales": {}}
					
					if (current_tree_node == null):
						# This usually happens if the user forgot to explicitly start a sequence
						# at the top of the file 
						current_tree_node = {"sequence_uid": "", "items": []}
						sheet_items.append(current_tree_node)
					
					current_tree_node["items"].append(current_tree_message)
					
					current_tree_message["speaker_id"] = speaker_variant[0]
					current_tree_message["variant"] = speaker_variant[1]
					current_tree_message["message_text"] = message_line
		
		line = lines.pop_front()
	
	# Append final sheet:
	if sheet_items.size() > 0:
		# Commits previous sheet data to result, and start new one
		if sheet_id in result["sheets"]:
			# If sheet is already in result, we merge
			result["sheets"][sheet_id]["nodes"].append_array(sheet_items)
		else:
			result["sheets"][sheet_id] = {
				"sheet_id": sheet_id,
				"sheet_desc": sheet_desc,
				"nodes": sheet_items,
			}
	
	return result
