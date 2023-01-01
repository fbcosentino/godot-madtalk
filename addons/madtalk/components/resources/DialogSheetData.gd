tool
extends Resource
class_name DialogSheetData

# This resource contains a sheet of dialog, consisting of interconnected nodes
# Each node is a DialogNodeData
#
# E.g.
#  DialogSheetData              -> e.g. sheet_id = "npc1_shop"
#    |- DialogNodeData              -> e.g. ID=0 - START (options are inside)
#    |    |- DialogNodeItemData         -> e.g. welcome message
#    |    |- DialogNodeItemData         -> e.g. some condition
#    |    '- DialogNodeItemData         -> e.g. some effects
#    |- DialogNodeData              -> e.g. ID=1 (e.g. some item purchase)
#    |    |- DialogNodeItemData         -> e.g. thank you message
#    |    |- DialogNodeItemData         -> e.g. effect to buy item
#    |    ...

export(String) var sheet_id = ""
export(String) var sheet_description = ""
export(int) var next_sequence_id = 0
export(Array, Resource) var nodes = [] # "nodes" as in dialog node, not Godot Node
