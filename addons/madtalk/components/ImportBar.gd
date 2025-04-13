@tool
extends Panel


@export var SizeClosed: int = 24
@export var SizeOpen: int = 200

@onready var content = get_node_or_null("Content")

func _ready():
	size.y = SizeClosed
	if content:
		content.hide()

func _on_BtnTogglePanel_pressed():
	if (size.y == SizeClosed):
		# Open:
		size.y = SizeOpen
		if content:
			content.show()
	else:
		# Close:
		size.y = SizeClosed
		if content:
			content.hide()
		
