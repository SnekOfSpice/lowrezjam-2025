extends Node

var entries := {
	#"2024" : {
		#"01" : {
			#"03" : "2024-01-03 its earlier januaray uwuwu",
			#"04" : "2024-01-04 its earlier januaray again uwuwu dfgdfg dfg df dfg df df d d df df d dgdfg dfg df dfg df df d d df df d d",
		#}
	#},
	#"2025" : {
		#"01" : {
			#"03" : "2025-01-03 its januaray uwugain uwuwu dfgdfg dfg df dfg df df d d df df d dgdfg dfg df dfg df df d d df df dwu",
			#"04" : "2025-01-04 its januaray again uwgain uwuwu dfgdfg dfg df dfg df df d d df df d dgdfg dfg df dfg df df d d df df duwu",
		#},
		#"08" : {
			#"02" : "2025-08-02 its yesterdaygain uwuwu dfgdfg dfg df dfg df df d d df df d dgdfg dfg df dfg df df d d df df d",
			#"03" : "2025-08-03 its today",
			#"04" : "2025-08-04 its tpmorrow",
		#}
	#}
}


func _ready() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	entries = JSON.parse_string(file.get_as_text())
	file.close()


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
	var y2 = parts2[0]
	var m2 = parts2[1]
	var d2 = parts2[2]
	
	if y1 < y2: return true
	if m1 < m2: return true
	if d1 < d2: return true
	return false

# origin is the base datetime, offset is how many indices from it we want. usually 0 (for origin itself) or -1 for prev or 1 for next
func get_entry(origin : String, offset:=0) -> String:
	origin = origin.split("T")[0]
	
	if offset == 0:
		@warning_ignore("confusable_local_declaration")
		var parts = origin.split("-")
		@warning_ignore("confusable_local_declaration")
		var year = parts[0]
		@warning_ignore("confusable_local_declaration")
		var month = parts[1]
		@warning_ignore("confusable_local_declaration")
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
