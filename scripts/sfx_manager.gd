extends Node
# ============================================================
# SFX Manager — Procedural audio for M0M3NTUM
# Generates tones/noise via AudioStreamGenerator (no files needed)
# ============================================================

var _players: Array[AudioStreamPlayer] = []
var _pool_size := 8
var _pool_idx := 0

func _ready() -> void:
	for i in range(_pool_size):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func _get_player() -> AudioStreamPlayer:
	var p := _players[_pool_idx]
	_pool_idx = (_pool_idx + 1) % _pool_size
	return p

# Play a short synth tone
func play_jump() -> void:
	_synth_tone(440.0, 0.08, 0.6, 0.0)

func play_wall_jump() -> void:
	_synth_tone(520.0, 0.07, 0.5, 80.0)

func play_dash() -> void:
	_synth_noise(0.06, 0.7)

func play_land() -> void:
	_synth_tone(180.0, 0.05, 0.4, -60.0)

func play_grapple_fire() -> void:
	_synth_tone(660.0, 0.04, 0.35, -30.0)

func play_grapple_release() -> void:
	_synth_tone(330.0, 0.04, 0.3, 0.0)

func play_gold() -> void:
	_synth_tone(880.0, 0.1, 0.6, 40.0)

func play_death() -> void:
	_synth_noise(0.18, 0.3)

func _synth_tone(freq: float, duration: float, volume: float, pitch_shift: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = duration
	var p := _get_player()
	p.stream = stream
	p.volume_db = linear_to_db(volume) + pitch_shift * 0.02
	p.play()
	var playback := p.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	var sample_count := int(stream.mix_rate * duration)
	var frames := PackedVector2Array()
	frames.resize(sample_count)
	for i in range(sample_count):
		var t2 := float(i) / stream.mix_rate
		var env := 1.0 - t2 / duration
		var f := freq * pow(2.0, pitch_shift / 1200.0)
		var s := sin(TAU * f * t2) * env * 0.3
		frames[i] = Vector2(s, s)
	playback.push_buffer(frames)

func _synth_noise(duration: float, volume: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = duration
	var p := _get_player()
	p.stream = stream
	p.volume_db = linear_to_db(volume)
	p.play()
	var playback := p.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	var sample_count := int(stream.mix_rate * duration)
	var frames := PackedVector2Array()
	frames.resize(sample_count)
	for i in range(sample_count):
		var t2 := float(i) / stream.mix_rate
		var env := 1.0 - t2 / duration
		var s := randf_range(-1.0, 1.0) * env * 0.25
		frames[i] = Vector2(s, s)
	playback.push_buffer(frames)
