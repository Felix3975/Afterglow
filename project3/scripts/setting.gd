extends Node2D

signal closed

const SETTINGS_PATH := "user://settings.cfg"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MasterSlider.value_changed.connect(_on_volume_changed.bind("Master"))
	$BgmSlider.value_changed.connect(_on_volume_changed.bind("BGM"))
	$SfxSlider.value_changed.connect(_on_volume_changed.bind("SFX"))
	$CloseButton.pressed.connect(_on_close_button_pressed)
	_load_settings()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_button_pressed() -> void:
	visible = false
	closed.emit()


func _on_volume_changed(value: float, bus_name: String) -> void:
	_apply_volume(bus_name, value)
	_save_settings()


func _apply_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	$MasterSlider.set_value_no_signal(config.get_value("audio", "master", 1.0))
	$BgmSlider.set_value_no_signal(config.get_value("audio", "bgm", 1.0))
	$SfxSlider.set_value_no_signal(config.get_value("audio", "sfx", 1.0))
	_apply_volume("Master", $MasterSlider.value)
	_apply_volume("BGM", $BgmSlider.value)
	_apply_volume("SFX", $SfxSlider.value)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", $MasterSlider.value)
	config.set_value("audio", "bgm", $BgmSlider.value)
	config.set_value("audio", "sfx", $SfxSlider.value)
	config.save(SETTINGS_PATH)
