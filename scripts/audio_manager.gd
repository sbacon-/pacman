extends Node
@onready var credit: AudioStreamPlayer = $Credit
@onready var death_0: AudioStreamPlayer = $Death0
@onready var death_1: AudioStreamPlayer = $Death1
@onready var eat_dot_0: AudioStreamPlayer = $EatDot0
@onready var eat_dot_1: AudioStreamPlayer = $EatDot1
@onready var eat_fruit: AudioStreamPlayer = $EatFruit
@onready var eat_ghost: AudioStreamPlayer = $EatGhost
@onready var extend: AudioStreamPlayer = $Extend
@onready var eyes: AudioStreamPlayer = $Eyes
@onready var eyes_first_loop: AudioStreamPlayer = $EyesFirstLoop
@onready var fright: AudioStreamPlayer = $Fright
@onready var fright_first_loop: AudioStreamPlayer = $FrightFirstLoop
@onready var intermission: AudioStreamPlayer = $Intermission
@onready var siren_0: AudioStreamPlayer = $Siren0
@onready var siren_0_first_loop: AudioStreamPlayer = $Siren0FirstLoop
@onready var siren_1: AudioStreamPlayer = $Siren1
@onready var siren_1_first_loop: AudioStreamPlayer = $Siren1FirstLoop
@onready var siren_2: AudioStreamPlayer = $Siren2
@onready var siren_2_first_loop: AudioStreamPlayer = $Siren2FirstLoop
@onready var siren_3: AudioStreamPlayer = $Siren3
@onready var siren_3_first_loop: AudioStreamPlayer = $Siren3FirstLoop
@onready var siren_4: AudioStreamPlayer = $Siren4
@onready var siren_4_first_loop: AudioStreamPlayer = $Siren4FirstLoop
@onready var start: AudioStreamPlayer = $Start

signal ghosts_respawned

var wa_ka: bool = false
var siren_phase: int = 0:
	set(value):
		if value != siren_phase:
			siren_phase = value
			if !fright.playing && !fright_first_loop.playing && !eyes.playing && !eyes_first_loop.playing:
				play_siren()
var eyes_count: int = 0:
	set(value):
		eyes_count = value
		if eyes_count == 0:
			print("respawned")
			ghosts_respawned.emit()
var energized: bool = false

func stop_music() -> void:
	stop_sirens()
	fright_first_loop.stop()
	fright.stop()
	eyes_first_loop.stop()
	eyes.stop()

func play_start() -> void:
	stop_music()
	start.play()
	get_tree().paused = true
	await start.finished
	get_tree().paused = false
	play_siren()

func play_waka() -> void:
	if wa_ka:
		eat_dot_0.play()
	else:
		eat_dot_1.play()
	wa_ka = !wa_ka

func play_eat_ghost() -> void:
	stop_music()
	eat_ghost.play()
	get_tree().paused = true
	await eat_ghost.finished
	get_tree().paused = false
	eyes_count += 1
	play_eyes()

func play_eyes() -> void:
	stop_music()
	eyes_first_loop.play()
	await eyes_first_loop.finished
	eyes.play()
	await ghosts_respawned
	stop_music()
	if energized:
		play_fright()
	else:
		play_siren()

func play_fright() -> void:
	energized = true
	stop_music()
	fright_first_loop.play()
	await fright_first_loop.finished
	fright.play()

func play_siren() -> void:
	if eyes.playing || death_0.playing:
		return
	stop_music()
	match siren_phase:
		0:
			siren_0_first_loop.play()
			await siren_0_first_loop.finished
			siren_0.play()
		1:
			siren_1_first_loop.play()
			await siren_1_first_loop.finished
			siren_1.play()
		2:
			siren_2_first_loop.play()
			await siren_2_first_loop.finished
			siren_2.play()
		3:
			siren_3_first_loop.play()
			await siren_3_first_loop.finished
			siren_3.play()
		4:
			siren_4_first_loop.play()
			await siren_4_first_loop.finished
			siren_4.play()

func stop_sirens() -> void:
	siren_0.stop()
	siren_0_first_loop.stop()
	siren_1.stop()
	siren_1_first_loop.stop()
	siren_2.stop()
	siren_2_first_loop.stop()
	siren_3.stop()
	siren_3_first_loop.stop()
	siren_4.stop()
	siren_4_first_loop.stop()

func play_death() -> void:
	stop_music()
	death_0.play()
