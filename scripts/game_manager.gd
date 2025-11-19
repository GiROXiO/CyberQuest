extends Node
class_name GameManager

@export var num_vertices: int = 10

var grafo: Grafo
var current_mode: GrafoVista.MinigameMode = GrafoVista.MinigameMode.BFS_DFS
var bfs_dfs_completed: bool = false
signal mode_changed(new_mode)


@onready var grafo_vista: GrafoVista = $GrafoVista
@onready var bfs_dfs_ui: BfsDfsUi = $MinigamesUI/BfsDfsUi
@onready var shortest_path_ui: CaminoMinimoUi = $MinigamesUI/ShortestPathUi
@onready var kruskal_prim_ui: PrimKruskalUi = $MinigamesUI/PrimKruskalUi
@onready var max_flow_ui: MaxFlowUi = $MinigamesUI/MaxFlowUi
@onready var final_game_ui: GameManager2 = $MinigamesUI/GameManagerJuegoFinal

func _ready() -> void:
	self.grafo = Grafo.new()
	self.grafo.generate_random(self.num_vertices)
	
	self.grafo_vista.set_graph(grafo)
	
	if self.bfs_dfs_ui:
		self.bfs_dfs_ui.set_graph(grafo)
		self.bfs_dfs_ui.set_graph_view(self.grafo_vista)
	
	if self.shortest_path_ui:
		self.shortest_path_ui.set_graph(self.grafo)
		self.shortest_path_ui.set_graph_view(self.grafo_vista)
		self.grafo_vista.graph_vertex_clicked.connect(self.shortest_path_ui.on_vertex_clicked_from_graph)
		self.shortest_path_ui.minigame_completed.connect(self._on_shortest_path_completed)
	
	self.grafo_vista.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	
	if self.bfs_dfs_ui:
		self.bfs_dfs_ui.visible = true
		self.bfs_dfs_ui.bfs_dfs_completed.connect(self._on_bfs_dfs_completed)
	
	if self.shortest_path_ui:
		self.shortest_path_ui.visible = false
	
	if self.grafo_vista and self.shortest_path_ui:
		self.grafo_vista.graph_vertex_clicked.connect(self.shortest_path_ui.on_vertex_clicked_from_graph)
	
	if self.kruskal_prim_ui:
		self.kruskal_prim_ui.minigame_completed.connect(self._on_prim_kruskal_completed)
	
	if self.max_flow_ui:
		self.max_flow_ui.set_graph(self.grafo)
		self.max_flow_ui.set_graph_view(self.grafo_vista)
		self.max_flow_ui.visible = false
	
	if self.final_game_ui:
		self.final_game_ui.visible = false
		self.final_game_ui.minigame_completed.connect(self._on_final_game_completed)
	
	print("GameManager listo. Grafo generado con ", num_vertices, " vértices.")
	mostrarCinematica("res://Dialogic/Timelines/1 Beginning.dtl")
	emit_signal("mode_changed", current_mode)
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Pausa"):
		if $pause_menu.visible == false:
			$pause_menu.entrarPausa = true
			$pause_menu.visible = true
			
func _on_bfs_dfs_completed(success: bool) -> void:
	print("[GameManager] Señal bfs_dfs_completed recibida. Éxito:", success)
	
	if not success:
		print("[GameManager] El minijuego BFS/DFS no se completó correctamente.")
		return
	
	self.bfs_dfs_completed = true
	self.current_mode = GrafoVista.MinigameMode.CAMINOS_MINIMOS
	
	self.grafo_vista.set_minigame_mode(current_mode, bfs_dfs_completed)
	
	if self.bfs_dfs_ui:
		self.bfs_dfs_ui.visible = false
	if self.shortest_path_ui:
		self.shortest_path_ui.visible = true
		self.shortest_path_ui.start_minigame()
	
	await get_tree().create_timer(0.6).timeout
	self.grafo_vista.highlight_infected_red()
	
	print("[GameManager] Cambio de modo: ahora CAMINOS_MINIMOS.")
	mostrarCinematica("res://Dialogic/Timelines/3 dijkstra.dtl")
	emit_signal("mode_changed", current_mode)
	

func _on_shortest_path_completed(success: bool) -> void:
	if not success:
		return
	
	print("[GameManager] Minijuego de caminos mínimos completado con éxito.")
	
	var infected_id: int = self.grafo.get_infected_id()
	if infected_id != -1:
		print("Eliminando nodo infectado del grafo: ", infected_id)
		self.grafo.remove_vertex(infected_id)
		
		self.grafo_vista.refresh_from_graph()
	
	# Reseteamos la vista
	if self.grafo_vista != null:
		self.grafo_vista.reset_view_state()
	
	#Cambiamos al siguiente nivel
	self.current_mode = GrafoVista.MinigameMode.ARBOL_EXPANSION_MINIMA
	self.grafo_vista.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	
	if self.shortest_path_ui:
		self.shortest_path_ui.visible = false
	
	if self.kruskal_prim_ui:
		self.kruskal_prim_ui.visible = true
	mostrarCinematica("res://Dialogic/Timelines/4 prim_kruskal.dtl")
	emit_signal("mode_changed", current_mode)


func _on_prim_kruskal_completed(success : bool) -> void:
	if not success:
		return
	
	print("[GameManager] Minijuego de arbol de expansión minima completado con éxito.")
	
	var mst_edges: Array = []
	if self.kruskal_prim_ui and self.kruskal_prim_ui.has_method("get_mst_edges"):
		mst_edges = self.kruskal_prim_ui.get_mst_edges()
		print("[GameManager] Aristas MST recibidas: ", mst_edges)
	else:
		print("[GameManager] WARNING: PrimKruskalUi no tiene get_mst_edges().")
	
	if self.grafo and mst_edges.size() > 0:
		self.grafo.keep_only_edges(mst_edges)
	
	if self.grafo_vista:
		if self.grafo_vista.has_method("refresh_from_graph"):
			self.grafo_vista.refresh_from_graph()
		else:
			self.grafo_vista.set_graph(self.grafo)
	
	# Reseteamos la vista
	if self.grafo_vista != null:
		self.grafo_vista.reset_view_state()
	
	#Cambiamos al siguiente nivel
	self.current_mode = GrafoVista.MinigameMode.FLUJO_MAXIMO
	self.grafo_vista.set_minigame_mode(self.current_mode, self.bfs_dfs_completed)
	
	if self.kruskal_prim_ui:
		self.kruskal_prim_ui.visible = false
	
	if self.max_flow_ui:
		self.max_flow_ui.visible = true
		# Conectar interacción de vértices solo para este minijuego
		self.grafo_vista.graph_vertex_clicked.connect(self.max_flow_ui.on_vertex_clicked_from_graph)
		self.max_flow_ui.minigame_completed.connect(self._on_max_flow_completed)
		self.max_flow_ui.start_minigame()
	
	mostrarCinematica("res://Dialogic/Timelines/5 ford-fulkerson .dtl")
	emit_signal("mode_changed", current_mode)

func _on_max_flow_completed(success: bool) -> void:
	if not success:
		return
	
	print("[GameManager] Minijuego de flujo máximo completado con éxito.")
	mostrarCinematica("res://Dialogic/Timelines/6 final mission.dtl")
	
	
	if self.grafo_vista:
		self.grafo_vista.reset_view_state()
		self.grafo_vista.visible = false

	# --- Apagar UIs de la campaña ---
	if self.bfs_dfs_ui:
		self.bfs_dfs_ui.visible = false
	if self.shortest_path_ui:
		self.shortest_path_ui.visible = false
	if self.kruskal_prim_ui:
		self.kruskal_prim_ui.visible = false
	if self.max_flow_ui:
		self.max_flow_ui.visible = false

	if self.final_game_ui:
		print("[GameManager] Lanzando juego final...")
		self.final_game_ui.visible = true
		final_game_ui.start_final_game() 

func _on_final_game_completed(success: bool):
	if not success:
		return
	
	print("[GameManager] Minijuego final completado con éxito.")
	mostrarCinematica("res://Dialogic/Timelines/7 ending.dtl")

func mostrarCinematica(rutaCin: String):
	if not ResourceLoader.exists(rutaCin):
		push_warning("No existe la cinematica")
		return
		
	var dialogic = Dialogic.start(rutaCin)
	add_child(dialogic)
	
	
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

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
