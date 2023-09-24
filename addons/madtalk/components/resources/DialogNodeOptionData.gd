@tool
extends Resource
class_name DialogNodeOptionData

# Text shown in the button
@export var text: String = ""
# To what sequence id this option is connected 
@export var connected_to_id: int = -1
# Holds the GraphNode port index for this item
var port_index : int = -1
# If option visibility is conditional
@export var is_conditional: bool = false
# Variable name
@export var condition_variable: String = ""
# Condition operator ("=", "!=", ">", "<", ">=", "<=")
# This version keeps it as string for code simplicity
@export var condition_operator: String = "="
# Variable value - if the string is a valid number, value is the number itself
# otherwise (if it's a text String) it's the variable name to compare to
@export var condition_value: String = ""
