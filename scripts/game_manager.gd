extends Node
class_name GameManager

@export var num_vertices: int = 10

var grafo: Grafo
var current_mode: GrafoVista.MinigameMode = GrafoVista.MinigameMode.BFS_DFS
var bfs_dfs_completed: bool = false

@onready var grafo_vista: GrafoVista = $GrafoVista
@onready var bfs_dfs_ui: BfsDfsUi = $MinigamesUI/BfsDfsUi
@onready var shortest_path_ui: CaminoMinimoUi = $MinigamesUI/ShortestPathUi
@onready var kruskal_prim_ui: PrimKruskalUi = $MinigamesUI/PrimKruskalUi

func _ready() -> void:
	self.grafo = Grafo.new()
	self.grafo.generate_random(self.num_vertices)
	
	self.grafo_vista.set_graph(grafo)
	
	if self.bfs_dfs_ui:
		self.bfs_dfs_ui.set_graph(grafo)
		self.bfs_dfs_ui.set_graph_view(self.grafo_vista)
	
	if self.shortest_path_ui:
		self.shortest_path_ui.set_graph(grafo)
	
	self.grafo_vista.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	
	if self.bfs_dfs_ui:
		self.bfs_dfs_ui.visible = true
		self.bfs_dfs_ui.bfs_dfs_completed.connect(self._on_bfs_dfs_completed)
	
	if self.shortest_path_ui:
		self.shortest_path_ui.visible = false
	
	if self.grafo_vista and self.shortest_path_ui:
		self.grafo_vista.graph_vertex_clicked.connect(self.shortest_path_ui.on_vertex_clicked_from_graph)
	
	print("GameManager listo. Grafo generado con ", num_vertices, " vértices.")

func _on_bfs_dfs_completed() -> void:
	print("[GameManager] Señal bfs_dfs_completed recibida.")
	
	self.bfs_dfs_completed = true
	
	self.current_mode = GrafoVista.MinigameMode.CAMINOS_MINIMOS
	
	self.grafo_vista.set_minigame_mode(current_mode, bfs_dfs_completed)
	
	if self.bfs_dfs_ui:
		self.bfs_dfs_ui.visible = false
	if self.shortest_path_ui:
		self.shortest_path_ui.visible = true
		self.shortest_path_ui.start_minigame()
	
	print("[GameManager] Cambio de modo: ahora CAMINOS_MINIMOS.")
