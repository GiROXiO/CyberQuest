extends RefCounted
class_name Grafo

#Variable para ver si el grafo es dirigido
var is_directed: bool = true

#Diccionario con los vertices del grafo
var vertices: Dictionary[int, Vertice] = {}

#Diccionario con las aristas del grafo => edges: Dictionary[int, Dictionary[int, Arista]]
var edges: Dictionary = {}

#Gestion de vertices
func add_vertex(id: int, hint: String = "", is_key_node: bool = false) -> Vertice:
	if self.vertices.has(id):
		return self.vertices[id]
		
	var v := Vertice.new(id, hint, is_key_node)
	self.vertices[id] = v
	return v

func get_vertex(id: int) -> Vertice:
	if self.vertices.has(id):
		return self.vertices[id]
	return null

func has_vertex(id: int) -> bool:
	return self.vertices.has(id)

func remove_vertex(id: int) -> void:
	if not self.vertices.has(id):
		return
	
	#Remover el vertice de la lista de vecinos
	for other_id in self.vertices.keys():
		if other_id == id:
			continue
		self.vertices[other_id].remove_neighbor(id)
	
	#Remover aristas relacionadas en edges
	if edges.has(id):
		edges.erase(id)

	# Quitar aristas que llegan a id
	for from_id in edges.keys():
		if edges[from_id].has(id):
			edges[from_id].erase(id)
	
	self.vertices.erase(id)

func get_vertices_ids() -> Array:
	return self.vertices.keys()

#Gestion de aristas
func _ensure_edge_dict(from_id: int) -> void:
	if not edges.has(from_id):
		self.edges[from_id] = {}

func add_edge(from_id: int, to_id: int, weight: float = 1.0, capacity: float = 0.0) -> void:
	self.add_vertex(from_id)
	self.add_vertex(to_id)
	
	#Actualizar vecinos
	self.vertices[from_id].add_neighbor(to_id)
	
	#Registrar datos de la arista
	self._ensure_edge_dict(from_id)
	var e := Arista.new(from_id, to_id, weight, capacity)
	self.edges[from_id][to_id] = e
	
	#Si no es dirigido, duplicar la arista inversa
	if not is_directed:
		self.vertices[to_id].add_neighbor(from_id)
		self._ensure_edge_dict(to_id)
		var e2 := Arista.new(to_id, from_id, weight, capacity)
		self.edges[to_id][from_id] = e2

func remove_edge(from_id: int, to_id: int) -> void:
	if self.edges.has(from_id) and self.edges[from_id].has[to_id]:
		self.vertices[from_id].remove_neighbor(to_id)
		self.edges[from_id].erase(to_id)
		
	if not is_directed:
		if self.edges.has(to_id) and self.edges[to_id].has(from_id):
			vertices[to_id].remove_neighbor(from_id)
			edges[to_id].erase(from_id)

func get_neighbors_ids(id: int) -> Array:
	var v := get_vertex(id)
	if v == null:
		return []
	return v.get_neighbors()

func get_edge(from_id: int, to_id: int) -> Arista:
	if self.edges.has(from_id) and self.edges[from_id].has[to_id]:
		return self.edges[from_id][to_id]
	return null

func has_edge(from_id: int, to_id: int) -> bool:
	return edges.has(from_id) and edges[from_id].has(to_id)

func get_weight(from_id: int, to_id: int, default: float = INF) -> float:
	var e := self.get_edge(from_id, to_id)
	return e.weight if e != null else default

func set_weight(from_id: int, to_id: int, weight: float) -> void:
	var e := self.get_edge(from_id, to_id)
	if e != null:
		e.weight = weight
	
	if not self.is_directed:
		var e2 := self.get_edge(to_id, from_id)
		if e2 != null:
			e2.weight = weight

func get_capacity(from_id: int, to_id: int, default: float = 0.0) -> float:
	var e := self.get_edge(from_id, to_id)
	return e.capacity if e != null else default

func set_capacity(from_id: int, to_id: int, capacity: float) -> void:
	var e := self.get_edge(from_id, to_id)
	if e != null:
		e.capacity = capacity
	
	if not self.is_directed:
		var e2 := self.get_edge(to_id, from_id)
		if e2 != null:
			e2.capacity = capacity

#Utils
func generate_random():
	pass


func clear() -> void:
	vertices.clear()
	edges.clear()
