extends Control
class_name BfsDfsUi

signal bfs_dfs_completed

@onready var neutralize_button: Button = $NeutralizeButton

var grafo: Grafo = null

func _ready() -> void:
	if self.neutralize_button:
		self.neutralize_button.text = "Neutralizar infección"
		self.neutralize_button.pressed.connect(self._on_neutralize_button_pressed)

func set_graph(p_grafo: Grafo) -> void:
	self.grafo = p_grafo

func _on_neutralize_button_pressed() -> void:
	if self.grafo == null:
		print("[BFS_DFS_UI] No hay referencia al grafo.")
		return
	var infected_id := self._get_infected_vertex_id()
	if infected_id != -1:
		var v: Vertice = self.grafo.vertices[infected_id]
		print("[BFS_DFS_UI] Eliminando vértice infectado id=", infected_id, " rol=", v.role)
		self.grafo.remove_vertex(infected_id)
	else:
		print("[BFS_DFS_UI] No se encontró vértice infectado")
	
	emit_signal("bfs_dfs_completed")

func _get_infected_vertex_id() -> int:
	if self.grafo == null:
		return -1
	
	for id in self.grafo.vertices.keys():
		var v: Vertice = self.grafo.vertices[id]
		if v.is_infected:
			return id
	return -1
