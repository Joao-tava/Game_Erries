extends Node

@onready var audio_player = $AudioStreamPlayer

func _ready() -> void:
	print("=== MUSIC DEBUG ===")
	print("AudioStreamPlayer existe: ", audio_player != null)
	
	var audio_path = "res://Asssets/SoundEfects/Super Mario World - Wandering The Plains (Restored) - LadiesMan217 (128k).wav"
	print("Arquivo existe: ", ResourceLoader.exists(audio_path))
	
	var audio_stream = load(audio_path)
	print("Stream carregado: ", audio_stream)
	print("Tipo do stream: ", audio_stream.get_class() if audio_stream else "NULL")
	
	audio_player.stream = audio_stream
	audio_player.volume_db = 0
	audio_player.play()
	print("Tocando: ", audio_player.playing)
