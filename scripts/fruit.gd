extends Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D

var score_value: int = 100

func set_region_x(new_x: float) -> void:
	sprite_2d.texture.region = Rect2(new_x, 48, 16, 16)

func _on_body_entered(_body: Node2D) -> void:
	GameManager.score += score_value
	AudioManager.eat_fruit.play()
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()
