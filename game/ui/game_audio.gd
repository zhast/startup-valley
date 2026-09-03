class_name GameAudio
extends Node

var effects_volume := 0.5
var ambience_volume := 0.2
var _voices: Array[AudioStreamPlayer] = []
var _ambient: AudioStreamPlayer
var _sounds: Dictionary[String, AudioStreamWAV] = {}
var _voice := 0
var _stopped := false

func _ready() -> void:
	if DisplayServer.get_name() == "headless": return
	for kind: String in ["hover", "click", "drawer", "step", "notice", "reward"]:
		_sounds[kind] = _tone(kind)
	for index: int in range(6):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	_ambient = AudioStreamPlayer.new()
	_ambient.stream = _tone("ambient")
	add_child(_ambient)
	set_volumes(effects_volume, ambience_volume)
	_ambient.play()
	get_tree().node_added.connect(_bind_later)
	for node: Node in get_tree().root.find_children("*", "Button", true, false):
		_bind_button(node)

func _bind_later(node: Node) -> void:
	if node is Button:
		call_deferred("_bind_button", node)

func _exit_tree() -> void:
	shutdown()

func shutdown() -> void:
	_stopped = true
	for voice: AudioStreamPlayer in _voices:
		voice.stop()
		voice.stream = null
	if _ambient != null:
		_ambient.stop()
		_ambient.stream = null
	_sounds.clear()

func _bind_button(node: Node) -> void:
	if not is_instance_valid(node) or not node is Button or node.has_meta("audio_bound"):
		return
	node.set_meta("audio_bound", true)
	(node as Button).button_down.connect(func() -> void: play("click"))
	(node as Button).mouse_entered.connect(func() -> void:
		if not (node as Button).disabled: play("hover")
	)

func set_volumes(effects: float, ambience: float) -> void:
	effects_volume = clampf(effects, 0, 1)
	ambience_volume = clampf(ambience, 0, 1)
	if _ambient != null:
		_ambient.volume_db = linear_to_db(maxf(0.0001, ambience_volume * 0.15))

func play(kind: String) -> void:
	if _stopped or _voices.is_empty() or not _sounds.has(kind): return
	var voice := _voices[_voice % _voices.size()]
	_voice += 1
	voice.stream = _sounds[kind]
	voice.volume_db = linear_to_db(maxf(0.0001, effects_volume * 0.28))
	voice.play()

func _tone(kind: String) -> AudioStreamWAV:
	# Original synthesized cues. No external recordings, dependencies, or licenses.
	var duration := 2.0 if kind == "ambient" else 0.18 if kind in ["reward", "notice"] else 0.06
	var frequency := 740.0 if kind == "hover" else 420.0 if kind == "click" else 160.0 if kind == "step" else 880.0 if kind == "reward" else 560.0
	var samples := int(22050 * duration)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for index: int in range(samples):
		var time := float(index) / 22050.0
		var envelope := pow(1.0 - float(index) / samples, 2.0)
		var wave := sin(TAU * frequency * time) * envelope
		if kind == "ambient": wave = (sin(TAU * 60.0 * time) + sin(TAU * 90.0 * time) * 0.3) * 0.12
		var sample := int(clampf(wave * 11000, -32767, 32767))
		bytes.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	if kind == "ambient":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples
	return stream
