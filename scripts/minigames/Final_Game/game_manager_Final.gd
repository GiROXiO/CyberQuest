extends Node
class_name GameManager2

@export var num_vertices: int = 10

var grafo2: Grafo
var current_mode: GrafoVista.MinigameMode = GrafoVista.MinigameMode.BFS_DFS
var bfs_dfs_completed: bool = false
signal mode_changed(new_mode)

@onready var grafo_vista2: GrafoVista = $GrafoVista
@onready var bfs_dfs_ui2: BfsDfsUi = $MinigamesUI/BfsDfsUi
@onready var shortest_path_ui2: CaminoMinimoUi = $MinigamesUI/ShortestPathUi
@onready var kruskal_prim_ui2: PrimKruskalUi = $MinigamesUI/PrimKruskalUi
@onready var max_flow_ui2: MaxFlowUi = $MinigamesUI/MaxFlowUi

func _ready() -> void:
	if self.bfs_dfs_ui2:
		self.bfs_dfs_ui2.visible = false
	if self.shortest_path_ui2:
		self.shortest_path_ui2.visible = false
	if self.kruskal_prim_ui2:
		self.kruskal_prim_ui2.visible = false
	if self.max_flow_ui2:
		self.max_flow_ui2.visible = false

func start_final_game() -> void:
	# Nuevo grafo para el juego final
	self.grafo2 = Grafo.new()
	self.grafo2.generate_random(num_vertices)

	if self.grafo_vista2:
		self.grafo_vista2.set_graph(self.grafo2)

	if self.bfs_dfs_ui2:
		self.bfs_dfs_ui2.set_graph(grafo2)
		self.bfs_dfs_ui2.set_graph_view(grafo_vista2)
		self.bfs_dfs_ui2.visible = true
		if not self.bfs_dfs_ui2.bfs_dfs_completed.is_connected(self._on_bfs_dfs_completed):
			self.bfs_dfs_ui2.bfs_dfs_completed.connect(self._on_bfs_dfs_completed)

	if self.shortest_path_ui2:
		self.shortest_path_ui2.set_graph(self.grafo2)
		self.shortest_path_ui2.set_graph_view(self.grafo_vista2)
		self.shortest_path_ui2.visible = false
		if not self.grafo_vista2.graph_vertex_clicked.is_connected(self.shortest_path_ui2.on_vertex_clicked_from_graph):
			self.grafo_vista2.graph_vertex_clicked.connect(self.shortest_path_ui2.on_vertex_clicked_from_graph)
		if not self.shortest_path_ui2.minigame_completed.is_connected(self._on_shortest_path_completed):
			self.shortest_path_ui2.minigame_completed.connect(_on_shortest_path_completed)

	if self.kruskal_prim_ui2:
		self.kruskal_prim_ui2.set_graph(self.grafo2)
		self.kruskal_prim_ui2.set_graph_view(self.grafo_vista2)
		self.kruskal_prim_ui2.visible = false
		if not self.kruskal_prim_ui2.minigame_completed.is_connected(self._on_prim_kruskal_completed):
			self.kruskal_prim_ui2.minigame_completed.connect(self._on_prim_kruskal_completed)

	if self.max_flow_ui2:
		self.max_flow_ui2.set_graph(self.grafo2)
		self.max_flow_ui2.set_graph_view(self.grafo_vista2)
		self.max_flow_ui2.visible = false
		if not self.max_flow_ui2.minigame_completed.is_connected(self._on_max_flow_completed):
			self.max_flow_ui2.minigame_completed.connect(self._on_max_flow_completed)

	self.current_mode = GrafoVista.MinigameMode.BFS_DFS
	self.bfs_dfs_completed = false

	if self.grafo_vista2:
		self.grafo_vista2.set_minigame_mode(current_mode, bfs_dfs_completed)
		self.grafo_vista2.reset_view_state()

	print("[GameManager2] Juego final iniciado con ", num_vertices, " vértices.")
	emit_signal("mode_changed", current_mode)

func _on_bfs_dfs_completed(success: bool) -> void:
	print("[GameManager] Señal bfs_dfs_completed recibida. Éxito:", success)
	
	if not success:
		print("[GameManager] El minijuego BFS/DFS no se completó correctamente.")
		return
	
	self.bfs_dfs_completed = true
	self.current_mode = GrafoVista.MinigameMode.CAMINOS_MINIMOS
	
	self.grafo_vista2.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	
	if self.bfs_dfs_ui2:
		self.bfs_dfs_ui2.visible = false
	if self.shortest_path_ui2:
		self.shortest_path_ui2.visible = true
		self.shortest_path_ui2.start_minigame()
	
	await get_tree().create_timer(0.6).timeout
	self.grafo_vista2.highlight_infected_red()
	
	print("[GameManager] Cambio de modo: ahora CAMINOS_MINIMOS.")
	emit_signal("mode_changed", current_mode)
	

func _on_shortest_path_completed(success: bool) -> void:
	if not success:
		return
	
	print("[GameManager] Minijuego de caminos mínimos completado con éxito.")
	
	var infected_id: int = self.grafo2.get_infected_id()
	if infected_id != -1:
		print("Eliminando nodo infectado del grafo: ", infected_id)
		self.grafo2.remove_vertex(infected_id)
		
		self.grafo_vista2.refresh_from_graph()
	
	# Reseteamos la vista
	if self.grafo_vista2 != null:
		self.grafo_vista2.reset_view_state()
	
	#Cambiamos al siguiente nivel
	self.current_mode = GrafoVista.MinigameMode.ARBOL_EXPANSION_MINIMA
	self.grafo_vista2.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	
	if self.shortest_path_ui2:
		self.shortest_path_ui2.visible = false
	
	if self.kruskal_prim_ui2:
		self.kruskal_prim_ui2.visible = true
	emit_signal("mode_changed", current_mode)


func _on_prim_kruskal_completed(success : bool) -> void:
	if not success:
		return
	
	print("[GameManager] Minijuego de arbol de expansión minima completado con éxito.")
	
	var mst_edges: Array = []
	if self.kruskal_prim_ui2 and self.kruskal_prim_ui2.has_method("get_mst_edges"):
		mst_edges = self.kruskal_prim_ui2.get_mst_edges()
		print("[GameManager] Aristas MST recibidas: ", mst_edges)
	else:
		print("[GameManager] WARNING: PrimKruskalUi no tiene get_mst_edges().")
	
	if self.grafo2 and mst_edges.size() > 0:
		self.grafo2.keep_only_edges(mst_edges)
	
	if self.grafo_vista2:
		if self.grafo_vista2.has_method("refresh_from_graph"):
			self.grafo_vista2.refresh_from_graph()
		else:
			self.grafo_vista2.set_graph(self.grafo)
	
	# Reseteamos la vista
	if self.grafo_vista2 != null:
		self.grafo_vista2.reset_view_state()
	
	#Cambiamos al siguiente nivel
	self.current_mode = GrafoVista.MinigameMode.FLUJO_MAXIMO
	self.grafo_vista2.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	
	if self.kruskal_prim_ui2:
		self.kruskal_prim_ui2.visible = false
	
	if self.max_flow_ui2:
		self.max_flow_ui2.visible = true
		# Conectar interacción de vértices solo para este minijuego
		self.grafo_vista2.graph_vertex_clicked.connect(self.max_flow_ui2.on_vertex_clicked_from_graph)
		self.max_flow_ui2.minigame_completed.connect(self._on_max_flow_completed)
		self.max_flow_ui2.start_minigame()
	emit_signal("mode_changed", current_mode)

func _on_max_flow_completed(success: bool) -> void:
	if not success:
		return
	
	print("[GameManager] Minijuego de flujo máximo completado con éxito.")
	
	if grafo_vista2:
		grafo_vista2.reset_view_state()

func _on_dialogic_signal(señal: String):
	print("Hola")
	if señal == "exit":
		print("Hola otra vez")
		print("Señal exit recibida desde Dialogic, cerrando cinematica...")
		
		await get_tree().create_timer(0.5).timeout
		
		for child in get_children():
			if child is Dialogic:
				child.queue_free()
		
		if Engine.has_singleton("Dialogic"):
			Dialogic.reset()
