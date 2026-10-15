class_name Start
extends Node2D

const FADE_DURATION := 0.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$StartButton.input_event.connect(_on_start_button_input_event)
	$SettingButton.input_event.connect(_on_setting_button_input_event)
	$QuitButton.input_event.connect(_on_quit_button_input_event)
	$Setting.closed.connect(_on_setting_closed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_game()


func _start_game() -> void:
	# 渐入纯黑后切换到客厅场景，客厅内再从黑屏渐入
	var fade: ColorRect = $FadeLayer/Fade
	if fade.visible:
		return
	fade.visible = true
	fade.color.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_change_to_livingroom)


func _change_to_livingroom() -> void:
	get_tree().change_scene_to_file("res://scenes/main/livingroom.tscn")


func _on_setting_button_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_setting()


func _on_quit_button_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().quit()


func _open_setting() -> void:
	$Setting.visible = true
	for button in [$StartButton, $SettingButton, $QuitButton]:
		button.visible = false
		button.input_pickable = false


func _on_setting_closed() -> void:
	$Setting.visible = false
	for button in [$StartButton, $SettingButton, $QuitButton]:
		button.visible = true
		button.input_pickable = true
