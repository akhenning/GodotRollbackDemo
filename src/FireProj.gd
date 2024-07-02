extends Area2D

signal _disable_proj

@onready var fire_timer = $FireProjTimer
@onready var animation_player = $FireAnimation
var _player = null
var active = true

func _ready():
	pass
	
func get_master():
	return _player

func get_damage_properties():
	if not active:
		return 0
	else:
		return 10


func _network_spawn(data: Dictionary) -> void:
	_player = data['player']
	global_position = data['position'] +  Vector2(25, -2)
	fire_timer.start()
	animation_player.play("fire_loop")

# input is not used, but seems to be needed
func _network_process(input: Dictionary) -> void:
	if active:
		for area in get_overlapping_areas():
			#print("overlapping area: %s" % area)
			if area.get_path() != _player:
				#print("Overlapping with something new. Player: %s" % _player)
				fire_timer.start(20)
				active = false
				if area.has_method("send_hurt"):
					area.send_hurt(10)
			#else:
			#	print("Overlapping with player that summoned projectile")
	#			pass
	#	if area.get_path() != _player:
	#		print("Overlapping with something new. Player: %s" % _player)
	#		fire_timer.stop()
	#		fire_timer.start(20)
	
	var velocity = Vector2(4, 0)
	#global_position += velocity
	#position += velocity
	translate(velocity)
	#move_and_slide()

func _on_fire_proj_timer_timeout():
	SyncManager.despawn(self)


func _save_state() -> Dictionary:
	var state = {
		position = position,
		active = active,
	}
	#Utils.save_node_transform_state(self, state)
	return state

func _load_state(state: Dictionary) -> void:
	#Utils.load_node_transform_state(self, state)
	position = state['position']
	active = state['active']
	#sync_to_physics_engine()
	

