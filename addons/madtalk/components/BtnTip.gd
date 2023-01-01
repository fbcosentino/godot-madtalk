tool
extends Button

export(String) var tip_title = ""
export(String, MULTILINE) var tip_text = ""

onready var tip_dialog = get_node("TipDialog")


func _on_BtnTip_pressed():
	tip_dialog.window_title = tip_title
	tip_dialog.dialog_text = tip_text
	tip_dialog.popup_centered()
