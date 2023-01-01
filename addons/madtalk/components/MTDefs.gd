# This file is used for global defintions used across the MadTalk plugin
tool
class_name MTDefs
extends Reference

const WeekdayNames = {
	0: "Sunday",
	1: "Monday",
	2: "Tuesday",
	3: "Wednesday",
	4: "Thursday",
	5: "Friday",
	6: "Saturday"
}
const WeekdayNamesShort = {
	0: "Sun",
	1: "Mon",
	2: "Tue",
	3: "Wed",
	4: "Thu",
	5: "Fri",
	6: "Sat"
}

const MonthNames = {
	1: "January",
	2: "February",
	3: "March",
	4: "April",
	5: "May",
	6: "June",
	7: "July",
	8: "August",
	9: "September",
	10: "October",
	11: "November",
	12: "December"
}

const MonthNamesShort = {
	1: "Jan",
	2: "Feb",
	3: "Mar",
	4: "Apr",
	5: "May",
	6: "Jun",
	7: "Jul",
	8: "Aug",
	9: "Sep",
	10: "Oct",
	11: "Nov",
	12: "Dec"
}

func zero_pad(value, num_digits) -> String:
	var res = str(value)
	while res.length() < num_digits:
		res = "0"+res
	return res
	
func zero_unpad(value) -> String:
	if float(value) == 0:
		return "0"
	if float(value) == 1:
		return "1"
		
	if value.find('.') > -1:
		value = value.rstrip('0')
		if value.ends_with('.'):
			value += "0"
	value = value.lstrip('0')
	return value
	
func ShowFloat(value) -> String:
	return zero_unpad("%f" % float(value))

################################################################################
#    CONDITIONS
# ==============================================================================


enum ConditionTypes {    # arguments:
	Random,              # float percentage of change (0.0 - 100.0)
	VarBool,             # "var_name", bool value
	VarAtLeast,          # "var_name", float min value (inclusive) 
	VarUnder,            # "var_name", float max value (not inclusive)
	VarString,           # "var_name", string value (comparison)
	
	Time,                # time min, time max (inclusive, format "HH:mm")
	DayOfWeek,           # day min, day max (inclusive, int 0-6)
	DayOfMonth,          # day min, day max (inclusive, int 1-31)
	Date,                # date min, date max (inclusive, format DD/MM)
	
	ElapsedFromVar,      # variable name, number of minutes
	
	Custom               # custom ID, newline separated string list 
						 # (converted to array of string in callback)
}

const TYPE_RANDOM       = 1000
const TYPE_WEEKDAY      = 1001
const TYPE_CHECK        = 1002
const TYPE_STRING_SHORT = 1003

const ConditionData = {
	ConditionTypes.Random: {
		"num_args": 1,
		"default": [50],
		"data_types": [TYPE_REAL],
		"print_types": [TYPE_RANDOM],
		"description": "Random",
		"print_text": "Random chance %s %%",
		"print_short": "Random %s%%",
		"print_short_fail": "Random %s%%",
		"help": "Percentage of chance to continue (branching when fails), as float.\n\nExample: for 30% chance, use 30.0 (and not 0.3)."
	},
	ConditionTypes.VarBool: {
		"num_args": 2,
		"default": ["", 1],
		"data_types": [TYPE_STRING, TYPE_INT],
		"print_types": [TYPE_STRING, TYPE_CHECK],
		"description": "Variable check",
		"print_text": "Variable [color=yellow]%s[/color] is [color=aqua]%s[/color]",
		"print_short": "%s",
		"print_short_fail": "%s",
		"help": "Continues if variable is equal to a target boolean value, branching otherwise."
		
	},
	ConditionTypes.VarAtLeast: {
		"num_args": 2,
		"default": ["", 0],
		"data_types": [TYPE_STRING, TYPE_REAL],
		"print_types": [TYPE_STRING, TYPE_REAL],
		"description": "Variable at least",
		"print_text": "Variable [color=yellow]%s[/color] >= [color=aqua]%s[/color]",
		"print_short": "%s >= %s",
		"print_short_fail": "%s < %s",
		"help": "Continues if variable is equal or larger than a target value (as float), branching otherwise."
		
	},
	ConditionTypes.VarUnder: {
		"num_args": 2,
		"default": ["", 0],
		"data_types": [TYPE_STRING, TYPE_REAL],
		"print_types": [TYPE_STRING, TYPE_REAL],
		"description": "Variable under",
		"print_text": "Variable [color=yellow]%s[/color] < [color=aqua]%s[/color]",
		"print_short": "%s < %s",
		"print_short_fail": "%s >= %s",
		"help": "Continues if variable is lower (and not equal) than a target value (as float), branching otherwise."
	},
	
	ConditionTypes.VarString: {
		"num_args": 2,
		"default": ["",""],
		"data_types": [TYPE_STRING, TYPE_STRING],
		"print_types": [TYPE_STRING, TYPE_STRING],
		"description": "Variable equals",
		"print_text": "Variable [color=yellow]%s[/color] equals \"[color=aqua]%s[/color]\"",
		"print_short": "%s = \"%s\"",
		"print_short_fail": "%s != \"%s\"",
		"help": "Continues if a variable contains an exact string (case sensitive), branching otherwise."
	},
	
	ConditionTypes.Time: {
		"num_args": 2,
		"default": ["07:00","08:00"],
		"data_types": [TYPE_STRING, TYPE_STRING],
		"print_types": [TYPE_STRING, TYPE_STRING],
		"description": "Time range",
		"print_text": "Time between \"[color=blue]%s[/color]\" and [color=blue]%s[/color]",
		"print_short": "Time [%s - %s]",
		"print_short_fail": "Time not [%s - %s]",
		"help": "Continues if current in-game time is within a given range (inclusive), branching otherwise. Format is \"HH:mm\".\n\nExample, for an event valid in range [6 PM, 7 PM) (that is, including 6PM, not including 7 PM), use:\"18:00\" and \"18:59\"."
	},
	ConditionTypes.DayOfWeek: {
		"num_args": 2,
		"default": [1,5],
		"data_types": [TYPE_INT, TYPE_INT],
		"print_types": [TYPE_WEEKDAY, TYPE_WEEKDAY],
		"description": "Day of Week Range",
		"print_text": "Day of Week between \"[color=blue]%s[/color]\" and [color=blue]%s[/color]",
		"print_short": "W.Day [%s - %s]",
		"print_short_fail": "W.Day not [%s - %s]",
		"help": "Continues if current in-game day of week is within a given range (inclusive), branching otherwise." # Week starts on 0 = Sunday and goes to 6 = Saturday, but repeats indefinitely (2 = 9 = 16 = Tuesday). Week days:\n0 = Sunday\n1 = Monday\n2 = Tuesday\n3 = Wednesday\n4 = Thursday\n5 = Friday\n6 = Saturday\n7 = Also Sunday\n\nExample, for an event valid in week days, use:\n1\n5\n\nFor an event valid from Friday to Tuesday, use:\n5\n9"
	},
	ConditionTypes.DayOfMonth: {
		"num_args": 2,
		"default": [1,1],
		"data_types": [TYPE_INT, TYPE_INT],
		"print_types": [TYPE_INT, TYPE_INT],
		"description": "Day of Month Range",
		"print_text": "Day of Month between \"[color=blue]%s[/color]\" and [color=blue]%s[/color]",
		"print_short": "Day [%s - %s]",
		"print_short_fail": "Day not [%s - %s]",
		"help": "Continues if current in-game day of month is within a given range (inclusive), branching otherwise." 
	},
	ConditionTypes.Date: {
		"num_args": 2,
		"default": ["01/01","01/01"],
		"data_types": [TYPE_STRING, TYPE_STRING],
		"print_types": [TYPE_STRING, TYPE_STRING],
		"description": "Date range",
		"print_text": "Date between \"[color=blue]%s[/color]\" and [color=blue]%s[/color]",
		"print_short": "Date [%s - %s]",
		"print_short_fail": "Date not [%s - %s]",
		"help": "Continues if current in-game date is within a given range (inclusive), branching otherwise. Does not include the year, which means the range is valid in any year of in-game date.\n\nFormat \"DD/MM\". Example, for an event taking place between 25 Feb and 02 Mar (inclusive), use \"25/02\" and \"02/03\"" 
	},
	
	ConditionTypes.ElapsedFromVar: {
		"num_args": 2,
		"default": [0, ""],
		"data_types": [TYPE_REAL, TYPE_STRING],
		"print_types": [TYPE_REAL, TYPE_STRING],
		"description": "Minutes elapsed since variable",
		"print_text": "Elapsed [color=blue]%s[/color] minutes after time stamped in variable [color=yellow]%s[/color]",
		"print_short": "%s mins after var %s",
		"print_short_fail": "Until %s mins after var %s",
		"help": "Continues if current in-game time is equal or later than a given number of minutes, when compared to a variable, branching otherwise. Used in conjunction with timestamping effects.",
	},
	
	ConditionTypes.Custom: {
		"num_args": 2,
		"default": ["",""],
		"data_types": [TYPE_STRING, TYPE_STRING],
		"print_types": [TYPE_STRING],
		"description": "Custom condition",
		"print_text": "Custom condition [color=yellow]%s[/color] successful",
		"print_short": "%s successful",
		"print_short_fail": "%s fails",
		"help": "Continues if a custom condition (implemented in user code) evaluates as true, branching otherwise.\n\nA custom ID is passed to the callback (to be used as condition type, e.g. \"combat\", \"inventory\", \"char\", or anything representable with a single string), as well as a list of strings separated here by line breaks (to be used as general purpose fixed data, e.g. item id, monster id, etc). The list of strings will be passed to the callback as Array of Strings.\n\nThe callback is whatever is connected to the \"evaluate_custom_condition\" signal in the MadTalk node. If more than one method is connected, only the first one is used.",
	}
}


	
func Condition_PrintFail(condition: int, values: Array) -> String:
	var text_items = []

	# Bool condition is an exception
	if condition == ConditionTypes.VarBool:
		# Bool has 2 arguments: variable name and a boolean value represented as
		# float (where anything non-zero is true)
		# however the boolean value is not printed. Instead the word "not" is
		# prepended. Hence the separated logic
		if (values[1] == 0):
			# A successful check is false, therefore the fail message is true
			text_items.append(values[0])
		else:
			# A successful check is true, therefore the fail message is false
			text_items.append("not "+values[0])
			

	else:
		var types = ConditionData[condition]["print_types"]
		for i in range(types.size()):
			match types[i]:
				TYPE_RANDOM:
					text_items.append(str(100.0 - values[i]))
				TYPE_INT:
					text_items.append(str(values[i]))
				TYPE_REAL:
					text_items.append(ShowFloat(values[i]))
				TYPE_WEEKDAY:
					var wday = values[i]
					while wday > 6:
						wday -= 7
					text_items.append(WeekdayNamesShort[wday])
				TYPE_STRING:
					text_items.append(values[i])
					
					
					
	return ConditionData[condition]["print_short_fail"] % text_items
			
################################################################################
#    EFFECTS
# ==============================================================================


enum EffectTypes {     # arguments:
	ChangeSheet,       # "sheet_id" sequence_id=0
	SetVariable,       # "var_name", value
	AddVariable,       # "var_name" value
	RandomizeVariable, # "var_name", value_min, value_max
	StampTime,         # "var_name"
	SpendMinutes,      # value_minutes
	SpendDays,         # value_days
	SkipToTime,        # value_time
	SkipToWeekDay,     # value_weekday
	WaitAnim,          # Animation name
	Custom             # "effect_id", newline separated string list 
					   # (converted to array of string in callback)
}

const EffectData = {
	EffectTypes.ChangeSheet: {
		"num_args": 2,
		"default": ["",0],
		"data_types": [TYPE_STRING, TYPE_INT],
		"print_types": [TYPE_STRING, TYPE_INT],
		"description": "Change Sheet",
		"print_text": "Change dialog to sheet \"%s\", sequence ID %s",
		"print_short": "Sheet %s (ID %s)",
		"help": "Abandons this dialog (items in this sequence below this effect are not executed) and runs dialog in another sheet.\n\nDefault starting point is ID 0, but a custom ID can be set instead."
	},
	EffectTypes.SetVariable: {
		"num_args": 2,
		"default": ["",0.0],
		"data_types": [TYPE_STRING, TYPE_REAL],
		"print_types": [TYPE_STRING, TYPE_REAL],
		"description": "Set Variable",
		"print_text": "Set the variable %s to the value %s",
		"print_short": "Set %s = %s",
		"help": "Sets the internal variable to a predefined value. If you want to use it in true/false checks, use zero for false, any other number for true.\n\nThis variable is stored inside MadTalk subsystem, and is not a GDScript variable. (It can be accessed from GDScript if required.)"
	},
	EffectTypes.AddVariable: {
		"num_args": 2,
		"default": ["",0.0],
		"data_types": [TYPE_STRING, TYPE_REAL],
		"print_types": [TYPE_STRING, TYPE_REAL],
		"description": "Add Value to Variable",
		"print_text": "Add to the variable %s a value of %s",
		"print_short": "To %s, add %s",
		"help": "Adds to the internal variable a given value.\n\nThis can be used to make counters (e.g. how many times the player has spoken to this NPC), to subtract money (e.g. in shops) using negative values, etc.\n\nThis variable is stored inside MadTalk subsystem, and is not a GDScript variable. (It can be accessed from GDScript if required.)"
	},
	EffectTypes.RandomizeVariable: {
		"num_args": 3,
		"default": ["",0.0, 1.0],
		"data_types": [TYPE_STRING, TYPE_REAL, TYPE_REAL],
		"print_types": [TYPE_STRING, TYPE_REAL, TYPE_REAL],
		"description": "Randomizes Variable",
		"print_text": "Set the variable %s to a random value between %s and %s",
		"print_short": "Set %s = rand(%s, %s)",
		"help": "Sets the internal variable to a random value, withing the given range (inclusive).\n\nThis can be used to generate random scenarios which will remain the same during the gameplay until randomized again (unlike a random condition, which is randomized again every time the sequence runs and the result is not accessible anywhere else).\n\nThis variable is stored inside MadTalk subsystem, and is not a GDScript variable. (It can be accessed from GDScript if required.)"
	},
	EffectTypes.StampTime: {
		"num_args": 1,
		"default": [""],
		"data_types": [TYPE_STRING],
		"print_types": [TYPE_STRING],
		"description": "Stamp Current Time to Variable",
		"print_text": "Set the variable %s to current timestamp",
		"print_short": "Var %s = timestamp",
		"help": "Stores the current in-game timestamp into the internal variable.\n\nThis should be used in conjunction with the timestamp condition to make dialog behavior dependent on a time window since this effect (e.g. a branch is only accessible during some minutes after talking to some NPC).\n\nThis variable is stored inside MadTalk subsystem as number of in-game seconds elapsed since start of gameplay, and is not a GDScript variable. (It can be accessed from GDScript if required.)"
	},
	EffectTypes.SpendMinutes: {
		"num_args": 1,
		"default": [0],
		"data_types": [TYPE_REAL],
		"print_types": [TYPE_REAL],
		"description": "Advance Minutes in In-Game Time",
		"print_text": "Add %s minutes to current in-game time",
		"print_short": "Spend %s minutes",
		"help": "Adds the specified number of minutes to the in-game time variable. Use this in conjunction with time-checking conditions to cause events to only happen in certain time windows (e.g. a shop keeper only sells during the day on business days)."
	},
	EffectTypes.SpendDays: {
		"num_args": 1,
		"default": [0],
		"data_types": [TYPE_REAL],
		"print_types": [TYPE_REAL],
		"description": "Advance Days in In-Game Time",
		"print_text": "Add %s days to current in-game time",
		"print_short": "Spend %s day(s)",
		"help": "Adds the specified number of days to the in-game time variable. Use this in conjunction with time-checking conditions to cause events to only happen in certain date ranges (e.g. an event is only available during weekends)."
	},

	EffectTypes.SkipToTime: {
		"num_args": 1,
		"default": ["07:00"],
		"data_types": [TYPE_STRING],
		"print_types": [TYPE_STRING],
		"description": "Skip until a certain time",
		"print_text": "Advances time until in-game time is %s",
		"print_short": "Skip to %s",
		"help": "Spends time until the next time the in-game time is at the specified value (in 24h format, e.g. \"07:00\").\n\nExample: if current in-game time is Wed 18:35, an effect to skip to \"07:00\" will spend time until the in-game time is at Thu 07:00.",
	},

	EffectTypes.SkipToWeekDay: {
		"num_args": 1,
		"default": [0],
		"data_types": [TYPE_INT],
		"print_types": [TYPE_WEEKDAY],
		"description": "Skip time until a certain weekday",
		"print_text": "Advances time until in-game weekday is %s midnight",
		"print_short": "Skip to %s 00:00",
		"help": "Spends time until the next day the in-game time is at the specified value. Time will be set to midnight (00:00) at the beginning of the given day."
	},

	EffectTypes.WaitAnim: {
		"num_args": 1,
		"default": [""],
		"data_types": [TYPE_STRING],
		"print_types": [TYPE_STRING],
		"description": "Play and wait for an animation",
		"print_text": "Play animation \"%s\" and wait for it to finish",
		"print_short": "Play \"%s\"",
		"help": "Plays the specified animation in the AnimationPlayer set in the MadTalk node, and holds the dialog until it completes."
	},
	EffectTypes.Custom: {
		"num_args": 2,
		"default": ["",""],
		"data_types": [TYPE_STRING, TYPE_STRING],
		"print_types": [TYPE_STRING, TYPE_STRING_SHORT],
		"description": "Custom Effect",
		"print_text": "Custom effect [color=yellow]%s[/color] (data: %s)",
		"print_short": "%s (%s)",
		"help": "Calls a custom effect (implemented in user code).\n\nA custom ID is passed to the callback (to be used as effect type, e.g. \"give_item\", \"teleport_player\", \"game_over\", or anything representable with a single string), as well as a list of strings separated here by line breaks (to be used as general purpose fixed data, e.g. item id, room id, etc). The list of strings will be passed to the callback as Array of Strings."
	}
}

func Effect_PrintShort(effect: int, values: Array) -> String:
	var text_items = []
	var types = EffectData[effect]["print_types"]
	for i in range(types.size()):
		match types[i]:
			TYPE_RANDOM:
				text_items.append(str(100.0 - values[i]))
			TYPE_INT:
				text_items.append(str(values[i]))
			TYPE_REAL:
				text_items.append(ShowFloat(values[i]))
			TYPE_WEEKDAY:
				var wday = values[i]
				while wday > 6:
					wday -= 7
				text_items.append(WeekdayNamesShort[wday])
			TYPE_STRING:
				text_items.append(values[i])
			TYPE_STRING_SHORT:
				var text = values[i].replace("\n", " ")
				if text.length() > 20:
					text = text.left(17) + "..."
				text_items.append(text)
				
				
	return EffectData[effect]["print_short"] % text_items

func debug_resource(res: Resource, indent = ""):
	if res == null:
		return
		
	var list = res.get_property_list()
	print(indent+"> %s - %s" % [str(res),str(res.resource_path)])
	for item in list:
		match item.type:
			TYPE_INT:
				print(indent+"  %s = %s" % [str(item.name), str(res[item.name])])
			TYPE_STRING:
				if not item.name in ["resource_name","resource_path"]:
					print(indent+"  %s = \"%s\"" % [str(item.name), str(res[item.name])])
			TYPE_ARRAY:
				print(indent+"  %s:" % str(item.name))
				for a_item in res[item.name]:
					#print("    %s" % str(a_item))
					debug_resource(a_item, indent+"    ")
			TYPE_DICTIONARY:
				print(indent+"  %s:" % str(item.name))
				for a_item in res[item.name]:
					print("    [%s]:" % str(a_item))
					debug_resource(res[item.name][a_item], indent+"      ")
