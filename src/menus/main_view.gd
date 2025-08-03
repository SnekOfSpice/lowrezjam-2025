extends Control

enum EntryStage {
	Date,
	LiberateFrom,
	LiberateWith
}

const AFFIRMATIONS := [
	"by any means",
	"more of us than them",
	"i am prepared should they force my hand",
	"good pup",
	"set the world ablaze",
	"nothing goes to waste",
	"My heart is a weapon",
	"I’ll die to fight this way",
	"No going back",
	"Self determined",
	"Put your life back in your hands",
	"Who dares wins",
	"For the cause live and die",
	"A world to win",
	"Nothing goes to waste",
]

var entry_stage : EntryStage
var nav_offset := 0
var current_entry := ""

var goal_color1 : Color
var goal_color2 : Color
var goal_color3 : Color

func set_anniversary_visible(value:bool):
	%AnniversaryContainer.visible = value
	%AnniversaryButton.visible = not value
	%TodayButton.visible = not value

func _ready() -> void:
	set_anniversary_visible(false)
	%Praise.visible = false
	nav_offset = 0
	update()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func affirm():
	%Praise.visible = true
	%PraiseLabel.text = AFFIRMATIONS.pick_random()
	var t = get_tree().create_timer(5)
	t.timeout.connect(%Praise.hide)

## returns todays datetime but with the T portion trimmed
func get_todays_datetime() -> String:
	var datetime := Time.get_datetime_string_from_system()
	return datetime.split("T")[0]

func get_offset_datetime() -> String:
	var today := get_todays_datetime()
	var datetimes := Data.get_all_entry_datetimes()
	if datetimes.is_empty() or nav_offset == 0:
		return today
	
	if not datetimes.has(today):
		datetimes.append(today)
	datetimes.sort_custom(Data.sort_datetimes)
	
	var today_pos = datetimes.find(today)
	
	return datetimes[today_pos + nav_offset]

func update():
	var is_today := nav_offset == 0
	var datetime := get_offset_datetime()
	
	%TodayButton.visible = not is_today
	var anniversary_count := Data.get_anniversaries(datetime).size()
	%AnniversaryButton.visible = anniversary_count > 1
	#%AnniversaryButton.text = "(%s)" % anniversary_count
	
	%CurrentDayEntryLabel.text = Data.get_entry(get_todays_datetime(), nav_offset) + "\n "
	
	if %AnniversaryContainer.visible:
		display_anniversaries()
	else:
		if is_today:
			var has_entry := Data.has_entry(datetime)
			%EntryContainer.visible = not has_entry
			%CurrentDayContainer.visible = has_entry
			set_entry_state(EntryStage.Date)
		else:
			%CurrentDayContainer.visible = true
	
	var parts = datetime.split("-")
	var year = parts[0]
	var month = parts[1]
	var day = parts[2]
	var seeds = [
		int(str(year, month, day)),
		int(str(day, month, year)),
		int(str(day, year, month))
		]
	
	for i in 3:
		var seed = seeds[i]
		var rng = rand_from_seed(seed)[0]
		var c = Color()
		c.r = float(str(rng).substr(0, 3)) / 1000.0
		c.g = float(str(rng).substr(4, 3)) / 1000.0
		c.b = float(str(rng).substr(6, 3)) / 1000.0
		c.v *= 0.3
		c.s *= 0.4
		set("goal_color%s" % (i + 1), c)
	
	
func ensure_text_ends_with(text : String, end : String) -> String:
	if not text.ends_with(end):
		text = text + end
	return text

func set_entry_state(state:EntryStage):
	%LineEdit.visible = state != EntryStage.Date
	match state:
		EntryStage.Date:
			current_entry = ""
			%PromptLabel.text = str("It is\n", get_offset_datetime())
		EntryStage.LiberateFrom:
			%LineEdit.call_deferred("grab_focus")
			current_entry = %PromptLabel.text
			current_entry = current_entry.replace("\n", " ")
			#current_entry = ensure_text_ends_with(current_entry, " ")
			#current_entry += %LineEdit.text
			current_entry = ensure_text_ends_with(current_entry, ".")
			#current_entry += text + " "
			%PromptLabel.text = "Today I took a step towards liberation from"
		EntryStage.LiberateWith:
			%LineEdit.call_deferred("grab_focus")
			current_entry = ensure_text_ends_with(current_entry, " ")
			current_entry += %PromptLabel.text
			current_entry = ensure_text_ends_with(current_entry, " ")
			current_entry += %LineEdit.text
			current_entry = ensure_text_ends_with(current_entry, ".")
			current_entry = ensure_text_ends_with(current_entry, " ")
			#current_entry += text + " "
			%PromptLabel.text = "I did this by"
			
	entry_stage = state
	%LineEdit.text = ""

const DEBOUNCE_DURATION := 0.1
func request_go_to_prev():
	if debounce > 0:
		return
	if not Data.has_entry(get_todays_datetime(), nav_offset - 1):
		print("cannot go to prev")
		return
	debounce = DEBOUNCE_DURATION
	nav_offset -= 1
	update()

func request_go_to_next():
	if debounce > 0:
		return
	if not Data.has_entry(get_todays_datetime(), nav_offset + 1):
		print("cannot go to next")
		return
	debounce = DEBOUNCE_DURATION
	nav_offset += 1
	update()

func _on_today_button_pressed() -> void:
	nav_offset = 0
	update()



func go_to_next_entry_state():
	match entry_stage:
		EntryStage.Date:
			set_entry_state(EntryStage.LiberateFrom)
		EntryStage.LiberateFrom:
			set_entry_state(EntryStage.LiberateWith)
		EntryStage.LiberateWith:
			current_entry += %PromptLabel.text
			current_entry = ensure_text_ends_with(current_entry, " ")
			current_entry += %LineEdit.text
			current_entry = ensure_text_ends_with(current_entry, ".")
			Data.save_entry(get_offset_datetime(), current_entry)
			update()
			affirm()

var touch_last_frame := false
var touch_last_position : Vector2
var input_request_callable:Callable
func _on_cover_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		$Label.text = event.screen_relative
		%CurrentDayEntryLabel.get_v_scroll_bar().value += event.screen_relative.y
		%AnniversaryScrollContainer.get_v_scroll_bar().value += event.screen_relative.y
	elif event is InputEventScreenTouch:
		if %AnniversaryContainer.visible:
			return
		#if touch_last_frame:
			#%CurrentDayEntryLabel.get_v_scroll_bar().value += touch_last_position.y - event.position.y
			#%AnniversaryScrollContainer.get_v_scroll_bar().value += touch_last_position.y - event.position.y
		#else:
		if event.position.x <= 31:
			request_go_to_prev()
		if event.position.x >= 32:
			request_go_to_next()
		
		#if event.is_released():
			#touch_last_frame = false
		#else:
			#touch_last_frame = true
			#touch_last_position = event.position
	elif event is InputEventMouseButton:
		if %AnniversaryContainer.visible:
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#if event.is_echo():
					#input_request_callable = Callable()
				#else:
			if event.position.x <= 31:
				request_go_to_prev()
			if event.position.x >= 32:
				request_go_to_next()
			#else:
				#input_request_callable = Callable()

var debounce := 0.0

var callable_next_frame:Callable
func _process(delta: float) -> void:
	if debounce > 0:
		debounce -= delta
		
	
	for i in range(1, 4):
		var current_color : Color = %Background.get_material().get_shader_parameter("colour_%s" % i)
		var r = lerpf(current_color.r, get("goal_color%s" % i).r, 0.04)
		var g = lerpf(current_color.g, get("goal_color%s" % i).r, 0.04)
		var b = lerpf(current_color.b, get("goal_color%s" % i).b, 0.04)
		%Background.get_material().set_shader_parameter("colour_%s" % i, Color(r,g,b))
	#%Background.get_material().set_shader_parameter("colour_3", goal_color3)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		request_go_to_prev()
	elif event.is_action_pressed("ui_right"):
		request_go_to_next()


func _on_anniversary_button_button_up() -> void:
	display_anniversaries()

func display_anniversaries():
	var datetime := get_offset_datetime()
	var anniversaries := Data.get_anniversaries(datetime)
	set_anniversary_visible(true)
	%CurrentDayContainer.visible = false
	%AnniversaryLabel.text = "= %s =" % datetime.right(5)
	for child in %AnniversaryEntries.get_children():
		child.queue_free()
	
	for i in anniversaries.size():
		var label = preload("res://src/entry_rtl.tscn").instantiate()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		%AnniversaryEntries.add_child(label)
		%AnniversaryEntries.move_child(label, 0)
		label.text = anniversaries[i]
		if i < anniversaries.size() - 1:
			var spacer := HSeparator.new()
			%AnniversaryEntries.add_child(spacer)
			%AnniversaryEntries.move_child(spacer, 0)


func _on_close_anniversary_button_button_up() -> void:
	set_anniversary_visible(false)
	update()


func _on_line_edit_text_submitted(_new_text: String) -> void:
	go_to_next_entry_state()
