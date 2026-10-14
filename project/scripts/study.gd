extends Node2D

const ENTRANCE_FADE_DURATION := 0.5
const BEDROOM_SCENE := "res://scenes/main/bedroom.tscn"
const PHOTOS_SCENE := "res://scenes/study/photos.tscn"

var _entrance_fading := true


func _ready() -> void:
	$Book.input_event.connect(_on_book_input_event)
	$Book.mouse_entered.connect(_on_area_mouse_entered)
	$Book.mouse_exited.connect(_on_area_mouse_exited)
	$ButtonLayer/BedroomButton.pressed.connect(_on_bedroom_button_pressed)
	_fade_in()


# ===== 场景入场过渡 =====

func _fade_in() -> void:
	var overlay: ColorRect = $CapLayer/CapRemember
	overlay.visible = true
	overlay.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, ENTRANCE_FADE_DURATION)
	tween.tween_callback(_on_fade_in_finished)


func _on_fade_in_finished() -> void:
	_entrance_fading = false
	$CapLayer/CapRemember.visible = false
	# 本阶段记忆全部看完 → 触发阶段切换
	GameState.check_and_start_stage_transition()


# ===== 鼠标光标 =====

func _on_area_mouse_entered() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)


func _on_area_mouse_exited() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)


# ===== 卧室跳转按钮 =====

func _on_bedroom_button_pressed() -> void:
	if _entrance_fading or GameState.is_transitioning():
		return
	get_tree().change_scene_to_file(BEDROOM_SCENE)


# ===== Book 点击 → 跳转 Photos =====

func _on_book_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _entrance_fading or GameState.is_transitioning():
			return
		get_tree().change_scene_to_file(PHOTOS_SCENE)
