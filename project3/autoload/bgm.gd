extends Node

const BGM_BUS := "BGM"


func _ready() -> void:
	var player: AudioStreamPlayer = $Player
	if player.stream != null:
		# 运行时开启无缝循环（不依赖 .import 的 loop 设置）
		if player.stream is AudioStreamOggVorbis:
			(player.stream as AudioStreamOggVorbis).loop = true
		player.play()
	_apply_saved_volume()


func _apply_saved_volume() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	var value: float = config.get_value("audio", "bgm", 1.0)
	var bus_index := AudioServer.get_bus_index(BGM_BUS)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))
