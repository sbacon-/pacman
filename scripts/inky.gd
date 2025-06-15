extends Ghost

@export var blinky: Ghost

func _process(_delta: float) -> void:
	if GameManager.round_number == 1 && GameManager.dots_eaten > 30:
		can_escape = true
	elif GameManager.round_number >=2 :
		can_escape = true

func _physics_process(delta: float) -> void:
	if tunnel_tiles.has(tile_map.local_to_map(global_position)):
		speed_multiplier = GameManager.get_ghost_speed_tunnel()
	elif mode == Mode.FRIGHTENED:
		speed_multiplier = GameManager.get_ghost_speed_frightened()
	elif mode == Mode.EATEN:
		speed_multiplier = GameManager.get_ghost_speed()*2
	else:
		speed_multiplier = GameManager.get_ghost_speed()
	super._physics_process(delta)

func chase_movement() -> void:
	target.global_position = blinky.current_tile_center() + Vector2((player.current_tile_center()+player.direction*16)-blinky.current_tile_center())*2
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
