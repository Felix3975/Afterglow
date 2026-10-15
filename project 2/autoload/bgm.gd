extends Node

const BGM_BUS := "BGM"


func _ready() -> void:
	var player: AudioStreamPlayer = $Player
	if player.stream != null:
		player.finished.connect(_on_player_finished)
		player.play()
	_apply_saved_volume()


func _on_player_finished() -> void:
	if $Player.stream != null:
		$Player.play()


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
