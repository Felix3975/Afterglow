extends CanvasLayer
# 全局菜单层：右上角羽毛笔图标 + 居中弹窗（返回主菜单 / 设置音量 / 进入下一阶段）
# 挂在 GameState（Autoload）下，因此除主菜单场景外所有场景都会显示

const START_SCENE := "res://scenes/main/start.tscn"
const LIVINGROOM_SCENE := "res://scenes/main/livingroom.tscn"


func _ready() -> void:
	$QuillIcon.pressed.connect(_on_quill_icon_pressed)
	$Popup.gui_input.connect(_on_popup_gui_input)
	$Popup/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)
	$Popup/SettingButton.pressed.connect(_on_setting_button_pressed)
	$Popup/NextStageButton.pressed.connect(_on_next_stage_button_pressed)
	$Popup/Setting.closed.connect(_on_setting_closed)
	$Popup/Setting.visible = false
	$Popup.visible = false


func _process(_delta: float) -> void:
	# 主菜单场景、阶段转场中、记忆视频播放中 → 隐藏图标（并关掉弹窗）
	var should_show := _should_show_icon()
	if $QuillIcon.visible != should_show:
		$QuillIcon.visible = should_show
		if not should_show:
			_close_popup()


func _should_show_icon() -> bool:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == START_SCENE:
		return false
	if GameState.is_transitioning() or GameState.memory_playing:
		return false
	return not _memory_video_playing()


func _memory_video_playing() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	for node in scene.find_children("*", "VideoStreamPlayer", true, false):
		if node.is_playing():
			return true
	return false


# ===== 羽毛笔图标：开 / 关弹窗 =====

func _on_quill_icon_pressed() -> void:
	if $Popup.visible:
		_close_popup()
		return
	# 阶段 3 已是最后阶段 → "进入下一阶段"置灰
	$Popup/NextStageButton.disabled = GameState.current_stage >= GameState.TOTAL_STAGES
	$Popup/Setting.visible = false
	$Popup.visible = true


func _close_popup() -> void:
	$Popup.visible = false
	$Popup/Setting.visible = false


# 点击弹窗外空白处关闭（设置面板打开时不响应）
func _on_popup_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if $Popup/Setting.visible:
			return
		_close_popup()


# ===== 三个按钮 =====

func _on_main_menu_button_pressed() -> void:
	_close_popup()
	get_tree().change_scene_to_file(START_SCENE)


func _on_setting_button_pressed() -> void:
	$Popup/Setting.visible = true


func _on_setting_closed() -> void:
	if $Popup.visible:
		$Popup/Setting.visible = false


func _on_next_stage_button_pressed() -> void:
	if GameState.current_stage >= GameState.TOTAL_STAGES or GameState.is_transitioning():
		return
	_close_popup()
	GameState.advance_stage()
	get_tree().change_scene_to_file(LIVINGROOM_SCENE)
