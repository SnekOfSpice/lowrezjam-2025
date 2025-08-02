extends Node

var entries := {}

const DAY_COUNT_BY_MONTH := {
	 1: 31,
	 2: 29,
	 3: 31,
	 4: 30,
	 5: 31,
	 6: 30,
	 7: 31,
	 8: 31,
	 9: 30,
	10: 31,
	11: 30,
	12: 31,
}

func _ready() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	entries = JSON.parse_string(file.get_as_text())
	file.close()

#func _ready() -> void:
	#for month in range (1, 13):
		#var days := {}
		#for day_count in DAY_COUNT_BY_MONTH.get(month):
			## saved by year but this is init so nothing
			#days[day_count] = {}
		#entries[month] = days

func get_all_entry_datetimes() -> Array:
	var datetimes := []
	
	for year in entries.keys():
		var year_entries : Dictionary = entries.get(year)
		for month in year_entries.keys():
			var month_entries : Dictionary = year_entries.get(month)
			for day in month_entries.keys():
				datetimes.append(str(year, "-", month, "-", day))
			
	datetimes.sort_custom(sort_datetimes)
	return datetimes

func sort_datetimes(dt1:String, dt2:String) -> bool:
	var parts = dt1.split("-")
	var y1 = parts[0]
	var m1 = parts[1]
	var d1 = parts[2]
	var parts2 = dt2.split("-")
	var y2 = parts[0]
	var m2 = parts[1]
	var d2 = parts[2]
	
	if y1 < y2: return true
	if m1 < m2: return true
	if d1 < d2: return true
	return false

# origin is the base datetime, offset is how many indices from it we want. usually 0 (for origin itself) or -1 for prev or 1 for next
func get_entry(origin : String, offset:=0) -> String:
	origin = origin.split("T")[0]
	
	if offset == 0:
		var parts = origin.split("-")
		var year = parts[0]
		var month = parts[1]
		var day = parts[2]
		
		return entries.get(year, {}).get(month, {}).get(day, "")
	
	var datetimes := get_all_entry_datetimes()
	#datetimes.append(origin)
	datetimes.sort_custom(sort_datetimes)
	var current_index := datetimes.find(origin)
	if current_index + offset <= 0 or current_index + offset >= datetimes.size():
		return ""
	
	var offset_datatime : String = datetimes[current_index + offset]
	var parts = offset_datatime.split("-")
	var year = parts[0]
	var month = parts[1]
	var day = parts[2]
	
	return entries.get(year, {}).get(month, {}).get(day, "")

func has_entry(datetime:String, offset := 0) -> bool:
	return not get_entry(datetime, offset).is_empty()

func get_anniversaries(datetime:String) -> Array:
	var dt_day : String = datetime.split("-")[2]
	var dt_month : String = datetime.split("-")[1]
	
	var result := []
	for year in entries.keys():
		var year_entries : Dictionary = entries.get(year)
		
		var text_of_day : String = year_entries.get(dt_month, {}).get(dt_day, "")
		if not text_of_day.is_empty():
			result.append(text_of_day)
	
	return result

func save_entry(datetime:String, entry:String):
	var parts = datetime.split("-")
	var year = parts[0]
	var month = parts[1]
	var day = parts[2]
	
	if not entries.has(year):
		entries[year] = {}
	if not entries.get(year).has(month):
		entries[year][month] = {}
	
	entries[year][month][day] = entry
	save()

const SAVE_PATH := "user://entries.json"
func save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(entries, "\t"))
	file.close()
