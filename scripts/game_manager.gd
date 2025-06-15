extends Node

@onready var score_particle = preload("res://scenes/score_particle.tscn")
@onready var phase_timer: Timer = $PhaseTimer

signal win_sceen_finished

var particles: Node2D
var particle_clear_timer: Timer
var player: CharacterBody2D
var ghosts: Node2D
var tile_map_layer: TileMapLayer

var lives: int = 4
var round_number: int = 1
var ghost_phase: int = 0
var first_fruit_spawned: bool = false
var second_fruit_spawned: bool = false
var extend: bool = false
var blank_coords = []
var dots_eaten: int = 0:
	set(value):
		dots_eaten = value
		if dots_eaten < 244 - 125:
			AudioManager.siren_phase = 0
		elif dots_eaten < 244 - 65:
			AudioManager.siren_phase = 1
		elif dots_eaten < 224 - 30:
			AudioManager.siren_phase = 2
		elif dots_eaten < 224 - 15:
			AudioManager.siren_phase = 3
		else:
			AudioManager.siren_phase = 4
		if dots_eaten >= 244:
			win_screen()
			await win_sceen_finished
			round_number += 1
			blank_coords.clear()
			dots_eaten = 0
			ghost_phase = 0
			phase_timer.paused = false
			first_fruit_spawned = false
			second_fruit_spawned = false
			if round_number == 3:
				get_tree().change_scene_to_file("res://scenes/intermission_1.tscn")
			elif round_number == 6:
				get_tree().change_scene_to_file("res://scenes/intermission_2.tscn")
			elif round_number == 10 || round_number == 14 || round_number == 18:
				get_tree().change_scene_to_file("res://scenes/intermission_3.tscn")
			else:
				get_tree().reload_current_scene()
var score: int = 0:
	set(value):
		value_to_particle(value-score)
		score = value
		if !extend && score > 10000:
			AudioManager.extend.play()
			lives += 1
			extend = true
var game_over: bool = false
var highscore: int = 0


func get_pellet_time() -> float:
	match round_number:
		1: return 6
		2: return 5
		3: return 4
		4: return 3
		5: return 2
		6: return 5
		7, 8: return 2
		9: return 1
		10: return 5
		11: return 2
		12, 13: return 1
		14: return 3
		15, 16, 18: return 1
		_: return 0

func get_pacman_speed() -> float:
	match round_number:
		1: return 1
		2,3,4,17,19,20: return 1.25
		_: return 1.125
func get_pacman_speed_energized() -> float:
	match round_number:
		1: return 1.125
		2,3,4: return 1.1875
		_: return 1.25

func get_ghost_speed() -> float:
	match round_number:
		1: return 0.9375
		2,3,4: return 1.0625
		_: return 1.1875
func get_ghost_speed_frightened() -> float:
	match round_number:
		1: return 0.625
		2,3,4: return 0.6875
		_: return 0.75
func get_ghost_speed_tunnel() -> float:
	match round_number:
		1: return 0.5
		2,3,4: return 0.5625
		_: return 0.625
func get_ghost_speed_elroy() -> float:
	var speed_up_1: Array[float] = [1, 1.125,1.25]
	var speed_up_2: Array[float] = [1.0625, 1.1875, 1.3125]
	match round_number:
		1:
			if dots_eaten>= 234:
				return speed_up_2[0]
			if dots_eaten>= 224:
				return speed_up_1[0]
			return get_ghost_speed()
		2,3,4: 
			if dots_eaten>= 234:
				return speed_up_2[1]
			if dots_eaten>= 224:
				return speed_up_1[1]
			return get_ghost_speed()
		_:
			if dots_eaten>=234:
				return speed_up_2[2]
			if dots_eaten>=224:
				return speed_up_1[2]
			return get_ghost_speed()

func value_to_particle(value: int):
	match value:
		200:
			new_score_particle(Rect2(0,128,16,16))
		400:
			new_score_particle(Rect2(16,128,16,16))
		800:
			new_score_particle(Rect2(32,128,16,16))
		1600:
			new_score_particle(Rect2(48,128,16,16))
		100:
			new_score_particle(Rect2(0,144,16,16)).global_position = Vector2(112,164)
		300:
			new_score_particle(Rect2(16,144,16,16)).global_position = Vector2(112,164)
		500:
			new_score_particle(Rect2(32,144,16,16)).global_position = Vector2(112,164)
		700:
			new_score_particle(Rect2(48,144,16,16)).global_position = Vector2(112,164)
		1000:
			new_score_particle(Rect2(64,144,18,16)).global_position = Vector2(112,164)
		2000:
			new_score_particle(Rect2(62,160,20,16)).global_position = Vector2(112,164)
		3000:
			new_score_particle(Rect2(62,176,20,16)).global_position = Vector2(112,164)
		5000:
			new_score_particle(Rect2(62,192,20,16)).global_position = Vector2(112,164)

func new_score_particle(texture_region: Rect2) -> GPUParticles2D:
	var score_particle_instance = score_particle.instantiate()
	particles.add_child(score_particle_instance)
	score_particle_instance.global_position = player.global_position
	score_particle_instance.texture.region = texture_region
	score_particle_instance.emitting = true
	particle_clear_timer.start()
	return score_particle_instance

func get_phase_wait_time(phase: int) -> float:
	match round_number:
		1:
			return [7,20,8,20,5,20,5].get(phase)
		2,3,4:
			return [7,20,7,20,5,1033,0.016].get(phase)
		_:
			return [5,20,5,20,5,1037,0.016].get(phase)

func _on_phase_timer_timeout() -> void:
	if ghost_phase <= 6:
		phase_timer.start(GameManager.get_phase_wait_time(ghost_phase))
	if ghost_phase%2 == 0:
		for ghost in get_tree().get_nodes_in_group("Ghost"):
			if ghost.mode == Ghost.Mode.CHASE:
				ghost.mode = Ghost.Mode.SCATTER
			else:
				ghost.return_mode = Ghost.Mode.SCATTER
			ghost.target_direction *= -1
			ghost.last_changed = ghost.current_tile_center()
	else:
		for ghost in get_tree().get_nodes_in_group("Ghost"):
			if ghost.mode == Ghost.Mode.SCATTER:
				ghost.mode = Ghost.Mode.CHASE
			else:
				ghost.return_mode = Ghost.Mode.CHASE
			ghost.target_direction *= -1
			ghost.last_changed = ghost.current_tile_center()
	ghost_phase+=1

func retry() -> void:
	AudioManager.death_0.stop()
	AudioManager.death_1.play()
	GameManager.lives -= 1
	if lives >= 0:
		ghost_phase = 0
		phase_timer.paused = false
		await get_tree().create_timer(1.0).timeout
		get_tree().reload_current_scene()
	else:
		highscore = max(score,highscore)
		game_over = true
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func win_screen() -> void:
	AudioManager.stop_music()
	player.animated_sprite_2d.play("idle")
	get_tree().paused = true
	await get_tree().create_timer(1.5).timeout
	ghosts.visible = false
	tile_map_layer.modulate = Color(100.0,100.0,100.0)
	
	await get_tree().create_timer(0.25).timeout
	tile_map_layer.modulate = Color(1.0,1.0,1.0)
	await get_tree().create_timer(0.25).timeout
	tile_map_layer.modulate = Color(100.0,100.0,10)
	await get_tree().create_timer(0.25).timeout
	tile_map_layer.modulate = Color(1.0,1.0,1.0)
	await get_tree().create_timer(0.25).timeout
	tile_map_layer.modulate = Color(100.0,100.0,100.0)
	await get_tree().create_timer(0.25).timeout
	tile_map_layer.modulate = Color(1.0,1.0,1.0)
	await get_tree().create_timer(0.25).timeout
	tile_map_layer.modulate = Color(100.0,100.0,100.0)
	await get_tree().create_timer(0.25).timeout
	tile_map_layer.modulate = Color(1.0,1.0,1.0)
	await get_tree().create_timer(0.5).timeout
	
	win_sceen_finished.emit()

func init_values() -> void:
	score = 0
	lives = 4
	round_number = 1
	extend = false
	blank_coords.clear()
	dots_eaten = 0
