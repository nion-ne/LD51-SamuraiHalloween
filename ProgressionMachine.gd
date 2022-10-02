extends AnimationPlayer

var anim_queue = ["wave_2", "wave_3", "wave_4", "wave_5"]
var anim_index = 0


func _ready():
	
	connect("animation_changed", self, "animation_changed")
	connect("animation_finished", self, "animation_finished")
	UTILS.connect("begin_waves", self, "begin")
	
	get_tree().get_nodes_in_group("stage_label")[0].hide()
	
	if UTILS.intro_complete:
		get_tree().get_nodes_in_group("stage_label")[0].show()
		anim_index = 0
		play("wave_1")
		update_stage_label()
	

func update_stage_label():
	get_tree().get_nodes_in_group("stage_label")[0].show()
	get_tree().get_nodes_in_group("stage_label")[0].text = "stage " + str(anim_index + 1) + "/" + str(anim_queue.size() + 1)

func spawn_skeleton(amount = 1):
	
	spawn_enemy("skeleton", amount)

func spawn_ghost(amount = 1):
	
	var map_rect = UTILS.get_map_extents()
	
	spawn_enemy("ghost", amount)
		
func spawn_enemy(type, amount):
	
	var map_rect = UTILS.get_map_extents()
	var new_enemy
	
	for i in range(amount):
		
		match type:
			"ghost": new_enemy = UTILS.GHOST_SCENE.instance()
			"skeleton": new_enemy = UTILS.SKELETON_SCENE.instance()
		
		var lightning_strike = UTILS.LIGHTNING_SCENE.instance()
		randomize()
		var spawn_position_x = rand_range(map_rect.position.x, map_rect.end.x)
		var spawn_position_y = rand_range(map_rect.position.y, map_rect.end.y)
		
		new_enemy.position = Vector2(spawn_position_x, spawn_position_y)
		
		lightning_strike.position = Vector2(spawn_position_x, spawn_position_y)
		
		get_tree().current_scene.add_child(lightning_strike)
		get_tree().get_nodes_in_group("y_sort")[0].add_child(new_enemy)



func wait_for_enemies_clear():
	print("waiting for enemies clear")
	stop(false)
	yield(UTILS, "all_enemies_cleared")
	play()
	print("enemies cleared")

func animation_changed():
	print("starting : " + current_animation)

func animation_finished(anim):
	
	if anim_index == anim_queue.size():
		UTILS.win()
		return
	
	print(anim, " finished")
	play(anim_queue[anim_index])
	anim_index += 1
	update_stage_label()
	
func begin():
	play("wave_1")
	update_stage_label()
