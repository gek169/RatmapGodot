#Usage:
#var temp_player = SimpleAudioPlayer.new()
#temp_player.play_sound(mysound, position, ... [args])
extends Spatial

var audio_node: AudioStreamPlayer3D = null
var should_loop = false
var loops: int = -1
#var globals = null
func _ready():
	audio_node = AudioStreamPlayer3D.new()
	get_tree().get_root().add_child(self)
	audio_node.connect("finished", self, "sound_finished")
	add_child(audio_node)
	add_to_group("DONT_SAVE",false)
	add_to_group("SimpleAudioPlayers",false)
	audio_node.stop()

	#globals = get_node("/root/Globals")


func play_sound(audio_stream, position: Vector3, volume = null, pitch = null, max_distance = null):
	if audio_stream == null:
		print ("No audio stream passed; cannot play sound")
		#globals.created_audio.remove(globals.created_audio.find(self))
		queue_free()
		return

	audio_node.stream = audio_stream
	if pitch is float:
		audio_node.pitch_scale = pitch
	if volume is float:
		audio_node.unit_db = volume
	if max_distance is float:
		audio_node.max_distance = max_distance
	audio_node.global_transform.origin = position
	audio_node.play(0.0)


func sound_finished():
	if should_loop:
		audio_node.play(0.0)
		if loops > 0:
			loops = loops - 1
		elif loops == 0:
			queue_free()
	else:
		audio_node.stop()
		queue_free()
