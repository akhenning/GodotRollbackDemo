extends Area2D

signal hurt (damage)

@export var input_prefix := "p1_"
@onready var animation_player = $DemoAnimations
@onready var anim_timer = $PlayerAnimTimer

const FireProj = preload("res://src/fire_proj.tscn")

enum Anim {
	NONE,
	FIRE,
	HURT,
}


var animations = {}
var curr_anim = Anim.NONE

func _ready():
	animations[Anim.FIRE] = 30
	animations[Anim.HURT] = 40
	animation_player.play("riki_idle")

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

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	
	return input

func _network_process(input: Dictionary) -> void:
	#var highest_damage_overlap = 0
	#for area in get_overlapping_areas():
		#print("overlapping area: %s" % area)
		#print("Masters are %s" % self.get_path())
		#print("and %s" % area.get_master())
	#	if area.has_method("get_damage_properties") and area.get_master() != self.get_path():
	#		var damage = area.get_damage_properties()
	#		if damage > highest_damage_overlap:
	#			highest_damage_overlap = damage
			#print("Overlapping with hitbox. Has damage value: %s" % area.get_damage_properties())
			
	#	else:
	#		print("Characters are overlapping.")
	#if highest_damage_overlap != 0:
	#	pass
		#self.hurt(highest_damage_overlap)
	
	if curr_anim != Anim.NONE:
		if (curr_anim == Anim.FIRE and anim_timer.ticks_left == 20):
			SyncManager.spawn("FireProj", get_parent(), FireProj, { position = global_position, player = self.get_path() })
	else:		
		#print(input)
		# Can only input things in idle (temp)
		if input.is_empty():
			return
		var x = 0
		if input.has("l"):
			x -= 8
		if input.has("r"):
			x += 8
		var y = 0
		if input.has("u"):
			y -= 8
		if input.has("d"):
			y += 8
		translate(Vector2(x, y))
		
		if input.has("s"):
			curr_anim = Anim.FIRE
			anim_timer.start(animations[curr_anim])
			animation_player.play("riki_fire")

func _save_state() -> Dictionary:
	return {
		position = position,
		curr_anim = curr_anim,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']
	curr_anim = state['curr_anim']

func send_hurt(damage):
	if curr_anim != Anim.HURT:
		#print("Sending hurt signal")
		emit_signal("hurt", damage)


func _on_hurt(damage):
	if curr_anim != Anim.HURT:
		#print("###HURTING FOR %s DAMAGE" % damage)
		curr_anim = Anim.HURT
		anim_timer.start(animations[curr_anim])
		animation_player.play("riki_hurt")


func _on_player_anim_timer_timeout():
	curr_anim = Anim.NONE
	animation_player.play("riki_idle")
	
