extends EditorInspectorPlugin

func can_handle(object):
	# We don't know the class of the node since it will be defined by user
	# so we just accept anything
	return true
	
func parse_property(object, type, path, hint, hint_text, usage):
	# This component is used in String fields starting with "madtalk_sheet_id"
	if (type == TYPE_STRING) and (path.begins_with("madtalk_sheet_id")):
		# Register *an instance* of the custom property editor that we'll define next.
		add_property_editor(path, InspectorPluginSheetIDFieldItem.new())
		# We return `true` to notify the inspector that we'll be handling
		# this property, so it doesn't need to parse other plugins
		# (including built-in ones) for an appropriate editor.
		return true
	else:
		return false
