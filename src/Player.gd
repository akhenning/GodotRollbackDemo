extends SGArea2D

signal hurt (damage)

@export var input_prefix := "p1_"
@onready var animation_player = $DemoAnimations
@onready var anim_timer = $PlayerAnimTimer
@onready var collision_shape = $CollisionShape2D

const MOVEMENT_SPEED := 65536*8

const FireProj = preload("res://src/fire_proj.tscn")

enum Anim {
	NONE,
	FIRE,
	HURT,
}
# Use this to test if getting hit causes the position to be in a different place after rollback
#var got_hit_once = false

var animations = {}
var curr_anim = Anim.NONE

func _ready():
	animations[Anim.FIRE] = 30
	animations[Anim.HURT] = 40
	animation_player.play("riki_idle")
	#fixed_position = SGFixed.vector2(200*65536,400*65536)

func _get_local_input() -> Dictionary:
	#var input_vector = Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down")
	var l = Input.is_action_pressed(input_prefix + "left")
	var r = Input.is_action_pressed(input_prefix + "right")
	var u = Input.is_action_pressed(input_prefix + "up")
	var d = Input.is_action_pressed(input_prefix + "down")
	var input := {}
	# left + right and up + down are mutually exclusive
	if l and not r:
		input["l"] = true
	if r and not l:
		input["r"] = true
	if u and not d:
		input["u"] = true
	if d and not u:
		input["d"] = true
	if Input.is_action_pressed(input_prefix + "k"):
		input["k"] = true
	if Input.is_action_pressed(input_prefix + "p"):
		input["p"] = true
	if Input.is_action_pressed(input_prefix + "s"):
		input["s"] = true
	if Input.is_action_pressed(input_prefix + "h"):
		input["h"] = true
	
	#if input_vector != Vector2.ZERO:
	#	input["input_vector"] = input_vector
	
	return input

func _predict_remote_input(previous_input: Dictionary, _ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	
	return input

func _network_process(input: Dictionary) -> void:
	if curr_anim != Anim.NONE:
		if (curr_anim == Anim.FIRE and anim_timer.ticks_left == 20):
			SyncManager.spawn("FireProj", get_parent(), FireProj, { x = fixed_position.x, y = fixed_position.y, player = self.get_path() })
	else:		
		# Can only input things in idle (temp)
		if input.is_empty():
			return
		var x = 0
		if input.has("l"):
			x -= MOVEMENT_SPEED
		if input.has("r"):
			x += MOVEMENT_SPEED
		var y = 0
		if input.has("u"):
			y -= MOVEMENT_SPEED
		if input.has("d"):
			y += MOVEMENT_SPEED
		fixed_position.iadd(SGFixed.vector2(x, y))
		
		#if fixed_position.x > 1000:
		#	fixed_position.x = 1000
		#elif fixed_position.x < 0:
		#	fixed_position.x = 0
		#if fixed_position.y > 1000:
		#	fixed_position.y = 1000
		#elif fixed_position.y < 0:
		#	fixed_position.y = 0
		
		#if Settings.is_server_or_client == "CLIENT" and Engine.max_fps != 50:
		#	push_warning("Changing FPS")
		#	Engine.max_fps = 59
		#	await get_tree().create_timer(1).timeout
		
		if input.has("s"):
			curr_anim = Anim.FIRE
			anim_timer.start(animations[curr_anim])
			animation_player.play("riki_fire")
		sync_to_physics_engine()

func _save_state() -> Dictionary:
	return {
		x = fixed_position.x,
		y = fixed_position.y,
		curr_anim = curr_anim,
	}

# Client detects no collisions. Server detects two and rolls back one?
# Hmm. The log seems to think that Server is right? Huh. Oh, thats just because 
# it is from the server's perspective. It is wrong.
# So...
# Tap down so the projection hits the projectile.
# Detects collision -> keeps going -> realizes no down input was made -> rolls back to before collision -> detects another collision??
func _load_state(state: Dictionary) -> void:
	#print(state['curr_anim'])
	#print(curr_anim)
	#print(state['curr_anim'] == Anim.NONE)
	#if (state['curr_anim'] == Anim.HURT and curr_anim == Anim.NONE):
	#	push_warning ( "Rolling back to a state of being hurt.")
	#if (state['curr_anim'] == Anim.NONE and curr_anim == Anim.HURT):
	#	push_warning ( "ROLLING BACK AWAY FROM HURT STATE.")
	#	if (fixed_position != state['position']):
	#		push_warning ( "ALSO ROLLING POSITION FROM ",fixed_position," TO ",state['position'])
	#	else:
	#		push_warning ( "BUT, NOT ROLLING BACK POSITION.")
			
	fixed_position.x = state['x']
	fixed_position.y = state['y']
	curr_anim = state['curr_anim']
	sync_to_physics_engine()

func send_hurt(_damage,_f_position):
#	if curr_anim != Anim.HURT:
#		#print("Sending hurt signal")
#		emit_signal("hurt", damage,f_position)

	#var msg = "Collision at player = "
	#msg += str(position)
	#msg += " and fireball = "
	#msg += str(_f_position)
	#msg += " FROM "
	#msg += Settings.is_server_or_client
	#push_warning ( msg )
	#if got_hit_once:
	#	return
	#got_hit_once = true
#func _on_hurt(_damage,f_position):
	#print("HURT AT POSITION %s" % position)
	if curr_anim != Anim.HURT:
		#print("###HURTING FOR %s DAMAGE" % damage)
		curr_anim = Anim.HURT
		anim_timer.start(animations[curr_anim])
		animation_player.play("riki_hurt")


func _on_player_anim_timer_timeout():
	curr_anim = Anim.NONE
	animation_player.play("riki_idle")
	
