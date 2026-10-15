extends Node2D

const FADE_DURATION := 1.0
const ENTRANCE_FADE_DURATION := 0.5
# 各物体视频结束后的停顿时间
const CAP_PAUSE := 0.5
const FLOWER_PAUSE := 0.2
const CANDY_PAUSE := 0.5
const LIVINGROOM_SCENE := "res://scenes/main/livingroom.tscn"
const BEDROOM_SCENE := "res://scenes/main/bedroom.tscn"

# 各可点击物的 key（需与 GameState.STAGE_MEMORIES 中一致）
const KEY_CAP := "cap"
const KEY_FLOWER := "flower"
const KEY_CANDY := "candy"

var _entrance_fading := true
var _memory_started := false
var _current_key := ""
var _current_pause := 0.0


func _ready() -> void:
	# 按当前阶段显示对应背景
	$livingroom1.visible = GameState.current_stage == 1
	$livingroom2.visible = GameState.current_stage == 2
	$livingroom3.visible = GameState.current_stage == 3
	# 杯子随阶段换图
	$CapArea/Cap1.visible = GameState.current_stage == 1
	$CapArea/Cap2.visible = GameState.current_stage == 2
	$CapArea/Cap3.visible = GameState.current_stage == 3
	# Candy 只在阶段 2 可视（其余阶段连点都点不到）
	var show_candy := GameState.current_stage == 2
	$CandyArea.visible = show_candy
	$CandyArea.input_pickable = show_candy
	# ===== Cap1（杯子） =====
	$CapArea.mouse_entered.connect(_on_area_mouse_entered)
	$CapArea.mouse_exited.connect(_on_area_mouse_exited)
	$CapArea.input_event.connect(_on_cap_input_event)
	# ===== Flower1（花盆） =====
	$FlowerArea.mouse_entered.connect(_on_area_mouse_entered)
	$FlowerArea.mouse_exited.connect(_on_area_mouse_exited)
	$FlowerArea.input_event.connect(_on_flower_input_event)
	# ===== Candy（糖果） =====
	$CandyArea.mouse_entered.connect(_on_area_mouse_entered)
	$CandyArea.mouse_exited.connect(_on_area_mouse_exited)
	$CandyArea.input_event.connect(_on_candy_input_event)
	# ===== 公共 =====
	$CapLayer/VideoPlayer.finished.connect(_on_video_finished)
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


# ===== 鼠标光标（所有可点击物体共用） =====

func _on_area_mouse_entered() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)


func _on_area_mouse_exited() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)


# ===== 卧室跳转按钮 =====

func _on_bedroom_button_pressed() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	get_tree().change_scene_to_file(BEDROOM_SCENE)


# ===== Cap1 点击处理（独立） =====

func _on_cap_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cap_clicked()


func _on_cap_clicked() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	if not GameState.is_memory_enabled(KEY_CAP):
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)
		return
	if GameState.is_memory_watched(KEY_CAP):
		GameState.show_notification(GameState.TEXT_WATCHED)
		return
	_play_memory_sequence(KEY_CAP, CAP_PAUSE)


# ===== Flower1 点击处理（独立） =====

func _on_flower_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_flower_clicked()


func _on_flower_clicked() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	if not GameState.is_memory_enabled(KEY_FLOWER):
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)
		return
	if GameState.is_memory_watched(KEY_FLOWER):
		GameState.show_notification(GameState.TEXT_WATCHED)
		return
	_play_memory_sequence(KEY_FLOWER, FLOWER_PAUSE)


# ===== Candy 点击处理（独立） =====

func _on_candy_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_candy_clicked()


func _on_candy_clicked() -> void:
	if _entrance_fading or _memory_started or GameState.is_transitioning():
		return
	if not GameState.is_memory_enabled(KEY_CANDY):
		GameState.show_notification(GameState.TEXT_NOT_IN_STAGE)
		return
	if GameState.is_memory_watched(KEY_CANDY):
		GameState.show_notification(GameState.TEXT_WATCHED)
		return
	_play_memory_sequence(KEY_CANDY, CANDY_PAUSE)


# ===== 通用：记忆视频播放序列 =====
# 渐黑 → 显示视频并播放 → 渐透明（看到第一帧）→ [视频播完] → 停顿 → 渐黑 → 切回 livingroom
# 后期添加新物体只需调用此方法，传入唯一 key 和停顿时长
func _play_memory_sequence(key: String, pause_duration: float) -> void:
	_memory_started = true
	_current_key = key
	_current_pause = pause_duration
	$ButtonLayer/BedroomButton.visible = false
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
	# 标记当前物体已观看
	GameState.mark_watched(_current_key)
	# 停顿 → 渐黑 → 切回 livingroom（新场景再从黑屏渐入）
	var overlay: ColorRect = $CapLayer/CapRemember
	overlay.visible = true
	overlay.color.a = 0.0
	var tween := create_tween()
	tween.tween_interval(_current_pause)
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_return_to_livingroom)


# ===== 切回客厅 =====

func _return_to_livingroom() -> void:
	get_tree().change_scene_to_file(LIVINGROOM_SCENE)
