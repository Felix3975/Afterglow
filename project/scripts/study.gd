extends Node2D

const ENTRANCE_FADE_DURATION := 0.5
const BEDROOM_SCENE := "res://scenes/main/bedroom.tscn"
const PHOTOS_SCENE := "res://scenes/study/photos.tscn"
const NOTE_INSIDE_SCENE := "res://scenes/study/note_inside.tscn"

# 各可点击物的 key（需与 GameState.STAGE_MEMORIES 中一致）
const KEY_NOTE := "note"

var _entrance_fading := true


func _ready() -> void:
	# 按当前阶段显示对应背景
	$study1.visible = GameState.current_stage == 1
	$study2.visible = GameState.current_stage == 2
	$study3.visible = GameState.current_stage == 3
	$BookArea.input_event.connect(_on_book_input_event)
	$BookArea.mouse_entered.connect(_on_area_mouse_entered)
	$BookArea.mouse_exited.connect(_on_area_mouse_exited)
	# BookArea 只在阶段 1 可点击（阶段 2 / 3 保持可视但无响应无手型）
	$BookArea.input_pickable = GameState.current_stage == 1
	# 笔记：所有阶段都可视（阶段 1 / 3 点击只会提示"想不起更多了"）
	$NoteArea.mouse_entered.connect(_on_area_mouse_entered)
	$NoteArea.mouse_exited.connect(_on_area_mouse_exited)
	$NoteArea.input_event.connect(_on_note_input_event)
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


# ===== Note 点击 → 阶段 2 放大查看，其余提示 =====

func _on_note_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _entrance_fading or GameState.is_transitioning():
			return
		if GameState.current_stage == 2:
			if not GameState.is_memory_watched(KEY_NOTE):
				get_tree().change_scene_to_file(NOTE_INSIDE_SCENE)
				return
			GameState.show_notification(GameState.TEXT_WATCHED)
			return
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)
