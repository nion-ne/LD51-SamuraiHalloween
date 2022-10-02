extends Area2D

onready var despawn_timer = $DespawnTimer
onready var sprite = $Sprite
onready var explosion_sprite = $ExplosionSprite
onready var explosion_timer = $ExplosionTimer

const MOVE_SPEED = 1.0
const DESPAWN_TIME = 10.0
const EXPLOSION_TIME = 1.0

var move_dir := Vector2(1, 0)

var ready := true

func _ready():
	connect("body_entered", self, "body_entered")
	despawn_timer.connect("timeout", self, "despawn")
	despawn_timer.start(DESPAWN_TIME)
	explosion_sprite.hide()

func _physics_process(delta):
	position += move_dir * MOVE_SPEED

func despawn():
	queue_free()

func body_entered(body):
	if not body.is_in_group("player"):
		return
	
	if not ready:
		return
	ready = false
	
	if UTILS.player.stunned:
		return
	
	UTILS.player_hit()
	
	# explode with particles
	sprite.hide()
	move_dir = Vector2.ZERO
	explosion_timer.start(EXPLOSION_TIME)
	explosion_sprite.show()
	yield(explosion_timer, "timeout")	
	
	despawn()

func set_move_dir(dir):
	move_dir = dir
