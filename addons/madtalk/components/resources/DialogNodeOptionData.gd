tool
extends Resource
class_name DialogNodeOptionData

# Text shown in the button
export(String) var text = ""
# To what sequence id this option is connected 
export(int) var connected_to_id = -1
# Holds the GraphNode port index for this item
var port_index : int = -1
# If option visibility is conditional
export(bool) var is_conditional = false
# Variable name
export(String) var condition_variable = ""
# Condition operator ("=", "!=", ">", "<", ">=", "<=")
# This version keeps it as string for code simplicity
export(String) var condition_operator = "="
# Variable value - if the string is a valid number, value is the number itself
# otherwise (if it's a text String) it's the variable name to compare to
export(String) var condition_value = ""
