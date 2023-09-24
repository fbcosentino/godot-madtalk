@tool
extends Resource
class_name DialogNodeItemData

# This resource is variant and is shared across all node item types
# Properties which are not applicable are just ignored

enum ItemTypes {
	Message,            # Basic item, displays a dialog message
	Condition,          # Condition to branch out
	Effect              # Effect causing a change to some in-game state
}

# Type of item (message, condition or effect)
@export var item_type: ItemTypes = ItemTypes.Message
# To what sequence id this item is connected (only valid for condition)
@export var connected_to_id: int = -1
# Holds the GraphNode port index for this item
var port_index : int = -1

# ==============================================================================
# USED BY TYPE: MESSAGE

@export var message_speaker_id: String = ""
@export var message_speaker_variant: String = ""
@export var message_voice_clip: String = "" # Default locale
@export_multiline var message_text := "" # default locale
@export var message_hide_on_end: int = 0

# ==============================================================================
# USED BY TYPE: CONDITION

@export var condition_type := MTDefs.ConditionTypes.Custom # (MTDefs.ConditionTypes)
@export var condition_values: Array = []

# ==============================================================================
# USED BY TYPE: EFFECT

@export var effect_type := MTDefs.EffectTypes.Custom # (MTDefs.EffectTypes)
@export var effect_values: Array = []

