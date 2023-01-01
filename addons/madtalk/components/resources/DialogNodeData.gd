tool
extends Resource
class_name DialogNodeData

# This Resource refers to an entire dialog sequence (graphical node),
# and does not include sub-items
# It is used to define sequence ID and option buttons

export(int) var sequence_id = 0
export(Vector2) var position = Vector2(0,0)
export(String) var comment = ""

export(Array, Resource) var items = []
export(Array, Resource) var options = []

export(int) var continue_sequence_id = -1
export(int) var continue_port_index = -1
