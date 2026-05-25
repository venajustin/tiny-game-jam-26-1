extends Node3D

var pivot_parent:Node3D = null
var last_bend = null
#var p_loc = null

func add_pivot(old_pivot:Node3D, last_bend_norm:Vector3):
	var p_loc = null
	last_bend = last_bend_norm
	pivot_parent = old_pivot
	p_loc = pivot_parent.find_child("wire_connection").global_position
	if abs((self.global_position - p_loc).length()) > 0.001:
		self.look_at(p_loc)
	self.scale.z = (p_loc - self.global_position).length()

func get_last_bend() -> Vector3:
	return last_bend
	
func remove_pivot() -> Node3D:
	var tmp = pivot_parent
	pivot_parent = null
	last_bend = null
	return tmp
	
#
#func link_direction() -> Vector3:
	#return (p_loc - self.global_position).normalized()
