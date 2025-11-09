extends RefCounted
class_name Arista

enum StyleState {
	NORMAL,
	SELECTED,
	FLOW
}

var from_id: int
var to_id: int
var weight: float = 1.0
var capacity: float = 0.0

var style_state: int = StyleState.NORMAL

func _init(p_from_id: int, p_to_id: int, p_weight: float = 1.0, p_capacity: float = 0.0) -> void:
	self.from_id = p_from_id
	self.to_id = p_to_id
	self.weight = p_weight
	self.capacity = p_capacity
