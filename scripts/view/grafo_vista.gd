extends Node2D
class_name GrafoVista

@export var vertex_scene: PackedScene
@export var edge_scene: PackedScene

signal graph_vertex_clicked(vertex_id: int, is_selected: bool)

enum MinigameMode {
	BFS_DFS,
	CAMINOS_MINIMOS,
	ARBOL_EXPANSION_MINIMA,
	FLUJO_MAXIMO
}

var grafo: Grafo
var vertex_nodes: Dictionary = {}
var edge_nodes: Dictionary = {}
var selected_vertices: Array[int] = []
var active_edges: Dictionary = {}
var highlighted_edges: Array[Array] = []

var vertex_positions: Dictionary = {}

var current_mode: MinigameMode = MinigameMode.BFS_DFS
var bfs_dfs_completed: bool = false

func _ready() -> void:
	pass

func set_graph(p_grafo: Grafo) -> void:
	self.grafo = p_grafo
	self._build_initial_layout()
	self._rebuild_from_layout()
	self._apply_minigame_mode()

func refresh_from_graph() -> void:
	if self.grafo == null:
		return
	
	if self.vertex_positions.is_empty():
		return
	
	self._rebuild_from_layout()
	self._apply_minigame_mode()


func found_subarray(main_arr, sub_arr) -> bool:
	
	for arr in main_arr:
		if arr == sub_arr:
			return true;
	
	return false

func set_minigame_mode(mode: MinigameMode, p_bfs_dfs_completed: bool = false) -> void:
	self.current_mode = mode
	self.bfs_dfs_completed = p_bfs_dfs_completed
	self._apply_minigame_mode()

func _apply_minigame_mode() -> void:
	if self.vertex_nodes.is_empty() and self.edge_nodes.is_empty():
		return
	
	for id in self.vertex_nodes.keys():
		var vnode := self.vertex_nodes[id] as VerticeVista
		if vnode:
			vnode.set_minigame_mode(self.current_mode, bfs_dfs_completed)
	
		for from_id in edge_nodes.keys():
			for to_id in edge_nodes[from_id].keys():
				var enode := edge_nodes[from_id][to_id] as AristaVista
				if enode:
					enode.set_minigame_mode(self.current_mode)
	
	self.clear_all_edge_flows()

#Metodos para dibujar el grafo
func _build_initial_layout() -> void:
	for child in get_children():
		child.queue_free()
	
	self.vertex_nodes.clear()
	self.edge_nodes.clear()
	self.selected_vertices.clear()
	
	if self.grafo == null:
		return
	if self.vertex_scene == null:
		return
	
	var ids: Array = self.grafo.get_vertices_ids()
	var n: int = ids.size()
	if n == 0:
		return
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var padding: float = 80.0
	
	var usable_size := viewport_size - Vector2(padding * 2.0, padding * 2.0)
	
	var cols: int = ceili(sqrt(n))
	var rows: int = ceili(float(n) / float(cols))
	
	var cell_w := usable_size.x / float(cols)
	var cell_h := usable_size.y / float(rows)
	
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(n):
		var id: int = ids[i]
		
		var row: int = i / cols
		var col: int = i % cols
		
		var cell_origin := Vector2(
			padding + cell_w * col,
			padding + cell_h * row
		)
		
		var local_margin := 0.2
		var x := rng.randf_range(
			cell_origin.x + cell_w * local_margin,
			cell_origin.x + cell_w * (1.0 - local_margin)
		)
		
		var y := rng.randf_range(
			cell_origin.y + cell_h * local_margin,
			cell_origin.y + cell_h * (1.0 - local_margin)
		)
		
		self.vertex_positions[id] = Vector2(x, y)

func _rebuild_from_layout() -> void:
	for child in get_children():
		child.queue_free()
	
	self.vertex_nodes.clear()
	self.edge_nodes.clear()
	self.selected_vertices.clear()
	
	if self.grafo == null:
		return
	if self.vertex_scene == null or self.edge_scene == null:
		return
	
	#Dibujamos los vertices
	var ids: Array = self.grafo.get_vertices_ids()
	for id in ids:
		var pos: Vector2
		if self.vertex_positions.has(id):
			pos = self.vertex_positions[id]
		else:
			pos = get_viewport_rect().size * 0.5
		
		var vnode := self.vertex_scene.instantiate() as VerticeVista
		var v_logic: Vertice = self.grafo.get_vertex(id)
		
		add_child(vnode)
		vnode.setup(v_logic, pos)
		vnode.vertex_clicked.connect(self._on_vertex_clicked)
		
		self.vertex_nodes[id] = vnode
	
	#Dibujamos las aristas
	for from_id in self.grafo.edges.keys():
		self.edge_nodes[from_id] = {}
		for to_id in self.grafo.edges[from_id].keys():
			if not self.vertex_nodes.has(from_id):
				continue
			if not self.vertex_nodes.has(to_id):
				continue
			
			var from_node := self.vertex_nodes[from_id] as VerticeVista
			var to_node := self.vertex_nodes[to_id] as VerticeVista
			var edge: Arista = self.grafo.edges[from_id][to_id]
			
			var enode := self.edge_scene.instantiate() as AristaVista
			add_child(enode)
			enode.setup(edge, from_node.position, to_node.position)
			enode.set_active(false)
			
			self.edge_nodes[from_id][to_id] = enode

#Utils
func _on_vertex_clicked(vertex_id: int) -> void:
	if grafo == null:
		return
	if not grafo.has_vertex(vertex_id):
		return
	
	var is_selected_now := false
	
	if vertex_id in self.selected_vertices:
		self.selected_vertices.erase(vertex_id)
		is_selected_now = false
	else:
		self.selected_vertices.append(vertex_id)
		is_selected_now = true
	
	print("Seleccionados ahora: ", self.selected_vertices)
	#self._refresh_edge_info_visibility()
	
	self.graph_vertex_clicked.emit(vertex_id, is_selected_now)

#func _refresh_edge_info_visibility() -> void:
	#for from_id in self.edge_nodes.keys():
		#for to_id in self.edge_nodes[from_id].keys():
			#var enode: AristaVista = self.edge_nodes[from_id][to_id]
			#var show : bool = (from_id in self.selected_vertices) and (to_id in self.selected_vertices)
			#if found_subarray(highlighted_edges, [from_id, to_id]) and !show:
				#highlighted_edges.erase([from_id, to_id])
				#print("Miralo ve: ",highlighted_edges)
			#elif show and !found_subarray(highlighted_edges, [from_id, to_id]):
				#highlighted_edges.append([from_id, to_id])
				#print("Miralo ve: ", highlighted_edges)
	
			#enode.set_flow_active(show)

func highlight_infected_red() -> void:
	if self.grafo == null:
		return
	
	for id in self.grafo.vertices.keys():
		var v: Vertice = self.grafo.vertices[id]
		if v.is_infected and self.vertex_nodes.has(id):
			var vnode: VerticeVista = self.vertex_nodes[id]
			vnode.set_color(Color(1.0, 0.25, 0.25))
			print("Pintando infectado: ", id)
			return

func force_set_vertex_selected(vertex_id: int, selected: bool) -> void:
	if not self.vertex_nodes.has(vertex_id):
		return
	
	var vnode: VerticeVista = self.vertex_nodes[vertex_id]
	if vnode == null:
		return
	
	vnode.set_selected_state(selected)
	
	if selected:
		if not self.selected_vertices.has(vertex_id):
			self.selected_vertices.append(vertex_id)
	else:
		self.selected_vertices.erase(vertex_id)
	
	#self._refresh_edge_info_visibility()

func clear_active_edges() -> void:
	for from_id in self.edge_nodes.keys():
		for to_id in self.edge_nodes[from_id].keys():
			var enode: AristaVista = self.edge_nodes[from_id][to_id]
			if enode:
				enode.set_active(false)
	self.active_edges.clear()

func set_edge_active(from_id: int, to_id: int, active: bool) -> void:
	if not self.edge_nodes.has(from_id):
		return
	if not self.edge_nodes[from_id].has(to_id):
		return
	
	var enode: AristaVista = self.edge_nodes[from_id][to_id]
	if enode == null:
		return
	
	enode.set_active(active)
	
	if active:
		if not self.active_edges.has(from_id):
			self.active_edges[from_id] = {}
		self.active_edges[from_id][to_id] = true
	else:
		if self.active_edges.has(from_id) and self.active_edges[from_id].has(to_id):
			self.active_edges[from_id].erase(to_id)
			if self.active_edges[from_id].is_empty():
				self.active_edges.erase(from_id)

func set_path_edges(path: Array[int]) -> void:
	self.clear_active_edges()
	self.clear_all_edge_flows()
	if path.size() < 2:
		return
	
	for i in range(path.size() - 1):
		var u := path[i]
		var v := path[i+1]
		if self.edge_nodes.has(u) and self.edge_nodes[u].has(v):
			self.set_edge_active(u, v, true)

func clear_all_edge_flows() -> void:
	for from_id in self.edge_nodes.keys():
		for to_id in self.edge_nodes[from_id].keys():
			var enode: AristaVista = self.edge_nodes[from_id][to_id]
			enode.set_active(false)
