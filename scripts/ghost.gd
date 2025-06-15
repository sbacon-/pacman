extends CharacterBody2D
class_name Ghost

enum Mode {CAGE, ESCAPE, CHASE, SCATTER, FRIGHTENED, EATEN}

const VELOCITY_FRAMES = 60

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var target: Marker2D = $Target

@export var tile_map: TileMapLayer
@export var navigation_map: TileMapLayer
@export var player: CharacterBody2D

@export var scatter_pos: Vector2i
@onready var frightened_timer: Timer = $FrightenedTimer

var mode: Mode = Mode.CAGE
var return_mode: Mode
var can_escape: bool = false
var tunnel_tiles: Array[Vector2i] = []

var direction: Vector2 = Vector2.UP
var target_direction: Vector2 = Vector2.ZERO
var last_changed: Vector2
var speed_multiplier: float = 0.9375

func _ready() -> void:
	set_target_position(scatter_pos)
	for x in range(-4,5):
		tunnel_tiles.append(Vector2i(x,17))
	for x in range(23,32):
		tunnel_tiles.append(Vector2i(x,17))
	for x in range(11,17):
		for y in range(16,19):
			tunnel_tiles.append(Vector2i(x,y))
	tunnel_tiles.append(Vector2i(13,15))
	tunnel_tiles.append(Vector2i(14,15))

func _physics_process(_delta: float) -> void:
	match mode:
		Mode.CAGE:
			cage_movement()
			if can_escape:
				mode = Mode.ESCAPE
		Mode.ESCAPE:
			escape_movement()
		Mode.CHASE:
			chase_movement()
		Mode.SCATTER:
			scatter_movement()
		Mode.FRIGHTENED:
			frightened_movement()
		Mode.EATEN:
			eaten_movement()
		
	if global_position.x < -3*8:
		global_position.x = 30*8
	if global_position.x > 30*8:
		global_position.x = -3*8
	
	#STUCK GHOSTS
	if velocity == Vector2.ZERO:
		last_changed = Vector2(-1,-1)
	if tunnel_tiles.slice(18,-2).has(tile_map.local_to_map(global_position)) && (mode==Mode.CHASE || mode==Mode.SCATTER):
		return_mode = mode
		mode = Mode.ESCAPE
		print(name)

func current_tile_center() -> Vector2:
	var current_tile = tile_map.local_to_map(global_position)
	return tile_map.map_to_local(current_tile)

func check_tile(dir: Vector2, ignore_door:bool = true) -> bool:
	var target_tile = tile_map.local_to_map(global_position + (dir * 4.01))
	var target_tile_atlas = tile_map.get_cell_atlas_coords(target_tile)
	if target_tile_atlas == Vector2i(1,1) || target_tile_atlas == Vector2i(1,6) || target_tile_atlas == Vector2i(0,6) || target_tile_atlas == Vector2i(1,4):
		if ignore_door:
			return target_tile_atlas != Vector2i(1,4)
		return true
	return false

func get_nav_tile_atlas() -> Vector2i:
	var current_tile = navigation_map.local_to_map(global_position)
	return navigation_map.get_cell_atlas_coords(current_tile)
	

func update_animated_sprite() -> void:
	if mode == Mode.FRIGHTENED:
		if frightened_timer.time_left < 2:
			animated_sprite_2d.play("frightend_expire")
		else:
			animated_sprite_2d.play("frightend")
		return
	if mode == Mode.EATEN:
		if velocity.x > 0:
			animated_sprite_2d.play("move_right_eaten")
		if velocity.x < 0:
			animated_sprite_2d.play("move_left_eaten")
		if velocity.y > 0:
			animated_sprite_2d.play("move_down_eaten")
		if velocity.y < 0:
			animated_sprite_2d.play("move_up_eaten")
		return
	if velocity.x > 0:
		animated_sprite_2d.play("move_right")
	if velocity.x < 0:
		animated_sprite_2d.play("move_left")
	if velocity.y > 0:
		animated_sprite_2d.play("move_down")
	if velocity.y < 0:
		animated_sprite_2d.play("move_up")

func set_target_position(tilemap_pos: Vector2i) -> void:
	target.global_position = tile_map.map_to_local(tilemap_pos)

func cage_movement() -> void:
	if global_position.y <= 135:
		velocity.y = speed_multiplier*VELOCITY_FRAMES
	if global_position.y >= 145 || velocity == Vector2.ZERO:
		velocity.y = -speed_multiplier*VELOCITY_FRAMES
	update_animated_sprite()
	move_and_slide()

func escape_movement() -> void:
	if abs(global_position.x - 112) < 1 :
		velocity.x = 0
		global_position.x = 112
		velocity.y = -speed_multiplier*VELOCITY_FRAMES
	else:
		velocity.y = 0
		velocity.x = (1 if 112>=global_position.x else -1)*speed_multiplier*VELOCITY_FRAMES
	if global_position.y <= 116:
		global_position.y = 116
		velocity = Vector2.ZERO
		target_direction = Vector2.LEFT
		last_changed = current_tile_center()
		if mode != Mode.FRIGHTENED:
			mode = return_mode
		else:
			return_mode = Mode.SCATTER if (GameManager.ghost_phase-1)%2 == 0 else Mode.CHASE
	update_animated_sprite()
	move_and_slide()

func chase_movement() -> void:
	pass

func scatter_movement() -> void:
	set_target_position(scatter_pos)
	if last_changed != current_tile_center():
		var check_dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
		if navigation_map.get_cell_atlas_coords(navigation_map.local_to_map(current_tile_center())) == Vector2i(3,5):
			check_dirs = [Vector2.RIGHT, Vector2.LEFT]
		var valid_dirs = []
		for dir in check_dirs:
			if dir == direction*-1:
				continue
			if check_tile(dir):
				valid_dirs.append(dir)
		if valid_dirs.size() > 0:
			var min_dist = 1000
			var new_dir = Vector2.ZERO
			for dir in valid_dirs:
				var distance_to_target = target.global_position.distance_to(global_position+(dir*8))
				if distance_to_target < min_dist:
					min_dist = distance_to_target
					new_dir = dir
			target_direction = new_dir
		last_changed = current_tile_center()
	if target_direction != direction:
		if direction == target_direction * -1:
			direction = target_direction
		elif global_position.distance_to(current_tile_center()) < 1 && check_tile(target_direction) || global_position == Vector2(112,116) :
			if target_direction == Vector2.RIGHT || target_direction == Vector2.LEFT:
				global_position.y = current_tile_center().y
				direction = target_direction
			if target_direction == Vector2.UP || target_direction == Vector2.DOWN:
				global_position.x = current_tile_center().x
				direction = target_direction
	if check_tile(direction):
		velocity = direction * VELOCITY_FRAMES * speed_multiplier
		update_animated_sprite()
		move_and_slide()
	else:
		global_position = current_tile_center()
		last_changed = Vector2(-1,-1)

func frightened_movement() -> void:
	if return_mode == Mode.CAGE || return_mode == Mode.ESCAPE:
		if can_escape:
			return_mode = Mode.ESCAPE
			escape_movement()
		else:
			cage_movement()
		return
	if last_changed != current_tile_center():
		var check_dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
		if navigation_map.get_cell_atlas_coords(navigation_map.local_to_map(current_tile_center())) == Vector2i(3,5):
			check_dirs = [Vector2.RIGHT, Vector2.LEFT]
		var valid_dirs = []
		for dir in check_dirs:
			if dir == direction*-1:
				continue
			if check_tile(dir):
				valid_dirs.append(dir)
		if valid_dirs.size() > 0:
			target_direction = valid_dirs.pick_random()
		last_changed = current_tile_center()
	if target_direction != direction:
		if direction == target_direction * -1:
			direction = target_direction
		elif global_position.distance_to(current_tile_center()) < 1 && check_tile(target_direction) || global_position == Vector2(112,116) :
			if target_direction == Vector2.RIGHT || target_direction == Vector2.LEFT:
				global_position.y = current_tile_center().y
				direction = target_direction
			if target_direction == Vector2.UP || target_direction == Vector2.DOWN:
				global_position.x = current_tile_center().x
				direction = target_direction
	if check_tile(direction):
		velocity = direction * VELOCITY_FRAMES * speed_multiplier
		update_animated_sprite()
		move_and_slide()
	else:
		global_position = current_tile_center()
		last_changed = Vector2(-1,-1)

func eaten_movement() -> void:
	target.global_position = Vector2(112,140)
	if last_changed != current_tile_center():
		var check_dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
		if navigation_map.get_cell_atlas_coords(navigation_map.local_to_map(current_tile_center())) == Vector2i(3,5):
			check_dirs = [Vector2.RIGHT, Vector2.LEFT]
		var valid_dirs = []
		for dir in check_dirs:
			if dir == direction*-1:
				continue
			if check_tile(dir,false):
				valid_dirs.append(dir)
		if valid_dirs.size() > 0:
			var min_dist = 1000
			var new_dir = Vector2.ZERO
			for dir in valid_dirs:
				var distance_to_target = target.global_position.distance_to(global_position+(dir*8))
				if distance_to_target < min_dist:
					min_dist = distance_to_target
					new_dir = dir
			target_direction = new_dir
		last_changed = current_tile_center()
	if target_direction != direction:
		if direction == target_direction * -1:
			direction = target_direction
		elif global_position.distance_to(current_tile_center()) < 1 && check_tile(target_direction,false) || global_position == Vector2(112,116) :
			if target_direction == Vector2.RIGHT || target_direction == Vector2.LEFT:
				global_position.y = current_tile_center().y
				direction = target_direction
			if target_direction == Vector2.UP || target_direction == Vector2.DOWN:
				global_position.x = current_tile_center().x
				direction = target_direction
	if check_tile(direction, false):
		velocity = direction * VELOCITY_FRAMES * speed_multiplier
		update_animated_sprite()
		move_and_slide()
	else:
		global_position = current_tile_center()
		last_changed = Vector2(-1,-1)

func set_frightened() -> void:
	if mode != Mode.EATEN:
		frightened_timer.wait_time = GameManager.get_pellet_time()
		frightened_timer.start()
		target_direction *= -1
		if mode != Mode.FRIGHTENED:
			return_mode = mode
		mode = Mode.FRIGHTENED

func _on_frightened_timer_timeout() -> void:
	GameManager.phase_timer.paused = false
	if mode != Mode.EATEN:
		mode = return_mode
