extends Node


var is_during_dialog = false
var is_during_cinematic = false 

var variables = {
}

var time = 0
var gametime_offset = 0
var gametime_year = 1

onready var gametime = epoch_to_game_time(time)

func set_variable(var_name: String, var_value) -> void:
	variables[var_name] = var_value
	
func get_variable(var_name: String, default = 0):
	if var_name in variables:
		return variables[var_name]
	else:
		return default

#
#func zero_pad(value, num_digits) -> String:
#	var res = str(value)
#	while res.length() < num_digits:
#		res = "0"+res
#	return res


# ==============================================================================
# TIME

func set_game_year(year: int) -> void:
	gametime_year = year
	var dt = {
		"year": year,
		"month": 1,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	gametime_offset = OS.get_unix_time_from_datetime(dt)
	gametime = epoch_to_game_time(time)

##
# Returns datetime in game reference (that is,
# start of game is 01/01/0001 00:00:00)
# Can be seen as "elapsed gameplay time"
func epoch_to_game_time(epoch_time: int) -> Dictionary:
	# Date time dictionary has the format:
	# {
	#   "year": ...,
	#   "month": ...,
	#   "day": ...,
	#   "weekday": ...,
	#   "hour": ...,
	#   "minute": ...,
	#   "second": ...
	# }
	# Custom values added here are:
	#  "time":    String hour/minute in format HH:MM
	#  "date":    String day/month in format DD/MM
	#  "date_inv": String day/month in format MM/DD
	
	var dt = OS.get_datetime_from_unix_time(gametime_offset + epoch_time)
	dt["year"] -= gametime_year-1 # year - 1, so starts at year 1
	dt["time"] = "%02d:%02d" % [dt["hour"], dt["minute"]]
	dt["date"] = "%02d/%02d" % [dt["day"], dt["month"]]
	dt["date_inv"] = "%02d/%02d" % [dt["month"], dt["day"]]
	dt["weekday_name"] = MTDefs.WeekdayNames[dt["weekday"]]
	dt["wday_name"] = MTDefs.WeekdayNamesShort[dt["weekday"]]
	return dt

# Converts day, month, year to unix epoch time
func game_time_to_epoch(p_gametime: Dictionary) -> int:
	p_gametime["year"] += gametime_year-1 # Year 1 is base,
	return OS.get_unix_time_from_datetime(p_gametime) - gametime_offset

func update_gametime_dict():
	gametime = epoch_to_game_time(time)


# Converts day, month, year to unix epoch time
func date_to_int(day: int, month: int, year: int) -> int:
	return game_time_to_epoch({
		"year": year, "month": month, "day": day,
		"hour": 0, "minute": 0, "second": 0
	})
	
# Converts hour, minute to float fractional hour
# Example: 2, 30 becomes 2.5
func time_to_float(hour: int, minute: int) -> float:
	return float(hour) + float(minute)/60.0

func time_to_string(var epoch_time: int, simplified: bool = true) -> String:
	# Date time dictionary has the format:
	# {
	#   "year": ...,
	#   "month": ...,
	#   "day": ...,
	#   "weekday": ...,
	#   "hour": ...,
	#   "minute": ...,
	#   "second": ...
	# }
	var dt = epoch_to_game_time(epoch_time)
	var res = ""
	
	# Simplified version is Weekday HH:MM
	if (simplified):
		res = MTDefs.WeekdayNames[dt['weekday']].left(3)
		res += " %02d:%02d" % [dt['hour'], dt['minute']]
	
	# Non-simplified is Weekday, DD of MonthName HH:MM
	else:
		res = MTDefs.WeekdayNames[dt['weekday']]
		res += ", "+str(dt['day'])
		res += " "+MTDefs.MonthNames[dt['month']]
		res += " %02d:%02d" % [dt['hour'], dt['minute']]

	return res
	

func split_time(value: String) -> Array:
	var nums_psa = str(value).split(':')
	while nums_psa.size() < 2:
		nums_psa.append(0)
	var nums = [int(nums_psa[0]), int(nums_psa[1])]
	if (nums[0] < 0) or (nums[0] > 23):
		nums[0] = 0
	if (nums[1] < 0) or (nums[1] > 59):
		nums[1] = 0
	return [nums[0], nums[1]]

func split_date(value: String) -> Array:
	var nums_psa = str(value).split('/')
	while nums_psa.size() < 2:
		nums_psa.append(1)
	var nums = [int(nums_psa[0]), int(nums_psa[1])]
	if (nums[0] < 1) or (nums[0] > 31):
		nums[0] = 1
	if (nums[1] < 1) or (nums[1] > 12):
		nums[1] = 1
	return [nums[0], nums[1]]

func print_date(value: String) -> String:
	var nums = split_date(value)
	var day = "%02d" % nums[0]
	var month = MTDefs.MonthNames[nums[1]].left(3)
	return day+' '+month
	
func print_weekday(value):
	while value > 6:
		value -= 7
	return MTDefs.WeekdayNames[value]

func split_string_autodetect_rn(value: String) -> Array:
	var result = []
	
	value = str(value)
	
	if "\r\n" in value:
		# Windows style
		result = value.split("\r\n")
	elif "\r" in value:
		# MacOS style
		result = value.split("\r")
	else:
		# Unix style
		result = value.split("\n")
		
	return result
	
	
func next_time_at_time(time_value: String) -> int:
	var asked_time = split_time(time_value)

	# We calculate epoch time value for the requested hour happening today
	# if we are before this time, this is what we want
	var ingame_time_as_today = game_time_to_epoch({
		"year": gametime["year"],
		"month": gametime["month"],
		"day": gametime["day"],
		"hour": asked_time[0],
		"minute": asked_time[1],
		"second": 0
	})
	
	if time <= ingame_time_as_today:
		return ingame_time_as_today
	
	# If we are after this time, we want the same time but tomorrow
	# so we add 24 hours
	else:
		return ingame_time_as_today + 24*60*60 # seconds

func next_time_at_weekday(weekday: int) -> int:
	# First we find the weekday delta handling when the requested weekday
	# is lower (or equal) than current one
	var asked_weekday = weekday if weekday > gametime["weekday"] else weekday + 7
	var weekday_delta = asked_weekday - gametime["weekday"]

	# Find time for midnight of today
	var ingame_midnight_today = game_time_to_epoch({
		"year": gametime["year"],
		"month": gametime["month"],
		"day": gametime["day"],
		"hour": 0,
		"minute": 0,
		"second": 0
	})
	# Finally we just offset the weekday_delta days into the future
	return ingame_midnight_today + weekday_delta*24*60*60 # seconds


func export_game_data() -> Dictionary:
	var result = {
		"time": time,
		"gametime_offset": gametime_offset,
		"gametime_year": gametime_year,
		"variables": variables
	}
	return result
	
func import_game_data(data: Dictionary) -> void:
	if ("time" in data):
		time = int(round(float(data["time"])))
	if ("gametime_offset" in data):
		gametime_offset = int(round(float(data["gametime_offset"])))
	if ("gametime_year" in data):
		gametime_year = int(round(float(data["gametime_year"])))
	
	variables.clear()
	for variable_name in data["variables"]:
		if variable_name is String:
			var value = data["variables"][variable_name]
			if typeof(value) in [TYPE_INT, TYPE_REAL, TYPE_STRING]:
				# All numeric values can be safely assumed float (as per JSON)
				# since all methods using them do proper casting
				variables[variable_name] = value
	# Silently ignore everything else
