@tool
extends Resource
class_name DialogNodeData

# This Resource refers to an entire dialog sequence (graphical node),
# and does not include sub-items
# It is used to define sequence ID and option buttons

@export var sequence_id: int = 0
@export var position: Vector2 = Vector2(0,0)
@export var comment: String = ""

@export var items = [] # (Array, Resource)
@export var options = [] # (Array, Resource)

@export var continue_sequence_id: int = -1
@export var continue_port_index: int = -1
