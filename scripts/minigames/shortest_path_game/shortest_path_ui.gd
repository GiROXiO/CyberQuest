extends Control
class_name CaminoMinimoUi

signal minigame_completed(success: bool)

@onready var info_label: Label = $Label

var grafo: Grafo = null
var grafo_vista: GrafoVista = null

var source_id: int = -1
var target_id: int = -1
var shortest_path: Array = []
var user_path: Array = []

func _ready() -> void:
	if self.info_label:
		self.info_label.text = "Caminos Minimos con Dijkstra"

func set_graph(p_grafo: Grafo) -> void:
	self.grafo = p_grafo

func set_graph_view(p_view: GrafoVista) -> void:
	self.grafo_vista = p_view

func start_minigame() -> void:
	if self.grafo == null:
		return
	
	self.target_id

func _find_control_center_id() -> int:
	if self.grafo == null:
		return -1
	
	for id in self.grafo.vertices.keys():
		var v: Vertice = self.grafo.vertices[id]
		if v.role == Vertice.VertexRole.CENTRO_CONTROL:
			return id
	
	return -1

func _find_infected_vertex_id() -> int:
	if self.grafo == null:
		return -1
	
	for id in self.grafo.vertices.keys():
		var v: Vertice = self.grafo.vertices[id]
		if v.is_infected:
			return id
	
	return -1
