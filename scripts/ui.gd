extends Control
@onready var lives: TextureRect = $Lives
@onready var level: TextureRect = $Level

@onready var highscore: Label = $Highscore
@onready var score: Label = $Score
@onready var _1up: Label = $"1UP"
@onready var ready_label: Label = $Ready
@onready var game_over: Label = $GameOver

func _process(_delta: float) -> void:
	if GameManager.game_over:
		game_over.visible = true
	score.text = str(GameManager.score)
	highscore.text = str(max(GameManager.score,GameManager.highscore))
	if GameManager.lives > 0:
		var lives_region_y = 80 - GameManager.lives * 16
		lives.texture.region = Rect2(0,lives_region_y,80,16)
	else:
		lives.visible = false
	
	var level_region_y = 64 + GameManager.round_number * 16
	if level_region_y > 368:
		level_region_y = 368
	level.texture.region = Rect2(0,level_region_y,112,16)
	

func _on_timer_timeout() -> void:
	if ready_label.visible:
		ready_label.visible = false
	_1up.visible = !_1up.visible
