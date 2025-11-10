extends Node2D
class_name GrafoVista

@export var vertex_scene: PackedScene
@export var edge_scene: PackedScene

var grafo: Grafo
var vertex_nodes: Dictionary = {}
var edge_nodes: Dictionary = {}
var selected_vertices: Array[int] = []

func _ready() -> void:
	grafo = Grafo.new()
	grafo.generate_random(10)
	self._draw_vertices()

#Metodo para dibujar los vertices del grafo en pantalla
func _draw_vertices() -> void:
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
		
		var pos := Vector2(x,y)
		
		var vnode := self.vertex_scene.instantiate() as VerticeVista
		add_child(vnode)
		
		var v_logic: Vertice = grafo.get_vertex(id)
		vnode.setup(v_logic, pos)
		
		vnode.vertex_clicked.connect(self._on_vertex_clicked)
		
		self.vertex_nodes[id] = vnode
	self._draw_edges()

func _draw_edges() -> void:
	if self.grafo == null:
		return
	if self.edge_scene == null:
		return
	
	for from_id in self.grafo.edges.keys():
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
			
			if not self.edge_nodes.has(from_id):
				self.edge_nodes[from_id] = {}
			self.edge_nodes[from_id][to_id] = enode
	self._refresh_edge_info_visibility()

func _on_vertex_clicked(vertex_id: int) -> void:
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
			enode.set_info_visible(show)
			enode.ser_flow_active(show)
