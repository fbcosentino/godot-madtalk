@tool
class_name MadTalkImportExport
extends Node

const IMP_EXP_PATH := "res://addons/madtalk/importers/"

var importers_list := {}
var exporters_list := {}

func refresh_list_importers():
	importers_list.clear()
	exporters_list.clear()
	
	var dir = DirAccess.open(IMP_EXP_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if (not dir.current_is_dir()) and (file_name.ends_with(".gd")):
				var full_path: String = IMP_EXP_PATH + file_name
				var script_instance = load(full_path).new()
				
				if file_name.begins_with("imp_"):
					importers_list[full_path] = script_instance.name
				elif file_name.begins_with("exp_"):
					exporters_list[full_path] = script_instance.name
				
			
			else:
				pass # Subdirs are ignored
			
			file_name = dir.get_next()
	else:
		print("Error refreshing importers/exporters")
