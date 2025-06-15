extends Node2D

@onready var fruit_scene = preload("res://scenes/fruit.tscn")
@onready var energizer_blink: Node2D = $TileMapLayer/EnergizerBlink
@onready var particles: Node2D = $Particles

func _ready() -> void:
	GameManager.particles = particles
	GameManager.particle_clear_timer = $Particles/ParticleClearTimer
	GameManager.player = $Pacman
	GameManager.tile_map_layer = $TileMapLayer
	GameManager.ghosts = $Ghosts
	GameManager.ghost_phase = 0
	GameManager._on_phase_timer_timeout()
	AudioManager.play_start()

func _process(_delta: float) -> void:
	if GameManager.dots_eaten > 70 && !GameManager.first_fruit_spawned:
		spawn_fruit()
		GameManager.first_fruit_spawned = true
	if GameManager.dots_eaten > 140 && !GameManager.second_fruit_spawned:
		spawn_fruit()
		GameManager.second_fruit_spawned = true

func spawn_fruit() -> void:
	var fruit_instance = fruit_scene.instantiate()
	add_child(fruit_instance)
	fruit_instance.global_position = Vector2(112,164)
	match GameManager.round_number:
		1: #Cherry
			fruit_instance.score_value = 100
			fruit_instance.set_region_x(32)
		2: #Strawberry
			fruit_instance.score_value = 300
			fruit_instance.set_region_x(48)
		3, 4: #Orange
			fruit_instance.score_value = 500
			fruit_instance.set_region_x(64)
		5, 6: #Apple
			fruit_instance.score_value = 700
			fruit_instance.set_region_x(80)
		7, 8: #Melon
			fruit_instance.score_value = 1000
			fruit_instance.set_region_x(96)
		9, 10: #Galaxian
			fruit_instance.score_value = 2000
			fruit_instance.set_region_x(112)
		11, 12: #Bell
			fruit_instance.score_value = 3000
			fruit_instance.set_region_x(128)
		_: #Key
			fruit_instance.score_value = 5000
			fruit_instance.set_region_x(128)

func _on_respawner_body_entered(body: Node2D) -> void:
	if body is Ghost && body.mode == Ghost.Mode.EATEN:
		body.mode = Ghost.Mode.ESCAPE
		AudioManager.eyes_count -= 1


func _on_blink_timer_timeout() -> void:
	energizer_blink.visible = !energizer_blink.visible

func _on_particle_clear_timer_timeout() -> void:
	for particle in particles.get_children():
		if particle is GPUParticles2D:
			particle.queue_free()
