extends Control
@onready var highscore: Label = $Highscore

func _ready() -> void:
	highscore.text = str(GameManager.highscore)
	GameManager.init_values()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		AudioManager.credit.play()
		await AudioManager.credit.finished
		get_tree().change_scene_to_file("res://scenes/maze.tscn")
