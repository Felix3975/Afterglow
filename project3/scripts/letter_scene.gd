extends Node2D

const ENTRANCE_FADE_DURATION := 0.5
const BEDROOM_SCENE := "res://scenes/main/bedroom.tscn"

# 各可点击物的 key（需与 GameState.STAGE_MEMORIES 中一致）
const KEY_LETTER := "letter"

var _entrance_fading := true


func _ready() -> void:
	# 进入即视为已看（供阶段 2 完成度判定）；重复进入无任何提示
	GameState.mark_watched(KEY_LETTER)
	$ButtonLayer/ReturnButton.pressed.connect(_on_return_button_pressed)
	_fade_in()


# ===== 场景入场过渡 =====
# 注意：此处不调用 GameState.check_and_start_stage_transition()
# 阶段转场由返回 bedroom 后、bedroom 入场渐入完成时检查触发

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


# ===== 返回按钮 =====

func _on_return_button_pressed() -> void:
	if _entrance_fading or GameState.is_transitioning():
		return
	get_tree().change_scene_to_file(BEDROOM_SCENE)
