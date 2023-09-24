@tool
extends Panel


@export var SizeClosed: int = 24

@onready var content = get_node_or_null("Content")

func _on_BtnTogglePanel_pressed():
	if (size.y == SizeClosed):
		# Open:
		anchor_bottom = 1
		offset_bottom = -16
		if content:
			content.show()
	else:
		# Close:
		anchor_bottom = 0
		size.y = SizeClosed
		if content:
			content.hide()
		
