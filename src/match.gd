extends Node2D


const DummyNetworkAdapter = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

@onready var uh_oh_label = $CanvasLayer/UhOhLabel
@onready var message_label = $CanvasLayer/MessageLabel
@onready var sync_lost_label = $CanvasLayer/SyncLostLabel
@onready var reset_button = $CanvasLayer/ResetButton



var LOG_FILE_DIRECTORY = "C:/Users/ak7he/Documents/Documents/gitstuff/godot//logs"

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}
var players_loaded = 0

var logging_enabled = true

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

func _ready() -> void:
	print("Booting match")
	Settings.in_match = true
	
	multiplayer.peer_connected.connect(self._on_peer_connected)
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
	multiplayer.connected_to_server.connect(self._on_server_connected)
	multiplayer.server_disconnected.connect(self._on_server_disconnected)

	SyncManager.spectating = false
	SyncManager.sync_started.connect(self._on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(self._on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(self._on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(self._on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(self._on_SyncManager_sync_error)
	
	Settings.set_uh_oh_text.connect(self.set_error_msg)
	
	if SyncReplay.active:
		reset_button.visible = false

	if Settings.game_state == Settings.GameState.ONLINE_HOST:
		SyncManager.reset_network_adaptor()
		SyncManager.spectating = false
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(int(Settings.PORT))
		multiplayer.multiplayer_peer = peer
		message_label.text = "Listening..."
	elif Settings.game_state == Settings.GameState.ONLINE_CLIENT:
		SyncManager.reset_network_adaptor()
		SyncManager.spectating = false
		_start_client()
	elif Settings.game_state == Settings.GameState.LOCAL:
		SyncManager.network_adaptor = DummyNetworkAdapter.new()
		SyncManager.start()
		$ClientPlayer.input_prefix = "p2_"
	elif Settings.game_state == Settings.GameState.SPECTATOR:
		
		SyncManager.spectating = true
		_start_client()
	
	#var nodes = {}
	#nodes[$ClientPlayer.get_path()] = $ClientPlayer
	#nodes[$ServerPlayer.get_path()] = $ServerPlayer
	#nodes[$CanvasLayer/GameTimer.get_path()] = $CanvasLayer/GameTimer
	#SyncManager.add_nodes_to_sync_manager_for_replay_debugging(nodes)
	print("Finished booting match")

func _start_client() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(Settings.SERVER_IP, int(Settings.PORT))
	multiplayer.multiplayer_peer = peer
	message_label.text = "Connecting..."



func _on_peer_connected(peer_id: int):
	# Tell sibling peers about ourselves.
	if not multiplayer.is_server() and peer_id != 1:
		register_player.rpc_id(peer_id, {spectator = SyncManager.spectating})


func _on_peer_disconnected(peer_id: int):
	var peer = SyncManager.peers.get(peer_id)
	if peer and not peer.spectator:
		message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)


func _on_server_connected() -> void:
	if not SyncManager.spectating:
		$ClientPlayer.set_multiplayer_authority(multiplayer.get_unique_id())
	SyncManager.add_peer(1)
	# Tell server about ourselves.
	register_player.rpc_id(1, {spectator = SyncManager.spectating})

func _on_server_disconnected() -> void:
	_on_peer_disconnected(1)

@rpc("any_peer")
func register_player(options: Dictionary = {}) -> void:
	var peer_id = multiplayer.get_remote_sender_id()
	SyncManager.add_peer(peer_id, options)
	var peer = SyncManager.peers[peer_id]

	if not peer.spectator:
		$ClientPlayer.set_multiplayer_authority(peer_id)

		if multiplayer.is_server():
			multiplayer.multiplayer_peer.refuse_new_connections = true

			message_label.text = "Starting..."
			# Give a little time to get ping data.
			SyncManager.start()


func _on_SyncManager_sync_started() -> void:
	message_label.text = "Started!"

	if logging_enabled and not SyncReplay.active:
		if not DirAccess.dir_exists_absolute(LOG_FILE_DIRECTORY):
			DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)

		var datetime := Time.get_datetime_dict_from_system(true)
		var log_file_name = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			multiplayer.get_unique_id(),
		]

		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name)

func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()
		print("Stopping logging")

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false

	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()

func _on_reset_button_pressed():
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	#get_tree().reload_current_scene()
	get_tree().change_scene_to_file("res://src/main.tscn")


func setup_match_for_replay(my_peer_id: int, peer_ids: Array, _match_info: Dictionary) -> void:
	var client_peer_id: int
	if my_peer_id == 1:
		client_peer_id = peer_ids[0] if len(peer_ids) > 0 else 1
	else:
		client_peer_id = my_peer_id
	$ClientPlayer.set_multiplayer_authority(client_peer_id)
	

func set_error_msg(msg: String):
	uh_oh_label.text = msg

