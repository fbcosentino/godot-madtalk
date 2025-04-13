@tool
# MadTalk Godot Plugin by Fernando Cosentino
# https://github.com/fbcosentino/godot-madtalk
#
# License: MIT
# (But if you can be so kind as to mention the original in your Readme in case
# you base any work on this, I would be very glad :] )

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
	add_autoload_singleton("MadTalkGlobals", "res://addons/madtalk/runtime/MadTalkGlobals.tscn")
	
	add_inspector_plugin(sheet_id_inspector_editor)
	
	main_panel = MadTalkEditor_scene.instantiate()
	
	get_editor_interface().get_editor_main_screen().add_child(main_panel)
	main_panel.setup()
	_make_visible(false)
	
	var mt_ie := MadTalkImportExport.new()
	mt_ie.refresh_list_importers()
	
	print("Importers:")
	print(JSON.stringify(mt_ie.importers_list, "    "))
	
	print("Exporters:")
	print(JSON.stringify(mt_ie.exporters_list, "    "))
	
	var dialog_data = load("res://addons/madtalk/runtime/madtalk_data.tres")
	var sheet_data = dialog_data.sheets["localized"]
	var exporter = load(mt_ie.exporters_list.keys()[0]).new()
	print(exporter.export(sheet_data))
	#print(exporter.export(sheet_data, ["pt", "jp"]))
	
	var s := """[Sheet: localized]
	Abc

[Sequence]
alice(smirk): Well well well
bob: Water we have here?

[Sequence: Resource_ml5yl]
<Resource_rlxbw> narrator: -=-=-
Hello! Welcome to the localized example!
Warning: the next message will play an audio clip.
-=-=-
{es}: -=-=-
¡Hola! ¡Bienvenido al ejemplo localizado!
Advertencia: el siguiente mensaje reproducirá un clip de audio.
-=-=-
{pt}: -=-=-
Olá! Seja bem vindo ao teste localizado!
Aviso: a próxima mensagem reproduzirá um clipe de áudio.
-=-=-

<Resource_quvr4> narrator(humor): You are now seeing messages in English, because either this is your system language, or because your language is not included in this test.
{es}: Ahora estás viendo los mensajes en español, porque este es el idioma de tu sistema.
{pt}: Você está agora vendo mensagens em Português, porque esse é o idioma do seu sistema.

<Resource_w6lj3> : Thank you for playing this test!
{es}: ¡Gracias por jugar esta prueba!
{pt}: Obrigado por jogar esse teste!

John: Message said by John!
Peter: And well, this one is by Peter =]
{pt}: Esta é do Peter!

[Sequence]
alice: I don't know what to write here...

bob(bobbing): -=-=-
		Why not... 
		a multiline one?
-=-=-

alice: Nah.
"""
	var importer = load(mt_ie.importers_list.keys()[0]).new()
	print( JSON.stringify( importer.import(dialog_data, s) , "    ") )


func _exit_tree():
	remove_inspector_plugin(sheet_id_inspector_editor)
	
	if main_panel:
		main_panel.queue_free()
	
	remove_autoload_singleton("MadTalkGlobals")

func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel:
		main_panel.visible = visible
		main_panel.call_deferred("reopen_current_sheet")


func _get_plugin_name():
	return "Dialog"


func _get_plugin_icon():
	return viewport_icon#get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")

func _save_external_data():
	if main_panel:
		main_panel._save_external_data()
