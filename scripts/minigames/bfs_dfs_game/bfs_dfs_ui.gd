extends Control
class_name BfsDfsUi

signal bfs_dfs_completed

@onready var neutralize_button: Button = $NeutralizeButton

var grafo: Grafo = null
var grafo_vista: GrafoVista = null

var selected_vertex_id: int = -1

func _ready() -> void:
	if self.neutralize_button:
		self.neutralize_button.text = "Neutralizar infección"
		self.neutralize_button.pressed.connect(self._on_neutralize_button_pressed)

func set_graph(p_grafo: Grafo) -> void:
	self.grafo = p_grafo

func set_graph_view(p_view: GrafoVista) -> void:
	grafo_vista = p_view

# Llamado por GameManager cuando el usuario hace clic en un vértice del grafo
func on_vertex_clicked_from_graph(vertex_id: int) -> void:
	self.selected_vertex_id = vertex_id

func _on_neutralize_button_pressed() -> void:
	if self.grafo == null:
		print("[BFS_DFS_UI] No hay referencia al grafo.")
		return
	if self.grafo_vista != null:
		self.grafo_vista.highlight_infected_red()
	
	emit_signal("bfs_dfs_completed")

func _get_infected_vertex_id() -> int:
	if self.grafo == null:
		return -1
	
	for id in self.grafo.vertices.keys():
		var v: Vertice = self.grafo.vertices[id]
		if v.is_infected:
			return id
	return -1

func _role_to_string(role: int) -> String:
	match role:
		Vertice.VertexRole.CENTRO_CONTROL:
			return "Centro de Control"
		Vertice.VertexRole.ROUTER_CORE:
			return "Router Core"
		Vertice.VertexRole.ROUTER_BORDE:
			return "Router de Borde"
		Vertice.VertexRole.FIREWALL:
			return "Firewall"
		Vertice.VertexRole.SERVIDOR_APP:
			return "Servidor de Aplicaciones"
		Vertice.VertexRole.SERVIDOR_DB:
			return "Servidor de Base de Datos"
		Vertice.VertexRole.SERVIDOR_MAIL:
			return "Servidor de Correo"
		Vertice.VertexRole.GATEWAY_VPN:
			return "Gateway VPN"
		Vertice.VertexRole.IDS:
			return "Sistema IDS"
		Vertice.VertexRole.CLIENTE:
			return "Cliente Final"
		_:
			return "Nodo"
