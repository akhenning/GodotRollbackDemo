extends Label

# Counts per frame, does not count using system clock
# This is to make it useful for debugging
var ticks = 0

# Uses no floats
func _network_process(_input: Dictionary) -> void:
	ticks += 1
	 # 70 ticks = 1.1, displayed as 11.
	var time_one_decimal = ticks*10/60
	# Find number of minutes here, rounded down
	var mins = int(time_one_decimal/600)
	# Find modulo seconds by minutes
	var sec_str = str(time_one_decimal % 600)
	# Format remaining number of seconds
	sec_str = sec_str.left(sec_str.length() - 1) + "." + sec_str[sec_str.length() - 1]
	if sec_str[0] == ".":
		sec_str = "00"+sec_str
	elif  sec_str[1] == ".":
		sec_str = "0"+sec_str
	self.text = str(mins) + ":" + sec_str


func _save_state() -> Dictionary:
	var state = {
		ticks = ticks,
	}
	return state

func _load_state(state: Dictionary) -> void:
	ticks = state['ticks']
