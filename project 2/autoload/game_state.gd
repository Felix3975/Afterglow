extends Node
# 全局阶段管理器（Autoload）
# - 记录当前阶段与哪些记忆已观看
# - 提供全局通知弹窗（右下角，类似 Steam 成就）
# - 提供阶段切换遮罩（黑屏 → 正中文字 → 2 秒后自动进入下一阶段）

# ===== 阶段配置（后期加内容只改这里） =====
const TOTAL_STAGES := 3
# 每个阶段可点击的记忆 key 列表；不在当前列表里的 key 不可点击
const STAGE_MEMORIES := {
	1: ["cap", "flower", "photo", "firsttsphoto"],
	2: ["candy", "window", "letter", "note"],
	3: [],
}

# ===== 提示文案（后期改这里） =====
const TEXT_WATCHED := "这段记忆已经看过了"
const TEXT_NOT_IN_STAGE := "想不起更多了"

const FONT_PATH := "res://resources/font/乐米拾光手札体.ttf"
const LIVINGROOM_SCENE := "res://scenes/main/livingroom.tscn"

# ===== 通知系统参数 =====
const MAX_NOTIFICATIONS := 3
const NOTIF_WIDTH := 320.0
const NOTIF_HEIGHT := 56.0
const NOTIF_SPACING := 10.0
const NOTIF_BOTTOM_MARGIN := 20.0
const NOTIF_RIGHT_MARGIN := 20.0
const NOTIF_FADE_IN := 0.2
const NOTIF_LINGER := 0.8
const NOTIF_FADE_OUT := 0.5

# ===== 阶段切换参数 =====
const STAGE_FADE_DURATION := 0.5
const STAGE_TEXT_DURATION := 2.0

# ===== 状态 =====
var current_stage := 1
var _watched: Dictionary = {}
var _notifications: Array[Control] = []
var _skip_latest := false
var _transitioning := false


# ===== 阶段 / 记忆查询 =====

func is_memory_enabled(key: String) -> bool:
	return STAGE_MEMORIES.get(current_stage, []).has(key)


func is_memory_watched(key: String) -> bool:
	return _watched.get(key, false)


func mark_watched(key: String) -> void:
	_watched[key] = true


# 当前阶段列表里的记忆是否全部看完（空列表视为未完成）
func is_stage_complete() -> bool:
	var keys: Array = STAGE_MEMORIES.get(current_stage, [])
	if keys.is_empty():
		return false
	for key in keys:
		if not _watched.get(key, false):
			return false
	return true


func advance_stage() -> void:
	current_stage = min(current_stage + 1, TOTAL_STAGES)


func is_transitioning() -> bool:
	return _transitioning


# ===== 阶段完成检查（房间入场渐入完成后调用） =====

func check_and_start_stage_transition() -> void:
	if _transitioning:
		return
	if not is_stage_complete():
		return
	_start_stage_transition()


func _start_stage_transition() -> void:
	_transitioning = true
	var fade: ColorRect = $TransitionLayer/Fade
	var text: Label = $TransitionLayer/Text
	fade.visible = true
	fade.color.a = 0.0
	text.visible = false
	var tween := create_tween()
	# 1. 短停顿
	tween.tween_interval(0.3)
	# 2. 黑屏渐入
	tween.tween_property(fade, "color:a", 1.0, STAGE_FADE_DURATION)
	# 3. 正中显示文字，2 秒后自动进入下一阶段
	tween.tween_callback(func() -> void:
		text.visible = true
	)
	tween.tween_interval(STAGE_TEXT_DURATION)
	tween.tween_callback(_continue_to_next_stage)


func _continue_to_next_stage() -> void:
	advance_stage()
	get_tree().change_scene_to_file(LIVINGROOM_SCENE)
	var fade: ColorRect = $TransitionLayer/Fade
	var text: Label = $TransitionLayer/Text
	text.visible = false
	# 5. 黑屏渐出（新场景自身也会渐入，二者同时淡出，无缝衔接）
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, STAGE_FADE_DURATION)
	tween.tween_callback(func() -> void:
		fade.visible = false
		_transitioning = false
	)


# ===== 通知系统（右下角冒出，最多 3 个，新通知把旧的往上顶） =====

func show_notification(text: String) -> void:
	while _notifications.size() >= MAX_NOTIFICATIONS:
		var oldest: Control = _notifications[0]
		_notifications.remove_at(0)
		oldest.queue_free()
	var panel := Panel.new()
	panel.size = Vector2(NOTIF_WIDTH, NOTIF_HEIGHT)
	panel.modulate.a = 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", load(FONT_PATH))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.size = Vector2(NOTIF_WIDTH, NOTIF_HEIGHT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	$NotifLayer.add_child(panel)
	_notifications.append(panel)
	# 新通知从屏幕底部外冒出
	var vp := get_viewport().get_visible_rect().size
	var new_idx := _notifications.size() - 1
	var target_y := vp.y - NOTIF_BOTTOM_MARGIN - NOTIF_HEIGHT - new_idx * (NOTIF_HEIGHT + NOTIF_SPACING)
	var target_x := vp.x - NOTIF_RIGHT_MARGIN - NOTIF_WIDTH
	panel.position = Vector2(target_x, vp.y + 10)
	_skip_latest = true
	_layout_notifications()
	_skip_latest = false
	# 滑入+淡入 → 停留 → 淡出 → 移除
	var tween := create_tween()
	tween.bind_node(panel)
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", target_y, NOTIF_FADE_IN)
	tween.tween_property(panel, "modulate:a", 1.0, NOTIF_FADE_IN)
	tween.set_parallel(false)
	tween.tween_interval(NOTIF_LINGER)
	tween.tween_property(panel, "modulate:a", 0.0, NOTIF_FADE_OUT)
	tween.tween_callback(_on_notification_done.bind(panel))


func _on_notification_done(panel: Control) -> void:
	_notifications.erase(panel)
	panel.queue_free()
	_layout_notifications()


func _layout_notifications() -> void:
	var vp := get_viewport().get_visible_rect().size
	for i in _notifications.size():
		var idx := _notifications.size() - 1 - i
		if _skip_latest and i == 0:
			continue
		var notif: Control = _notifications[idx]
		var target_y := vp.y - NOTIF_BOTTOM_MARGIN - NOTIF_HEIGHT - i * (NOTIF_HEIGHT + NOTIF_SPACING)
		var target_x := vp.x - NOTIF_RIGHT_MARGIN - NOTIF_WIDTH
		if notif.position.y != target_y or notif.position.x != target_x:
			var tw := create_tween()
			tw.bind_node(notif)
			tw.tween_property(notif, "position", Vector2(target_x, target_y), 0.3)
