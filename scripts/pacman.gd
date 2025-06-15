extends CharacterBody2D

const VELOCITY_FRAMES = 60

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var energizer_timer: Timer = $EnergizerTimer
@onready var idle_timer: Timer = $IdleTimer

@export var tile_map: TileMapLayer

var direction: Vector2 = Vector2.RIGHT
var target_direction: Vector2 = direction
var speed_multiplier: float = 1

var consecutive_ghosts_multiplier: int = 1

func _ready() -> void:
	for blank in GameManager.blank_coords:
		tile_map.set_cell(blank, 2, Vector2i.ONE)
		
	speed_multiplier = GameManager.get_pacman_speed()
	energizer_timer.wait_time = GameManager.get_pellet_time()
	if GameManager.round_number < 5:
		idle_timer.wait_time = 4.0
	else:
		idle_timer.wait_time = 3.0
	idle_timer.start()

func _physics_process(_delta: float) -> void:
	if animated_sprite_2d.animation == "death":
		return
	
	if Input.is_action_just_pressed("move_left"):
		target_direction = Vector2.LEFT
	if Input.is_action_just_pressed("move_right"):
		target_direction = Vector2.RIGHT
	if Input.is_action_just_pressed("move_up"):
		target_direction = Vector2.UP
	if Input.is_action_just_pressed("move_down"):
		target_direction = Vector2.DOWN
	
	if target_direction != direction:
		if direction == target_direction * -1:
			direction = target_direction
		elif global_position.distance_to(current_tile_center()) < 2 && check_tile(target_direction):
			if target_direction == Vector2.RIGHT || target_direction == Vector2.LEFT:
				global_position.y = current_tile_center().y
				direction = target_direction
			if target_direction == Vector2.UP || target_direction == Vector2.DOWN:
				global_position.x = current_tile_center().x
				direction = target_direction
	
	if global_position.x < -3*8:
		global_position.x = 30*8
	if global_position.x > 30*8:
		global_position.x = -3*8
	
	if check_tile(Vector2.ZERO, true):
		eat_dot()
	elif check_tile(direction):
		velocity = direction * VELOCITY_FRAMES * speed_multiplier
		update_animated_sprite()
		move_and_slide()
	else :
		if animated_sprite_2d.animation != "death":
			animated_sprite_2d.pause()
	
	if !is_inside_tree():
		return
	for ghost in get_tree().get_nodes_in_group("Ghost"):
		if ghost.current_tile_center() == current_tile_center():
			if ghost.mode == Ghost.Mode.FRIGHTENED:
				ghost.mode = Ghost.Mode.EATEN
				GameManager.score += 200 * consecutive_ghosts_multiplier
				consecutive_ghosts_multiplier *= 2
				AudioManager.play_eat_ghost()
			elif ghost.mode != Ghost.Mode.EATEN:
				for ghost_v in get_tree().get_nodes_in_group("Ghost"):
					ghost_v.queue_free()
				speed_multiplier = 0
				animated_sprite_2d.play("death")
				AudioManager.play_death()
				animated_sprite_2d.animation_finished.connect(GameManager.retry)


func current_tile_center() -> Vector2:
	var current_tile = tile_map.local_to_map(global_position)
	return tile_map.map_to_local(current_tile)

func check_tile(dir: Vector2, ignore_blank:bool = false) -> bool:
	var target_tile = tile_map.local_to_map(global_position + (dir * 4.01))
	var target_tile_atlas = tile_map.get_cell_atlas_coords(target_tile)
	if target_tile_atlas == Vector2i(1,1) || target_tile_atlas == Vector2i(1,6) || target_tile_atlas == Vector2i(0,6):
		if ignore_blank:
			return target_tile_atlas != Vector2i(1,1)
		return true
	return false

func eat_dot() -> void:
	var map_target: Vector2i = tile_map.local_to_map(global_position)
	if tile_map.get_cell_atlas_coords(map_target) == Vector2i(0,6):
		GameManager.score += 50
		if GameManager.round_number < 19:
			GameManager.phase_timer.paused = true
			energizer_timer.start()
			AudioManager.play_fright()
			consecutive_ghosts_multiplier = 1
			speed_multiplier = GameManager.get_pacman_speed_energized()
			for ghost in get_tree().get_nodes_in_group("Ghost"):
				ghost.set_frightened()
		idle_timer.start()
	else:
		GameManager.score += 10
		AudioManager.play_waka()
		idle_timer.start()
	tile_map.set_cell(map_target, 2, Vector2i.ONE)
	GameManager.blank_coords.append(map_target)
	GameManager.dots_eaten += 1

func update_animated_sprite() -> void:
	if velocity.x > 0:
		animated_sprite_2d.play("move_right")
	if velocity.x < 0:
		animated_sprite_2d.play("move_left")
	if velocity.y > 0:
		animated_sprite_2d.play("move_down")
	if velocity.y < 0:
		animated_sprite_2d.play("move_up")

func _on_energizer_timer_timeout() -> void:
	speed_multiplier = GameManager.get_pacman_speed()
	AudioManager.energized = false
	AudioManager.play_siren()

func _on_idle_timer_timeout() -> void:
	for ghost in get_tree().get_nodes_in_group("Ghost"):
		if !ghost.can_escape:
			ghost.can_escape = true
			idle_timer.start()
			return
