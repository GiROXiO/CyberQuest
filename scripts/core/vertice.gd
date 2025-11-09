extends RefCounted
class_name Vertice

enum StyleState {
	NORMAL,
	SELECTED
}

enum VertexRole {
	CENTRO_CONTROL,
	ROUTER_CORE,
	ROUTER_BORDE,
	FIREWALL,
	SERVIDOR_APP,
	SERVIDOR_DB,
	SERVIDOR_MAIL,
	GATEWAY_VPN,
	IDS,
	CLIENTE
}

#Variables que se utilizaran para el manejo de vertices
var id: int
var neighbors: Array[int] = []

var style_state: int = StyleState.NORMAL

var hint: String = ""
var is_key_vertex: bool = false

func _init(p_id: int, p_hint: String = "", p_is_key_vertex: bool = false) -> void:
	self.id = p_id
	self.hint = p_hint
	self.is_key_vertex = p_is_key_vertex

#Manejo de seleccion
func select() -> void:
	self.style_state = StyleState.SELECTED

func deselect() -> void:
	self.style_state = StyleState.NORMAL

func toggle_selected() -> void:
	self.style_state = StyleState.NORMAL if self.style_state == StyleState.SELECTED else StyleState.SELECTED

#Manejo de vecinos
func add_neighbor(neighbor_id: int) -> void:
	if neighbor_id != self.id and neighbor_id not in self.neighbors:
		self.neighbors.append(neighbor_id)

func remove_neighbor(neighbor_id: int) -> void:
	self.neighbors.erase(neighbor_id)

func clear_neighbors() -> void:
	self.neighbors.clear()

func get_neighbors() -> Array:
	return self.neighbors.duplicate()
