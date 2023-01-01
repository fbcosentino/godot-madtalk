# MadTalk Godot Plugin by Fernando Cosentino
# https://github.com/fbcosentino/godot-madtalk
#
# License: MIT
# (But if you can be so kind as to mention the original in your Readme in case
# you base any work on this, I would be very glad :] )

tool
extends EditorPlugin

# ==============================================================================
# GODOT PLUGIN INTEGRATION
# ------------------------------------------------------------------------------

# Scened to be instanced
var MadTalkEditor_scene = preload("res://addons/madtalk/madtalk_editor.tscn")

# Resources
var viewport_icon = preload("res://addons/madtalk/images/madtalk_viewport_icon.png")

# Inspector sheet_id editor
var sheet_id_inspector_editor = preload("res://addons/madtalk/components/InspectorPluginSheetIDField.gd").new()

# Holds the main panel node in the viewport
var main_panel

func _enter_tree():
	add_inspector_plugin(sheet_id_inspector_editor)
	
	main_panel = MadTalkEditor_scene.instance()
	
	get_editor_interface().get_editor_viewport().add_child(main_panel)
	make_visible(false)


func _exit_tree():
	remove_inspector_plugin(sheet_id_inspector_editor)
	
	if main_panel:
		main_panel.queue_free()

func has_main_screen():
	return true


func make_visible(visible):
	if main_panel:
		main_panel.visible = visible


func get_plugin_name():
	return "Dialog"


func get_plugin_icon():
	return viewport_icon#get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")

func save_external_data():
	if main_panel:
		main_panel.save_external_data()
