extends Node2D

onready var BULLET_SCENE = load("res://Bullet.tscn")
onready var SLICE_FX_SCENE = load("res://fx/SliceFX.tscn")
onready var HEALTH_PIP_SCENE = load("res://fx/HealthPip.tscn")
onready var EXPLOSION_SCENE = load("res://fx/Explosion.tscn")
onready var LIGHTNING_SCENE = load("res://fx/LightningStrike.tscn")

onready var GHOST_SCENE = load("res://enemies/Ghost.tscn")
onready var SKELETON_SCENE = load("res://enemies/Skeleton.tscn")

#Main nodes
var player
var BG
var light_ray

#UI
onready var timer_label = get_tree().get_nodes_in_group("timer_label")[0]
onready var time_bar = get_tree().get_nodes_in_group("time_bar")[0]
onready var global_timer = Timer.new()
onready var health_bar = get_tree().get_nodes_in_group("health_bar")[0]

const PLAYER_STUN_TIME = 0.2
const timer_gameover_text = ["OH NO", "*@J;$", "hElP?", "uwu", "ouch...", "Et tu, Brute?", "aaaaaaaaaaaaaaaaa"]

var weapon_ready := false
var time := 10.0
var total_health := 8
var game_over_input := false
var paused := false
var debug := false
var attacking = false
var intro_complete := false

signal player_hit
signal player_recover
signal all_enemies_cleared
signal begin_waves

#signal screen_shake

func _ready():
	add_child(global_timer)
	setup()
	
	global_timer.connect("timeout", self, "global_timeout")
	

func setup():
	BG = get_tree().get_nodes_in_group("BG")[0]
	player = get_tree().get_nodes_in_group("player")[0]
	light_ray = get_tree().get_nodes_in_group("light_ray")[0]
	
	for c in health_bar.get_node("%HealthContainer").get_children():
		c.queue_free()
	for i in range(total_health):
		health_bar.get_node("%HealthContainer").add_child(HEALTH_PIP_SCENE.instance())
	
	global_timer.start(10.0)
	timer_label.get_node("AnimationPlayer").play("RESET")
	
	if intro_complete:
		get_tree().get_nodes_in_group("scarecrow")[0].queue_free()
	
	UI.show()
	print("setup")

func _process(delta):
	
	if not global_timer.is_stopped():
		timer_label.text = str(global_timer.time_left).pad_decimals(2) + " seconds"
		time_bar.get_node("TimeFill").rect_scale.x = 1 - global_timer.time_left / 10
	
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	get_tree().get_nodes_in_group("enemy_count_label")[0].text = "enemies " + str(enemy_count)

func global_timeout():
	global_timer.stop()
	timer_label.text = "WEAPON READY"
	timer_label.get_node("AnimationPlayer").play("flash")
	weapon_ready = true

func activate_weapon():
	weapon_ready = false
	player.active = false
	attacking = true
	get_tree().call_group("enemies", "deactivate")
	
	get_tree().call_group("bullets", "queue_free")
	
	yield(get_tree().create_timer(1.5), "timeout")
	
	var start_pos = player.position
	
	for target in get_tree().get_nodes_in_group("tagged"):
		
		var prev_player_pos = player.position
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(player, "position", target.position, 0.68)
		yield(tween, "finished")
		
		var new_slice = SLICE_FX_SCENE.instance()
		new_slice.add_to_group("slices")
		new_slice.points[0] = prev_player_pos - new_slice.position
		new_slice.points[1] = player.position - new_slice.position
		get_tree().current_scene.add_child(new_slice)
		
		# Target hecking explodes or something
		var explosion = EXPLOSION_SCENE.instance()
		explosion.position = player.position
		explosion.add_to_group("explosions")
		get_tree().current_scene.add_child(explosion)
		
		if target.is_in_group("scarecrow"):
			emit_signal("begin_waves")
			intro_complete = true
		
		target.queue_free()
		
	
	var tween = get_tree().create_tween()
	tween.tween_property(player, "position", start_pos, 0.5)
	
	
	yield(get_tree().create_timer(0.5), "timeout")
	
	for c in get_tree().get_nodes_in_group("slices"):
		c.queue_free()
	
	for e in get_tree().get_nodes_in_group("explosions"):
		e.queue_free()
	
	global_timer.start(10.0)
	timer_label.get_node("AnimationPlayer").play("RESET")
	weapon_ready = false
	attacking = false
	player.activate()
	get_tree().call_group("enemies", "activate")
	
	if get_tree().get_nodes_in_group("enemies").empty():
		emit_signal("all_enemies_cleared")
	

func get_map_extents():
	return BG.get_global_rect()

func is_position_in_bounds(pos):
	var extents = get_map_extents()
	if pos.x < extents.position.x: return false
	if pos.x > extents.end.x: return false
	if pos.y < extents.position.y: return false
	if pos.y > extents.end.y: return false
	return true

func spawn_bullet(pos, dir):
	var new_bullet = BULLET_SCENE.instance()
	new_bullet.position = pos
	new_bullet.set_move_dir(dir)
	
	get_tree().current_scene.add_child(new_bullet)

func target(pos):
	light_ray.position = pos
	
	light_ray.show()
	yield(get_tree().create_timer(0.5), "timeout")
	light_ray.hide()
	
func player_hit():
	emit_signal("player_hit")
	var health_pips = health_bar.get_node("%HealthContainer").get_children()
	if not health_pips.empty():
		if health_pips.size() <= 1:
			health_pips.front().queue_free()
			
			game_over()
			
			return
		health_pips.front().queue_free()
	
	yield(get_tree().create_timer(PLAYER_STUN_TIME), "timeout")
	emit_signal("player_recover")
	
func game_over():
	print("GAME OVER")
	global_timer.stop()
	
	player.active = false
	randomize()
	

	
	timer_label.text = timer_gameover_text[randi() % timer_gameover_text.size()]
	yield(get_tree().create_timer(2), "timeout")
	
	
	get_tree().change_scene("res://GameOver.tscn")
	yield(get_tree().create_timer(0.1), "timeout")
	UI.hide()
	
	yield(get_tree().create_timer(1.5), "timeout")
	game_over_input = true

func win():
	print("YOU WIN")
	global_timer.stop()
	player.active = false
	
	get_tree().change_scene("res://WinScreen.tscn")
	UI.hide()
	
	yield(get_tree().create_timer(5), "timeout")
	game_over_input = true
	
func _input(event):
	if game_over_input:
		if event.is_action_pressed("action"):
			
			weapon_ready = false
			global_timer.stop()
			
			game_over_input = false
			get_tree().change_scene("res://Main.tscn")
			yield(get_tree(), "idle_frame")
			setup()
	
	if event.is_action_pressed("debug_1") and debug:
		win()
	if event.is_action_pressed("debug_2") and debug:
		game_over()
	

