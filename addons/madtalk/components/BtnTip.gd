@tool
extends Button

@export var tip_title: String = ""
@export_multiline var tip_text: String = "" # (String, MULTILINE)

@onready var tip_dialog = get_node("TipDialog")


func _on_BtnTip_pressed():
	tip_dialog.title = tip_title
	tip_dialog.dialog_text = tip_text
	tip_dialog.popup_centered()
