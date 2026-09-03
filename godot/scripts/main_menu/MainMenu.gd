extends Control

func _ready() -> void:
	$PlayButton.pressed.connect(_on_play)
	$QuitButton.pressed.connect(_on_quit)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/vertical_slice/VerticalSlice.tscn")

func _on_quit() -> void:
	get_tree().quit()
