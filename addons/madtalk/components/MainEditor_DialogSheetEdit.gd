tool
extends WindowDialog

signal sheet_saved(sheet_id, sheet_desc, delete_word)

onready var sheet_id_edit = get_node("Panel/SheetIDEdit")
onready var sheet_desc_edit = get_node("Panel/SheedDescEdit")
onready var sheet_delete_word = get_node("Panel/SheetDeleteEdit")

func _ready():
	# Hides the close button
	get_close_button().hide()


func open(data):
	sheet_id_edit.text = data.sheet_id
	sheet_desc_edit.text = data.sheet_description
	sheet_delete_word.text = ""
	popup_centered()


func _on_BtnSave_pressed():
	# We do not hide the window here as the parent takes care of it
	# since a renaming collision raises a warning instead of closing it
	emit_signal("sheet_saved", sheet_id_edit.text, sheet_desc_edit.text, sheet_delete_word.text)


func _on_BtnCancel_pressed():
	hide()
