extends AudioStreamPlayer

func initialize(stream: AudioStream) -> AudioStreamPlayer:
	self.stream = stream
	return self

func _ready() -> void:
	self.finished.connect(_on_finish)

func _on_finish() -> void:
	self.queue_free()
