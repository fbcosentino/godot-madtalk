tool
extends Control
class_name DialogNodeItem_message

signal remove_requested(requester)
signal move_up_requested(requester)
signal move_down_requested(requester)

export(Resource) var data

onready var popup_menu = get_node("PopupMenu")
onready var dialog_edit = get_node("DialogEdit")
onready var edit_speaker_id = get_node("DialogEdit/Panel/SpeakerEdit")
onready var edit_speaker_var = get_node("DialogEdit/Panel/VariantEdit")
onready var edit_voiceclip = get_node("DialogEdit/Panel/VoiceEdit")
onready var edit_message = get_node("DialogEdit/Panel/MessageEdit")
onready var edit_preview = get_node("DialogEdit/Panel/PreviewBox/PreviewLabel")
onready var edit_previewtimer = get_node("DialogEdit/Panel/PreviewBox/PreviewTimer")
onready var edit_previewbg = get_node("DialogEdit/Panel/PreviewBox")
onready var edit_btn_hide_on_end = get_node("DialogEdit/Panel/BtnHideOnEnd")

onready var dialog_voiceclip = get_node("VoiceClipDialog")

enum PopupOptions {
	Edit,
	MoveUp,
	MoveDown,
	Remove
}


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

func update_from_data():
	if data:
		message_speakerlabel.text = data.message_speaker_id
		message_speakervarlabel.text = data.message_speaker_variant
		message_voicelabel.text = data.message_voice_clip
		message_msglabel.bbcode_text = data.message_text
		message_hideonendlabel.visible = (data.message_hide_on_end != 0)
		
		var variant_title = get_node("SpeakerVarLabel")
		variant_title.visible = (data.message_speaker_variant != "")
		
		var panel = get_node("Panel")
		if data.message_voice_clip != "":
			panel.margin_top = 40
		else:
			panel.margin_top = 28


func _on_DialogNodeItem_gui_input(event):
	if (event is InputEventMouseButton) and (event.pressed) and (event.button_index == BUTTON_RIGHT):
		var position = get_viewport().get_mouse_position()
		popup_menu.popup(Rect2(position,Vector2(10,10)))


func _on_PopupMenu_id_pressed(id):
	match id:
		PopupOptions.Edit:
			edit_speaker_id.text = data.message_speaker_id
			edit_speaker_var.text = data.message_speaker_variant
			edit_voiceclip.text = data.message_voice_clip
			edit_message.text = data.message_text
			edit_btn_hide_on_end.pressed = (data.message_hide_on_end != 0)
			_on_DialogEdit_PreviewTimer_timeout()
			dialog_edit.popup_centered()
			
		PopupOptions.MoveUp:
			emit_signal("move_up_requested", self)

		PopupOptions.MoveDown:
			emit_signal("move_down_requested", self)

		PopupOptions.Remove:
			emit_signal("remove_requested", self)



func _on_DialogEdit_BtnCancel_pressed():
	dialog_edit.hide()


func _on_DialogEdit_BtnSave_pressed():
	data.message_speaker_id = edit_speaker_id.text
	data.message_speaker_variant = edit_speaker_var.text
	data.message_voice_clip = edit_voiceclip.text
	data.message_text = edit_message.text
	data.message_hide_on_end = 1 if edit_btn_hide_on_end.pressed else 0
	update_from_data()
	dialog_edit.hide()



func _on_DialogEdit_PreviewTimer_timeout():
	edit_preview.bbcode_text = edit_message.text


func _on_DialogEdit_MessageEdit_text_changed():
	edit_previewtimer.start(1.0)


func _on_DialogEdit_BtnTextColor_color_changed(color):
	edit_preview.set("custom_colors/default_color", color)


func _on_DialogEdit_BtnBGColor_color_changed(color):
	edit_previewbg.color = color


func _on_BtnSelectClip_pressed():
	dialog_voiceclip.popup_centered()


func _on_FileDialog_voiceclip_selected(path):
	edit_voiceclip.text = path
