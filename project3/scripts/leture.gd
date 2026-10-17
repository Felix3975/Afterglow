extends Node2D
# 通用对话框（leture.tscn）：
# - start(lines) 开始一段对话；lines 为 {id: int, text: String} 数组
# - id=1 显示 UserName（"我"），id=2 显示 UserName2（前期不使用）
# - 打字机效果（约 25 字/秒）；输出中点击 → 跳过（立即显示全部文字）
# - 整句显示完 → 右下角 Next 图标出现；再点击 → 下一句 / 对话结束
# - 点击由全屏 ClickCatcher 接管：对话框期间客厅不可交互；
#   本层（50）位于 MenuLayer（90）之下，右上角设置不受影响

signal finished

const CHARS_PER_SECOND := 15.0

var _lines: Array = []
var _index := 0
var _typing := false
var _char_accum := 0.0

@onready var _label: Label = $Label
@onready var _next_icon: Sprite2D = $Next


func _ready() -> void:
	$ClickCatcher.gui_input.connect(_on_click_catcher_input)
	visible = false


# ===== 对外接口：开始一段对话 =====

func start(lines: Array) -> void:
	_lines = lines
	_index = 0
	visible = true
	_start_line()


func _start_line() -> void:
	var line: Dictionary = _lines[_index]
	var id: int = line.get("id", 1)
	$UserName.visible = id == 1
	$UserName2.visible = id == 2
	_label.text = line["text"]
	_label.visible_characters = 0
	_char_accum = 0.0
	_typing = true
	_next_icon.visible = false


func _process(delta: float) -> void:
	if not _typing:
		return
	_char_accum += delta * CHARS_PER_SECOND
	var total := _label.get_total_character_count()
	var shown := mini(int(_char_accum), total)
	_label.visible_characters = shown
	if shown >= total:
		_show_full_line()


func _show_full_line() -> void:
	_typing = false
	_label.visible_characters = -1
	_next_icon.visible = true


# ===== 点击：跳过 → 下一句 / 结束 =====

func _on_click_catcher_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _typing:
			_show_full_line()
		elif _index < _lines.size() - 1:
			_index += 1
			_start_line()
		else:
			visible = false
			finished.emit()
