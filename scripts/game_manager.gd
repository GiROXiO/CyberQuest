extends Node
class_name GameManager

@export var num_vertices: int = 10

var grafo: Grafo
var current_mode: GrafoVista.MinigameMode = GrafoVista.MinigameMode.BFS_DFS
var bfs_dfs_completed: bool = false

@onready var grafo_vista: GrafoVista = $GrafoVista

func _ready() -> void:
	self.grafo = Grafo.new()
	self.grafo.generate_random(self.num_vertices)
	
	self.grafo_vista.set_graph(grafo)
	self.grafo_vista.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	print("GameManager listo. Grafo generado con ", num_vertices, " vértices.")
