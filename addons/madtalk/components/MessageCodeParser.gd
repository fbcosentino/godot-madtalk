extends Reference
class_name MessageCodeParser

const tag_if_start = "{{if "
const tag_if_start_len = 5

const tag_if_end = "}}"
const tag_if_end_len = 2

const cond_sep = ": "
const cond_sep_len = 2

const operators = [" >= ", " <= ", " != ", " > ", " < ", " = "]



func process(source_text: String, variables: Dictionary) -> Array:
	var result = ""
	
	var message_list = parse(source_text, variables)
	for msg in message_list:
		if msg is String:
			result += msg
			
		elif (msg is Dictionary) and (msg["condition"] in variables):
			var var_value = variables[msg["condition"]]
			var message_approved = false
			match msg["operator"]:
				"=":
					message_approved = (var_value == msg["value"])
				"!=":
					message_approved = (var_value != msg["value"])
				">":
					message_approved = (var_value > msg["value"])
				">=":
					message_approved = (var_value >= msg["value"])
				"<":
					message_approved = (var_value < msg["value"])
				"<=":
					message_approved = (var_value <= msg["value"])
				_:
					message_approved = false
			if message_approved:
				result += msg["text"]
				
	# Find pause points
	var text_segments = result.split("<pause>")
	if (not text_segments is PoolStringArray) or (text_segments.size() <= 1):
		return [result, [1.0]] # 1.0 means one text with 100% of characters
	
	
	# Calculate total length of text
	# This text is potentially BB code, and therefore must be properly
	# parsed since text progression is based only on visible characters
	# For this we need a RichTextLabel to parse the BBCode, but it doesn't
	# have to be added anyhere
	var bbcode_parser = RichTextLabel.new()
	bbcode_parser.bbcode_enabled = true
	bbcode_parser.bbcode_text = ""
	var charcount_per_segment = []
	
	result = ""
	for item in text_segments:
		result += item
		bbcode_parser.bbcode_text += item
		var characters_up_to_here = bbcode_parser.text.length() #get_total_character_count()

		charcount_per_segment.append(characters_up_to_here)
	var total_characters = float(bbcode_parser.text.length())
	
	bbcode_parser.queue_free()

	var percentages = []
	for charcount in charcount_per_segment:
		percentages.append(float(charcount) / total_characters)
		
	return [result, percentages]


func parse(source_text: String, variables: Dictionary) -> Array:
	# variables is a Dictionary mapping "variable name" to a value (int, float or String)
	# result is an Array of text segments, where each segment is in the format
	#     segment = "String"    ---> means text is not conditional
	#     segment = {
	#         "condition": "variable name",
	#         "operator":  "=" | "!=" | ">" | ">=" | "<" | "<="
	#         "value":     <value> or "variable name",
	#         "text":      "text"
	#     }
	var result = []
	
	var s_tmp = source_text
	var tag_pos = s_tmp.find("{{if")
	while tag_pos > -1:
		var text_before = s_tmp.left(tag_pos)
		var text_after = s_tmp.right(tag_pos + tag_if_start_len)
		
		var tag_endpos = text_after.find(tag_if_end)
		
		# if we don't have a closing tag, this is malformatted syntax and we
		# just assume it's not meant to be parsed
		if tag_endpos == -1:
			break
			
		var text_cond = text_after.left(tag_endpos)
		text_after = text_after.right(tag_endpos + tag_if_end_len)
		
		# Now we have:
		# text_before -> text before the start tag
		# text_cond   -> everything between both tags (not including)
		# text_after  -> text after the end tag
		# both tags are not included anywhere
		
		
		result.append(_parse_condition(text_before, variables))
		result.append(_parse_condition(text_cond, variables))
		
		s_tmp = text_after
		tag_pos = s_tmp.find("{{if")
	
	result.append(_replace_variables(s_tmp, variables))
	
	return result




func _parse_condition(text: String, variables: Dictionary):
	# Returns a segment to be appended into the array in parse()
	var sep_pos = text.find(cond_sep)
	if sep_pos == -1:
		return text
		
	var text_before = text.left(sep_pos)
	var text_after = text.right(sep_pos + cond_sep_len)
	
	
	var cond_terms = text_before
	for op in operators:
		if op in text_before:
			# Split text (e.g. "variable >= 5")
			cond_terms = text_before.split(op, false, 2)
			if cond_terms.size() < 2:
				cond_terms = text_before
				break
				
			var value = cond_terms[1]
			if value.is_valid_integer():
				value = value.to_int()
			elif value.is_valid_float():
				value = value.to_float()
			
			return {
				"condition": cond_terms[0],
				"operator": op.strip_edges(),
				"value": value,
				"text": _replace_variables(text_after, variables),
			}
	
	# If no operator was found, cond_terms remains String
	
	
	# Boolean check (e.g. "{{if variable: Text here!}}
	if cond_terms is String:
		return {
			"condition": cond_terms,
			# Boolean check is implemented as "value != 0"
			"operator": "!=",
			"value": 0,
			"text": _replace_variables(text_after, variables),
		}
	
	else:
		return ""
	
func _replace_variables(text, variables):
	var s_tmp = text
	for var_name in variables:
		var var_tag = "<<%s>>" % var_name
		if var_tag in s_tmp:
			var var_value = variables[var_name]
			# Converts 15.0 into 15 for elegant printing
			if (var_value is float) and (var_value == floor(var_value)):
				var_value = str(int(var_value))
			else:
				var_value = str(var_value)
			
			s_tmp = s_tmp.replace(var_tag, var_value)
	return s_tmp
