extends Node2D

const FADE_DURATION := 1.0
const ENTRANCE_FADE_DURATION := 0.5
const WINDOW_PAUSE := 0.2
const BEDROOM_SCENE := "res://scenes/main/bedroom.tscn"
const WINDOW_AREA_SCENE := "res://scenes/bedroom/window_area.tscn"

# 各可点击物的 key（需与 GameState.STAGE_MEMORIES 中一致）
const KEY_WINDOW := "window"

# 窗户记忆视频
const WINDOW_VIDEO := preload("res://resources/video/children run.ogv")

# 各阶段的窗户背景（阶段不同图片不同）
const BG_TEXTURES := {
	1: preload("res://resources/photos/window1.png"),
	2: preload("res://resources/photos/window2.png"),
	3: preload("res://resources/photos/window3.png"),
}

var _entrance_fading := true
var _memory_started := false
var _current_key := ""
var _current_pause := 0.0


func _ready() -> void:
	# 按当前阶段显示对应窗户背景
	$BG.texture = BG_TEXTURES.get(GameState.current_stage, BG_TEXTURES[1])
	$ClickArea.mouse_entered.connect(_on_area_mouse_entered)
	$ClickArea.mouse_exited.connect(_on_area_mouse_exited)
	$ClickArea.input_event.connect(_on_click_input_event)
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
	# 本阶段记忆全部看完 → 触发阶段切换
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
	get_tree().change_scene_to_file(BEDROOM_SCENE)


# ===== Click 点击处理 =====

func _on_click_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click_area_clicked()


func _on_click_area_clicked() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	if not GameState.is_memory_enabled(KEY_WINDOW):
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)
		return
	if GameState.is_memory_watched(KEY_WINDOW):
		GameState.show_notification(GameState.TEXT_WATCHED)
		return
	_play_memory_sequence(KEY_WINDOW, WINDOW_PAUSE)


# ===== 记忆视频播放序列 =====
# 渐黑 → 显示视频并播放 → 渐透明 → [播完] → 停顿 → 渐黑 → 切回 WindowArea

func _play_memory_sequence(key: String, pause_duration: float) -> void:
	_memory_started = true
	_current_key = key
	_current_pause = pause_duration
	GameState.memory_playing = true
	$ButtonLayer/ReturnButton.visible = false
	$CapLayer/VideoPlayer.stream = WINDOW_VIDEO
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
	GameState.mark_watched(_current_key)
	# 准备播放后对话（第一个记忆追加结尾句）
	GameState.prepare_memory_dialog(_current_key)
	# 停顿 → 渐黑 → 切回 WindowArea
	var overlay: ColorRect = $CapLayer/CapRemember
	overlay.visible = true
	overlay.color.a = 0.0
	var tween := create_tween()
	tween.tween_interval(_current_pause)
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_return_to_window_area)


# ===== 切回 WindowArea =====

func _return_to_window_area() -> void:
	GameState.memory_playing = false
	get_tree().change_scene_to_file(WINDOW_AREA_SCENE)
