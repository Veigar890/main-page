extends Node

@export var background_music_stream: AudioStream = preload("res://assets/audio/main_bg.ogg")
@export var click_stream: AudioStream = preload("res://assets/audio/click.ogg")

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.stream = background_music_stream
	_music_player.autoplay = false
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	
	if background_music_stream and background_music_stream is AudioStreamOggVorbis:
		background_music_stream.loop = true
	
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	_sfx_player.autoplay = false
	_sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_player)
	
	ensure_music_state()

func ensure_music_state() -> void:
	if not _music_player:
		return
	
	if Globals.music_enabled and background_music_stream:
		if not _music_player.playing:
			_music_player.play()
	else:
		if _music_player.playing:
			_music_player.stop()

func play_click() -> void:
	if not _sfx_player or not click_stream:
		return
	
	if not Globals.audio_enabled:
		return
	
	_sfx_player.stream = click_stream
	_sfx_player.stop()
	_sfx_player.play()

func stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()

