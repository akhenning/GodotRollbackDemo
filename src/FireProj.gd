extends SGArea2D

signal _disable_proj

@onready var fire_timer = $FireProjTimer
@onready var animation_player = $FireAnimation
var _player = null
var active = true

const ONE_PIXEL := int(65536)

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
	print(data)
	#print(data['position'])
	print(fixed_position)
	#print(data['position'].x)
	print(fixed_position.x)
	#global_position = data['position'] + Vector2(25, -2)
	fixed_position.x = data['x']
	fixed_position.y = data['y']
	fixed_position.x += 25*ONE_PIXEL
	fixed_position.y += -2*ONE_PIXEL
	fire_timer.start()
	animation_player.play("fire_loop")
	sync_to_physics_engine()

# input is not used, but seems to be needed
func _network_process(_input: Dictionary) -> void:
	if active:
		for area in get_overlapping_areas():
			#print("overlapping area: %s" % area)
			if area.get_path() != _player:
				#print("Overlapping with something new. Player: %s" % _player)
				#push_warning ( "Projectile is overlapping with something.")
				fire_timer.start(20)
				active = false
				if area.has_method("send_hurt"):
					area.send_hurt(10,position)
			#else:
			#	print("Overlapping with player that summoned projectile")
	#			pass
	#	if area.get_path() != _player:
	#		print("Overlapping with something new. Player: %s" % _player)
	#		fire_timer.stop()
	#		fire_timer.start(20)
	
	#var velocity = Vector2(4, 0)
	#global_position += velocity
	fixed_position.x += 4*ONE_PIXEL
	sync_to_physics_engine()

func _on_fire_proj_timer_timeout():
	SyncManager.despawn(self)

# when I was on top of her trying to fire when she was also firing, we desynched.

func _save_state() -> Dictionary:
	var state = {
		#fixed_position = fixed_position,
		x = fixed_position.x,
		y = fixed_position.y,
		active = active,
	}
	#Utils.save_node_transform_state(self, state)
	return state

func _load_state(state: Dictionary) -> void:
	#Utils.load_node_transform_state(self, state)
	#fixed_position = state['fixed_position']
	fixed_position.x = state['x']
	fixed_position.y = state['y']
	active = state['active']
	sync_to_physics_engine()
