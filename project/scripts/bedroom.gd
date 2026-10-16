extends Node2D

const ENTRANCE_FADE_DURATION := 0.5
const FADE_DURATION := 1.0
const MEMORY_PAUSE := 0.5
const LIVINGROOM_SCENE := "res://scenes/main/livingroom.tscn"
const STUDY_SCENE := "res://scenes/main/study.tscn"
const WINDOW_AREA_SCENE := "res://scenes/bedroom/window_area.tscn"
const LETTER_AREA_SCENE := "res://scenes/bedroom/letter_scene.tscn"

# 各可点击物的 key（需与 GameState.STAGE_MEMORIES 中一致）
const KEY_FIRSTTSPHOTO := "firsttsphoto"
const KEY_LETTER := "letter"

var _entrance_fading := true
var _memory_started := false


func _ready() -> void:
	# 按当前阶段显示对应背景
	$bedroom1.visible = GameState.current_stage == 1
	$bedroom2.visible = GameState.current_stage == 2
	$bedroom3.visible = GameState.current_stage == 3
	# 合照：阶段 1、2 各显示一张，阶段 3 两张都不可视（但仍可点击）
	$"FisttsPhotoArea/1".visible = GameState.current_stage == 1
	$"FisttsPhotoArea/2".visible = GameState.current_stage == 2
	# 信件：阶段 1 不可视不可点，阶段 2 / 3 可视
	$LetterArea.visible = GameState.current_stage != 1
	$LetterArea.input_pickable = GameState.current_stage != 1
	# ===== 窗户（跳转 WindowArea 场景） =====
	$WindowArea.mouse_entered.connect(_on_area_mouse_entered)
	$WindowArea.mouse_exited.connect(_on_area_mouse_exited)
	$WindowArea.input_event.connect(_on_window_input_event)
	# ===== 信件（阶段 2 放大查看） =====
	$LetterArea.mouse_entered.connect(_on_area_mouse_entered)
	$LetterArea.mouse_exited.connect(_on_area_mouse_exited)
	$LetterArea.input_event.connect(_on_letter_input_event)
	# ===== 合照（阶段 1 播放记忆） =====
	$FisttsPhotoArea.mouse_entered.connect(_on_area_mouse_entered)
	$FisttsPhotoArea.mouse_exited.connect(_on_area_mouse_exited)
	$FisttsPhotoArea.input_event.connect(_on_firsttsphoto_input_event)
	$CapLayer/VideoPlayer.finished.connect(_on_video_finished)
	$ButtonLayer/LivingroomButton.pressed.connect(_on_livingroom_button_pressed)
	$ButtonLayer/StudyButton.pressed.connect(_on_study_button_pressed)
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


# ===== 跳转按钮 =====

func _on_livingroom_button_pressed() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	get_tree().change_scene_to_file(LIVINGROOM_SCENE)


func _on_study_button_pressed() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	get_tree().change_scene_to_file(STUDY_SCENE)


# ===== Window 点击 → 跳转 WindowArea 场景 =====

func _on_window_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _entrance_fading or _memory_started or GameState.is_transitioning():
			return
		get_tree().change_scene_to_file(WINDOW_AREA_SCENE)


# ===== Letter 点击 → 阶段 2 放大查看，其余提示 =====

func _on_letter_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _entrance_fading or _memory_started or GameState.is_transitioning():
			return
		# 阶段 2：无论是否看过都可进入 letterscene，无任何提示弹窗
		if GameState.current_stage == 2:
			get_tree().change_scene_to_file(LETTER_AREA_SCENE)
			return
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)


# ===== FisttsPhoto 点击 =====
# 阶段 1 未观看 → 播放记忆；阶段 2 → 已看过；阶段 1 已看 / 阶段 3 → 想不起更多了

func _on_firsttsphoto_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _entrance_fading or _memory_started or GameState.is_transitioning():
			return
		if GameState.current_stage == 1 and not GameState.is_memory_watched(KEY_FIRSTTSPHOTO):
			_play_firsttsphoto_sequence()
			return
		if GameState.current_stage == 2:
			GameState.show_notification(GameState.TEXT_WATCHED)
			return
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)


# ===== 合照记忆播放序列（在卧室场景内直接播放） =====
# 渐黑 → 显示视频并播放 → 渐透明 → [播完] → 停顿 → 渐黑 → 渐出，回到卧室

func _play_firsttsphoto_sequence() -> void:
	_memory_started = true
	_set_buttons_visible(false)
	var overlay: ColorRect = $CapLayer/CapRemember
	overlay.visible = true
	overlay.color.a = 0.0
	var tween := create_tween()
	# 1. 先渐黑
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	# 2. 黑屏时显示视频并开始播放
	tween.tween_callback(_show_and_play_video)
	# 3. 逐渐透明，看到视频
	tween.tween_property(overlay, "color:a", 0.0, FADE_DURATION)


func _show_and_play_video() -> void:
	var vp := $CapLayer/VideoPlayer
	vp.visible = true
	vp.play()


func _on_video_finished() -> void:
	# 标记已观看
	GameState.mark_watched(KEY_FIRSTTSPHOTO)
	var overlay: ColorRect = $CapLayer/CapRemember
	overlay.visible = true
	overlay.color.a = 0.0
	var tween := create_tween()
	# 停顿 → 渐黑
	tween.tween_interval(MEMORY_PAUSE)
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_on_video_blacked_out)


func _on_video_blacked_out() -> void:
	$CapLayer/VideoPlayer.stop()
	$CapLayer/VideoPlayer.visible = false
	# 渐出黑屏，回到卧室
	var overlay: ColorRect = $CapLayer/CapRemember
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, ENTRANCE_FADE_DURATION)
	tween.tween_callback(_on_memory_returned)


func _on_memory_returned() -> void:
	$CapLayer/CapRemember.visible = false
	_memory_started = false
	_set_buttons_visible(true)
	GameState.check_and_start_stage_transition()


func _set_buttons_visible(v: bool) -> void:
	$ButtonLayer/LivingroomButton.visible = v
	$ButtonLayer/StudyButton.visible = v
