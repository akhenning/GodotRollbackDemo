extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

var v = false

const input_path_mapping := {
	'/root/Main/ServerPlayer': 1,
	'/root/Main/ClientPlayer': 2,
}

enum HeaderFlags {
	l 		  = 1 << 0, # Bit 0
	r         = 1 << 1, # Bit 1
	u         = 1 << 2, # Bit 2
	d         = 1 << 3,
	k         = 1 << 4,
	p         = 1 << 5,
	s         = 1 << 6,
	h         = 1 << 7,
}

var input_path_mapping_reverse := {}

func _init() -> void:
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key


func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(16)
	
	if v: print("Wrapping input %s" % all_input)
	
	buffer.put_u32(all_input['$'])
	buffer.put_u8(all_input.size() - 1)
	for path in all_input:
		if path == '$':
			continue
		buffer.put_u8(input_path_mapping[path])
		
		var header := 0
		var input = all_input[path]
		if input.has('l'):
			header |= HeaderFlags.l
		if input.has('r'):
			header |= HeaderFlags.r
		if input.has('u'):
			header |= HeaderFlags.u
		if input.has('d'):
			header |= HeaderFlags.d
		if input.has('k'):
			header |= HeaderFlags.k
		if input.has('s'):
			header |= HeaderFlags.s
		if input.has('h'):
			header |= HeaderFlags.h
		buffer.put_u8(header)

		#print("Header: %s" % header)

	
	buffer.resize(buffer.get_position())
	if v: print("Buffer size: %s" % buffer.get_size())
	if (buffer.get_size() > 100):
		print("WARNING: BUFFER REALLY BIG FOR %s" % all_input)
	return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	if v: print("Buffer received: %s" % buffer)
	
	var all_input := {}
	
	all_input['$'] = buffer.get_u32()
	
	var input_count = buffer.get_u8()
	if input_count == 0:
		return all_input
	
	var path = input_path_mapping_reverse[buffer.get_u8()]
	var input := {}
	
	var header = buffer.get_u8()
	if v: print("Unwrapping header %s" % header)
	if header & HeaderFlags.l:
		input["l"] = true
	if header & HeaderFlags.r:
		input["r"] = true
	if header & HeaderFlags.u:
		input["u"] = true
	if header & HeaderFlags.d:
		input["d"] = true
	if header & HeaderFlags.k:
		input["k"] = true
	if header & HeaderFlags.p:
		input["p"] = true
	if header & HeaderFlags.s:
		input["s"] = true
	if header & HeaderFlags.h:
		input["h"] = true
	
	all_input[path] = input
	if v: print("Unwrapped input %s" % all_input)
	return all_input
