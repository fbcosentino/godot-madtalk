@tool
extends Control
class_name DialogNodeItem_message

signal remove_requested(requester)
signal move_up_requested(requester)
signal move_down_requested(requester)

@export var data: Resource

#@onready var popup_menu = get_node("PopupMenu")
#@onready var dialog_edit = get_node("DialogEdit")
var edit_speaker_id
var edit_speaker_var
var edit_voiceclip
var edit_message
var edit_preview
var edit_previewtimer
var edit_previewbg
var edit_btn_hide_on_end

#@onready var dialog_voiceclip = get_node("VoiceClipDialog")

var template_VoiceClipDialog: PackedScene = preload("res://addons/madtalk/components/popups/Messages_VoiceClipDialog.tscn")
var dialog_voiceclip: FileDialog

var template_DialogEdit: PackedScene = preload("res://addons/madtalk/components/popups/Messages_DialogEdit.tscn")
var dialog_edit: Window

var template_PopupMenu: PackedScene = preload("res://addons/madtalk/components/popups/DialogNodeItem_PopupMenu.tscn")
var popup_menu: PopupMenu

enum PopupOptions {
	Edit,
	MoveUp,
	MoveDown,
	Remove
}

@onready var box_height_margins = size.y - get_node("Panel/MessageLabel").size.y

var message_speakervarlabel = null
var message_speakerlabel = null
var message_voicelabel = null
var message_msglabel = null
var message_hideonendlabel = null



func _ready():
	if data:
		set_data(data)

func set_data(new_data):
	data = new_data
	message_speakerlabel = get_node("SpeakerNameLabel")
	message_speakervarlabel = get_node("SpeakerVariantLabel")
	message_voicelabel = get_node("VoiceFileLabel")
	message_msglabel = get_node("Panel/MessageLabel")
	message_hideonendlabel = get_node("HideOnEndLabel")
	update_from_data()

func update_height():
	if is_inside_tree():
		custom_minimum_size.y = min(
			box_height_margins + message_msglabel.get_content_height(),
			120
		)

func update_from_data():
	if data:
		message_speakerlabel.text = data.message_speaker_id
		message_speakervarlabel.text = data.message_speaker_variant
		message_voicelabel.text = data.message_voice_clip
		message_msglabel.text = data.message_text
		message_hideonendlabel.visible = (data.message_hide_on_end != 0)
		
		var variant_title = get_node("SpeakerVarLabel")
		variant_title.visible = (data.message_speaker_variant != "")
		
		var panel = get_node("Panel")
		if data.message_voice_clip != "":
			panel.offset_top = 40
		else:
			panel.offset_top = 28
		
		update_height()

func create_dialog_edit():
	if not dialog_edit:
		dialog_edit = template_DialogEdit.instantiate() as Window
		add_child(dialog_edit)
		dialog_edit.get_node("Panel/VoiceEdit/BtnSelectClip").pressed.connect(_on_BtnSelectClip_pressed)
		dialog_edit.get_node("Panel/MessageEdit").text_changed.connect(_on_DialogEdit_MessageEdit_text_changed)
		dialog_edit.get_node("Panel/BtnTextColor").color_changed.connect(_on_DialogEdit_BtnTextColor_color_changed)
		dialog_edit.get_node("Panel/BtnBGColor").color_changed.connect(_on_DialogEdit_BtnBGColor_color_changed)
		dialog_edit.get_node("Panel/PreviewBox/PreviewTimer").timeout.connect(_on_DialogEdit_PreviewTimer_timeout)
		dialog_edit.get_node("Panel/BottomBar/BtnSave").pressed.connect(_on_DialogEdit_BtnSave_pressed)
		dialog_edit.get_node("Panel/BottomBar/BtnCancel").pressed.connect(_on_DialogEdit_BtnCancel_pressed)

		edit_speaker_id = dialog_edit.get_node("Panel/SpeakerEdit")
		edit_speaker_var = dialog_edit.get_node("Panel/VariantEdit")
		edit_voiceclip = dialog_edit.get_node("Panel/VoiceEdit")
		edit_message = dialog_edit.get_node("Panel/MessageEdit")
		edit_preview = dialog_edit.get_node("Panel/PreviewBox/PreviewLabel")
		edit_previewtimer = dialog_edit.get_node("Panel/PreviewBox/PreviewTimer")
		edit_previewbg = dialog_edit.get_node("Panel/PreviewBox")
		edit_btn_hide_on_end = dialog_edit.get_node("Panel/BtnHideOnEnd")

func dispose_dialog_edit():
	if dialog_edit:
		dialog_edit.queue_free()
		dialog_edit = null

func create_voice_clip_dialog():
	if not dialog_voiceclip:
		dialog_voiceclip = template_VoiceClipDialog.instantiate()
		add_child(dialog_voiceclip)
		dialog_voiceclip.file_selected.connect(_on_FileDialog_voiceclip_selected)

func dispose_voice_clip_dialog():
	if dialog_voiceclip:
		dialog_voiceclip.queue_free()
		dialog_voiceclip = null


func create_popup_menu():
	if not popup_menu:
		popup_menu = template_PopupMenu.instantiate() as PopupMenu
		add_child(popup_menu)
		popup_menu.id_pressed.connect(_on_PopupMenu_id_pressed)

func dispose_popup_menu():
	if popup_menu:
		popup_menu.queue_free()
		popup_menu = null



func _on_DialogNodeItem_gui_input(event):
	if (event is InputEventMouseButton) and (event.pressed):
		if (event.button_index == MOUSE_BUTTON_LEFT) and event.double_click:
			_on_PopupMenu_id_pressed(PopupOptions.Edit)
			
		if (event.button_index == MOUSE_BUTTON_RIGHT):
			var cursor_position =  get_viewport().get_mouse_position() if get_viewport().gui_embed_subwindows else DisplayServer.mouse_get_position()
			create_popup_menu()
			popup_menu.popup(Rect2(cursor_position,Vector2(10,10)))



func _on_PopupMenu_id_pressed(id):
	dispose_popup_menu() # Handles null gracefully
	match id:
		PopupOptions.Edit:
			create_dialog_edit()
			edit_speaker_id.text = data.message_speaker_id
			edit_speaker_var.text = data.message_speaker_variant
			edit_voiceclip.text = data.message_voice_clip
			edit_message.text = data.message_text
			edit_btn_hide_on_end.button_pressed = (data.message_hide_on_end != 0)
			_on_DialogEdit_PreviewTimer_timeout()
			dialog_edit.popup_centered()
			
		PopupOptions.MoveUp:
			emit_signal("move_up_requested", self)

		PopupOptions.MoveDown:
			emit_signal("move_down_requested", self)

		PopupOptions.Remove:
			emit_signal("remove_requested", self)



func _on_DialogEdit_BtnCancel_pressed():
	dispose_dialog_edit()


func _on_DialogEdit_BtnSave_pressed():
	data.message_speaker_id = edit_speaker_id.text
	data.message_speaker_variant = edit_speaker_var.text
	data.message_voice_clip = edit_voiceclip.text
	data.message_text = edit_message.text
	data.message_hide_on_end = 1 if edit_btn_hide_on_end.button_pressed else 0
	update_from_data()
	dispose_dialog_edit()



func _on_DialogEdit_PreviewTimer_timeout():
	edit_preview.text = edit_message.text


func _on_DialogEdit_MessageEdit_text_changed():
	edit_previewtimer.start(1.0)


func _on_DialogEdit_BtnTextColor_color_changed(color):
	edit_preview.set("theme_override_colors/default_color", color)


func _on_DialogEdit_BtnBGColor_color_changed(color):
	edit_previewbg.color = color


func _on_BtnSelectClip_pressed():
	create_voice_clip_dialog()
	dialog_voiceclip.popup_centered()


func _on_FileDialog_voiceclip_selected(path):
	edit_voiceclip.text = path
	dispose_voice_clip_dialog()
