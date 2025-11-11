extends Node2D
class_name GrafoVista

@export var vertex_scene: PackedScene
@export var edge_scene: PackedScene

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
		pass
	
	self._rebuild_from_layout()
	self._apply_minigame_mode()

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
			
			self.edge_nodes[from_id][to_id] = enode

#Utils
func _on_vertex_clicked(vertex_id: int) -> void:
	if grafo == null:
		return
	if not grafo.has_vertex(vertex_id):
		return
	
	if vertex_id in self.selected_vertices:
		self.selected_vertices.erase(vertex_id)
	else:
		self.selected_vertices.append(vertex_id)
	
	print("Seleccionados ahora: ", self.selected_vertices)
	self._refresh_edge_info_visibility()

func _refresh_edge_info_visibility() -> void:
	for from_id in self.edge_nodes.keys():
		for to_id in self.edge_nodes[from_id].keys():
			var enode: AristaVista = self.edge_nodes[from_id][to_id]
			var show : bool = (from_id in self.selected_vertices) and (to_id in self.selected_vertices)
			enode.set_flow_active(show)
