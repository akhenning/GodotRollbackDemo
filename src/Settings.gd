extends Node


enum GameState {
	LOCAL,
	ONLINE_HOST,
	ONLINE_CLIENT,
	SPECTATOR,
}

# Singleton to hold preferences information, and also handles the universally accessable
# error display

var PORT = "9999"
var SERVER_IP = "127.0.0.1" # IPv4 localhost
var is_server_or_client = ""
var game_state = null
var in_match = false
var p1_character = 0
var p2_character = 0


var last_text_sent_to_error = ""
var ticks_since_message_was_displayed = 60
var trying_to_clear_error_label = false

signal set_uh_oh_text(msg)

func _process(_something):
	# handle timer that makes sure error messages wont be up for less than a second
	if ticks_since_message_was_displayed < 60:
		ticks_since_message_was_displayed += 1
	if ticks_since_message_was_displayed >= 60 and trying_to_clear_error_label:
		set_uh_oh_text.emit("")
	

func set_error_text(msg: String):
	if msg != "":
		ticks_since_message_was_displayed = 0
	# Don't send signals more often than we need to
	if msg != last_text_sent_to_error:
		# If clearing label and has been less than a second since the last message was sent,
		# do not send it.
		if msg == "" and ticks_since_message_was_displayed < 60:
			trying_to_clear_error_label = true
			return
		last_text_sent_to_error = msg
		# Otherwise, reset counters and say that it is not trying to overwrite label.
		trying_to_clear_error_label = false
		set_uh_oh_text.emit(msg)
	
		
		
#func _ready():
	#var root = get_tree().root
	#current_scene = root.get_child(root.get_child_count() - 1)
