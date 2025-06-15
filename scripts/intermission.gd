extends Node2D

func _ready() -> void:
	get_tree().paused = false

func end_intermission() -> void:
	get_tree().change_scene_to_file("res://scenes/maze.tscn")
