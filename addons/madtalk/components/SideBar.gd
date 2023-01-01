tool
extends Panel


export(int) var SizeClosed = 24

onready var content = get_node_or_null("Content")

func _on_BtnTogglePanel_pressed():
	if (rect_size.y == SizeClosed):
		# Open:
		anchor_bottom = 1
		margin_bottom = -16
		if content:
			content.show()
	else:
		# Close:
		anchor_bottom = 0
		rect_size.y = SizeClosed
		if content:
			content.hide()
		
