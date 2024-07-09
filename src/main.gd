extends Node2D

@onready var menu_panel = $CanvasLayer/MainMenuButtons
@onready var connection_panel = $CanvasLayer/ConnectionPanel
@onready var host_field = $CanvasLayer/ConnectionPanel/GridContainer/HostField
@onready var port_field = $CanvasLayer/ConnectionPanel/GridContainer/PortField

func _ready() -> void:
	print("Starting!")
	host_field.text = Settings.SERVER_IP
	port_field.text = Settings.PORT

	if SyncReplay.active:
		print("Replaying on boot, changing to match scene")
		Settings.game_state = Settings.GameState.SPECTATOR
		# Ignore the "parent node is busy adding/removing children" error message, 
		# the replay boot is just wonky
		get_tree().change_scene_to_file("res://src/match.tscn")

func _on_server_button_pressed():
	print("Pressed server button.")
	Settings.game_state = Settings.GameState.ONLINE_HOST
	
	Settings.SERVER_IP = host_field.text
	Settings.PORT = port_field.text
	Settings.is_server_or_client = "SERVER"
	get_tree().change_scene_to_file("res://src/match.tscn")

func _on_SpectatorButton_pressed() -> void:
	print("Pressed spectator button.")
	Settings.game_state = Settings.GameState.SPECTATOR
	get_tree().change_scene_to_file("res://src/match.tscn")

func _on_client_button_pressed():
	print("Pressed client button.")
	Settings.SERVER_IP = host_field.text
	Settings.PORT = port_field.text
	Settings.is_server_or_client = "CLIENT"
	Settings.game_state = Settings.GameState.ONLINE_CLIENT
	get_tree().change_scene_to_file("res://src/match.tscn")

func _on_online_button_pressed():
	print("Pressed online button.")
	connection_panel.visible = true
	menu_panel.visible = false

func _on_local_button_pressed():
	print("Pressed local button.")
	Settings.game_state = Settings.GameState.LOCAL
	get_tree().change_scene_to_file("res://src/match.tscn")
