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

func _ready() -> void:
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
	var datetimes := Data.get_all_entry_datetimes()
	if datetimes.is_empty() or nav_offset == 0:
		return get_todays_datetime()
	return datetimes[-nav_offset]

func update():
	var is_today := nav_offset == 0
	var datetime := get_offset_datetime()
	
	%TodayButton.visible = not is_today
	%AnniversaryButton.visible = not Data.get_anniversaries(datetime).size() > 1
	
	%CurrentDayEntryLabel.text = Data.get_entry(get_todays_datetime(), nav_offset) + "\n "
	
	if is_today:
		var has_entry := Data.has_entry(datetime)
		%EntryContainer.visible = not has_entry
		set_entry_state(EntryStage.Date)

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
			%LineEdit.grab_focus()
			current_entry = %PromptLabel.text
			current_entry = current_entry.replace("\n", " ")
			#current_entry = ensure_text_ends_with(current_entry, " ")
			#current_entry += %LineEdit.text
			current_entry = ensure_text_ends_with(current_entry, ".")
			#current_entry += text + " "
			%PromptLabel.text = "Today I took a step towards liberation from"
		EntryStage.LiberateWith:
			%LineEdit.grab_focus()
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

func request_go_to_prev():
	if not Data.has_entry(get_todays_datetime(), nav_offset - 1):
		print("cannot go to prev")
		return
	nav_offset -= 1
	update()

func request_go_to_next():
	if not Data.has_entry(get_todays_datetime(), nav_offset + 1):
		print("cannot go to next")
		return
	nav_offset += 1
	update()

func _on_today_button_pressed() -> void:
	nav_offset = 0
	update()


func _on_next_entry_stage_button_button_up() -> void:
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

var input_request_callable:Callable
func _on_current_day_entry_label_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_echo():
			input_request_callable = Callable()
		if event.position.x <= 31:
			input_request_callable = request_go_to_prev
		if event.position.x >= 32:
			input_request_callable = request_go_to_next
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.is_echo():
					input_request_callable = Callable()
				else:
					if event.position.x <= 31:
						input_request_callable = request_go_to_prev
					if event.position.x >= 32:
						input_request_callable = request_go_to_next
			else:
				input_request_callable = Callable()

var callable_next_frame:Callable
func _process(delta: float) -> void:
	if callable_next_frame != Callable():
		callable_next_frame.call()
		callable_next_frame = Callable()
	if input_request_callable:
		callable_next_frame = input_request_callable


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		request_go_to_prev()
	elif event.is_action_pressed("ui_right"):
		request_go_to_next()
