extends LineEdit

var keyboard_height = DisplayServer.virtual_keyboard_get_height()
@export var scroll_container : ScrollContainer

func _ready() -> void:
	focus_entered.connect(_on_line_edit_focus_entered)
	focus_exited.connect(_on_line_edit_focus_exited)

func _on_line_edit_focus_entered():
	virtual_keyboard_resize(scroll_container, true)
	call_deferred("ensure_control_visible_deferred")

func _on_line_edit_focus_exited():
	virtual_keyboard_resize(scroll_container, false)

func ensure_control_visible_deferred():
	scroll_container.ensure_control_visible(self)

func virtual_keyboard_resize(control, is_visible):
	control.size.y += -keyboard_height if is_visible else keyboard_height
