tool
extends Resource
class_name DialogData

# This Resource is the top container of all the dialog data in the game
# It contains sheets, each sheet contains sequences, each sequence contains
# items and options
#
# DialogData
#   |- DialogSheetData              -> e.g. sheet_id = "npc1_shop"
#   |    |- DialogNodeData              -> e.g. ID=0 - START (options are inside)
#   |    |    |- DialogNodeItemData         -> e.g. welcome message
#   |    |    |- DialogNodeItemData         -> e.g. some condition
#   |    |    '- DialogNodeItemData         -> e.g. some effects
#   |    |- DialogNodeData              -> e.g. ID=1 (e.g. some item purchase)
#   |    |    |- DialogNodeItemData         -> e.g. thank you message
#   |    |    |- DialogNodeItemData         -> e.g. effect to buy item
#   |    |    ...
#   |    ...
#   |- DialogSheetData              -> e.g. dialog in some other context
#   ...

# Version number will be used in the future to convert databases to newer
# versions. This is necessary since conditions and effects are based on
# enums (and therefore int's) and adding new items might potentially break
# existing designs
export(float) var version = 1.0

# Dictionary keys are strings
# Dictionary values are DialogSheetData resource
export(Dictionary) var sheets = {}

