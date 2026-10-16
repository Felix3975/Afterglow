extends Node2D

const FADE_DURATION := 1.0
const ENTRANCE_FADE_DURATION := 0.5
const KITE_PAUSE := 0.5
const LIVINGROOM_SCENE := "res://scenes/main/livingroom.tscn"
const DESK_SCENE := "res://scenes/livingroom/desk.tscn"

# 各可点击物的 key（需与 GameState.STAGE_MEMORIES 中一致）
const KEY_KITE := "kite"

var _entrance_fading := true
var _memory_started := false


func _ready() -> void:
	$KiteAreaRetail.mouse_entered.connect(_on_area_mouse_entered)
	$KiteAreaRetail.mouse_exited.connect(_on_area_mouse_exited)
	$KiteAreaRetail.input_event.connect(_on_kite_input_event)
	$CapLayer/VideoPlayer.finished.connect(_on_video_finished)
	$ButtonLayer/ReturnButton.pressed.connect(_on_return_button_pressed)
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
	# 本阶段记忆全部看完 → 触发阶段切换（最终阶段由 GameState 内部拦截，无任何反应）
	GameState.check_and_start_stage_transition()


# ===== 鼠标光标 =====

func _on_area_mouse_entered() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)


func _on_area_mouse_exited() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)


# ===== 返回按钮 =====

func _on_return_button_pressed() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	get_tree().change_scene_to_file(LIVINGROOM_SCENE)


# ===== KiteAreaRetail 点击处理 =====
# 点击区域与返回按钮重叠时，优先响应返回按钮，不响应 KiteAreaRetail

func _on_kite_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and ($ButtonLayer/ReturnButton == hovered or $ButtonLayer/ReturnButton.is_ancestor_of(hovered)):
			return
		_on_kite_clicked()


func _on_kite_clicked() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	if not GameState.is_memory_enabled(KEY_KITE):
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)
		return
	if GameState.is_memory_watched(KEY_KITE):
		GameState.show_notification(GameState.TEXT_WATCHED)
		return
	_play_memory_sequence()


# ===== 记忆视频播放序列 =====
# 渐黑 → 显示视频并播放 → 渐透明 → [播完] → 停顿 0.5 秒 → 渐黑 → 切回 desk

func _play_memory_sequence() -> void:
	_memory_started = true
	$ButtonLayer/ReturnButton.visible = false
	var overlay: ColorRect = $CapLayer/CapRemember
	overlay.visible = true
	overlay.color.a = 0.0
	var tween := create_tween()
	# 1. 先渐黑
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	# 2. 黑屏时显示视频并开始播放
	tween.tween_callback(_show_and_play_video)
	# 3. 逐渐透明，看到视频第一帧
	tween.tween_property(overlay, "color:a", 0.0, FADE_DURATION)


func _show_and_play_video() -> void:
	var vp := $CapLayer/VideoPlayer
	vp.visible = true
	vp.play()


func _on_video_finished() -> void:
	# 标记已观看
	GameState.mark_watched(KEY_KITE)
	# 停顿 → 渐黑 → 切回 desk（新场景再从黑屏渐入）
	var overlay: ColorRect = $CapLayer/CapRemember
	overlay.visible = true
	overlay.color.a = 0.0
	var tween := create_tween()
	tween.tween_interval(KITE_PAUSE)
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_return_to_desk)


# ===== 切回 desk =====

func _return_to_desk() -> void:
	get_tree().change_scene_to_file(DESK_SCENE)
