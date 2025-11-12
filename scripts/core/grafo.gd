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
	if not self.edges.has(from_id):
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
	if self.edges.has(from_id) and self.edges[from_id].has(to_id):
		return self.edges[from_id][to_id]
	return null

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
#Metodo para asignar pesos y capacidad a las aristas dependiendo de los vertices relacionados
func _random_edge_params(from_role: int, to_role: int, rng: RandomNumberGenerator) -> Dictionary:
	var weight_min := 1
	var weight_max := 10
	var capacity_min := 5
	var capacity_max := 25
	
	#Red confiable, bajo riesgo y mucha capacidad
	if (from_role == Vertice.VertexRole.CENTRO_CONTROL and to_role == Vertice.VertexRole.ROUTER_CORE) \
	or (from_role == Vertice.VertexRole.ROUTER_CORE and to_role == Vertice.VertexRole.ROUTER_BORDE) \
	or (from_role == Vertice.VertexRole.ROUTER_BORDE and to_role == Vertice.VertexRole.FIREWALL):
		weight_min = 1
		weight_max = 3
		capacity_min = 15
		capacity_max = 25
	
	#Enlaces hacia servidores
	elif to_role in [Vertice.VertexRole.SERVIDOR_APP, Vertice.VertexRole.SERVIDOR_DB, Vertice.VertexRole.SERVIDOR_MAIL]:
		weight_min = 2
		weight_max = 6
		capacity_min = 10
		capacity_max = 20
	
	#VPN Gateway, mas riesgoso y con menos capacidad
	elif from_role == Vertice.VertexRole.GATEWAY_VPN or to_role == Vertice.VertexRole.GATEWAY_VPN:
		weight_min = 5
		weight_max = 9
		capacity_min = 5
		capacity_max = 15
	
	#Cliente final: cuello de botella y con riesgo
	elif from_role == Vertice.VertexRole.CLIENTE or to_role == Vertice.VertexRole.CLIENTE:
		weight_min= 4
		weight_max = 8
		capacity_min = 3
		capacity_max = 12
	
	#IDs: poco riesgo y poca capacidad
	elif from_role == Vertice.VertexRole.IDS or to_role == Vertice.VertexRole.IDS:
		weight_min = 1
		weight_max = 4
		capacity_min = 5
		capacity_max = 10
	
	#otros enlaces
	else:
		weight_min = 3
		weight_max = 7
		capacity_min = 6
		capacity_max = 18
	
	return {
		"weight": rng.randf_range(weight_min, weight_max),
		"capacity": rng.randf_range(capacity_min, capacity_max)
	}

#Metodo para ver si una arista existe en el grafo
func has_edge(from_id: int, to_id: int) -> bool:
	return edges.has(from_id) and edges[from_id].has(to_id)

#Funcion para crear aristas
func _connect_if_exists(from_id: int, to_id: int, rng: RandomNumberGenerator) -> void:
	if not self.vertices.has(from_id):
		return
	if not self.vertices.has(to_id):
		return
	
	var from_v: Vertice = self.vertices[from_id]
	var to_v: Vertice = self.vertices[to_id]
	
	var params := self._random_edge_params(from_v.role, to_v.role, rng)
	self.add_edge(from_id, to_id, params["weight"], params["capacity"])

#Metodo para conectar vertices que tengan sentido dentro de la red
func _connect_roles(from_role: int, to_role: int, rng: RandomNumberGenerator, role_to_id: Dictionary) -> void:
	if not role_to_id.has(from_role):
		return
	if not role_to_id.has(to_role):
		return
	
	var from_id: int = role_to_id[from_role]
	var to_id: int = role_to_id[to_role]

	self._connect_if_exists(from_id, to_id, rng)

func generate_random(num_vertices: int) -> void:
	self.clear()
	self.is_directed = true
	
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var max_vertices := 10
	var n := clampi(num_vertices, 1, max_vertices)
	
	var all_roles: Array = [
		Vertice.VertexRole.CENTRO_CONTROL,
		Vertice.VertexRole.ROUTER_CORE,
		Vertice.VertexRole.ROUTER_BORDE,
		Vertice.VertexRole.FIREWALL,
		Vertice.VertexRole.SERVIDOR_APP,
		Vertice.VertexRole.SERVIDOR_DB,
		Vertice.VertexRole.SERVIDOR_MAIL,
		Vertice.VertexRole.GATEWAY_VPN,
		Vertice.VertexRole.IDS,
		Vertice.VertexRole.CLIENTE
	]
	
	var remaining_roles: Array = all_roles.duplicate()
	remaining_roles.erase(Vertice.VertexRole.CENTRO_CONTROL)
	remaining_roles.shuffle()
	
	var role_to_id: Dictionary = {}
	
	for i in range(n):
		var v := self.add_vertex(i)
		v.is_infected = false
		if i == 0:
			v.set_role(Vertice.VertexRole.CENTRO_CONTROL)
		else:
			var role_index := i - 1
			if role_index < remaining_roles.size():
				v.set_role(remaining_roles[role_index])
			else:
				v.set_role(Vertice.VertexRole.CLIENTE)
		
		role_to_id[v.role] = i
	
	if n > 1:
		var candidates: Array[int] = []
		
		for i in range(1, n):
			var r: int = vertices[i].role
			if r in [
				Vertice.VertexRole.SERVIDOR_APP,
				Vertice.VertexRole.SERVIDOR_DB,
				Vertice.VertexRole.SERVIDOR_MAIL,
				Vertice.VertexRole.GATEWAY_VPN,
				Vertice.VertexRole.CLIENTE
			]:
				candidates.append(i)
		
		if candidates.is_empty():
			for i in range(1, n):
				candidates.append(i)
		
		var infected_id: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		self.vertices[infected_id].is_infected = true
		
		#Elegimos el nodo con pista
		var hint_candidates: Array[int] = []
		for i in range(n):
			if i == infected_id:
				continue
			hint_candidates.append(i)
		
		if not hint_candidates.is_empty():
			var hint_id: int = hint_candidates[rng.randi_range(0, hint_candidates.size() - 1)]
			var v_hint: Vertice = self.vertices[hint_id]
			v_hint.is_key_vertex = true
			
			if v_hint.hint == "":
				v_hint.hint = "Hay pista"
		
		if n == 1:
			var only_v: Vertice = self.vertices[0]
			only_v.is_key_vertex = true
			if only_v.hint == "":
				only_v.hint = "Hay Pista"
		
		#Conexiones logicas dentro de la red por rol
		
		#Ruta desde Centro Control hasta Servidor App
		self._connect_roles(Vertice.VertexRole.CENTRO_CONTROL, Vertice.VertexRole.ROUTER_CORE, rng, role_to_id)
		self._connect_roles(Vertice.VertexRole.ROUTER_CORE, Vertice.VertexRole.ROUTER_BORDE, rng, role_to_id)
		self._connect_roles(Vertice.VertexRole.ROUTER_BORDE, Vertice.VertexRole.FIREWALL, rng, role_to_id)
		self._connect_roles(Vertice.VertexRole.FIREWALL, Vertice.VertexRole.SERVIDOR_APP, rng, role_to_id)
		
		#Ruta de Core hacia Servidores internos
		self._connect_roles(Vertice.VertexRole.ROUTER_CORE, Vertice.VertexRole.SERVIDOR_DB, rng, role_to_id)
		self._connect_roles(Vertice.VertexRole.ROUTER_CORE, Vertice.VertexRole.SERVIDOR_MAIL, rng, role_to_id)
		
		#Ruta VPN hacia Core
		self._connect_roles(Vertice.VertexRole.GATEWAY_VPN, Vertice.VertexRole.ROUTER_CORE, rng, role_to_id)
		
		#Ruta IDS hacia Firewall
		self._connect_roles(Vertice.VertexRole.IDS, Vertice.VertexRole.FIREWALL, rng, role_to_id)
		
		#Ruta desde Borde y Servidor App hacia el cliente
		self._connect_roles(Vertice.VertexRole.ROUTER_BORDE, Vertice.VertexRole.CLIENTE, rng, role_to_id)
		self._connect_roles(Vertice.VertexRole.SERVIDOR_APP, Vertice.VertexRole.CLIENTE, rng, role_to_id)
		
		#Nos aseguramos que todos los vertices sean alcanzables desde CENTRO_CONTROL
		var source_id: int = role_to_id.get(Vertice.VertexRole.CENTRO_CONTROL)
		var reachable_from_source := self._get_reachable_from(source_id)
		
		for id in self.vertices.keys():
			if id == source_id:
				continue
			
			if not reachable_from_source.has(id):
				#Se conecta desde algun nodo alcanzable
				var candidates_from: Array = []
				for k in reachable_from_source.keys():
					if not self.has_edge(id, k):
						candidates_from.append(k)
				
				if candidates_from.is_empty():
					candidates_from = reachable_from_source.keys()
				
				var from_id: int = candidates_from[rng.randi_range(0, candidates_from.size()-1)]
				
				var from_v: Vertice = self.vertices[from_id]
				var to_v: Vertice = self.vertices[id]
				var params := self._random_edge_params(from_v.role, to_v.role, rng)
				self.add_edge(from_id, id, params["weight"], params["capacity"])
				
				reachable_from_source[id] = true
		
		#Nos aseguramos que todos los vertices tengan un camino hacia el cliente
		if role_to_id.has(Vertice.VertexRole.CLIENTE):
			var sink_id: int = role_to_id[Vertice.VertexRole.CLIENTE]
			var can_reach_sink := self._get_can_reach_to(sink_id)
			
			for id in self.vertices.keys():
				if id == sink_id:
					continue
				
				if not can_reach_sink.has(id):
					var candidates_to: Array = []
					for k in can_reach_sink.keys():
						if not self.has_edge(k, id):
							candidates_to.append(k)
					
					if candidates_to.is_empty():
						candidates_to = can_reach_sink.keys()
					
					var to_id: int = candidates_to[rng.randi_range(0, candidates_to.size()-1)]
					
					var from_v2: Vertice = self.vertices[id]
					var to_v2: Vertice = self.vertices[to_id]
					var params2 := self._random_edge_params(from_v2.role, to_v2.role, rng)
					self.add_edge(id, to_id, params2["weight"], params2["capacity"])
					
					can_reach_sink[id] = true
		
		#Generamos aristas extra de manera aleatoria
		var extra_prob := 0.0
		
		for i in range(n):
			for j in range(n):
				if i == j:
					continue
				
				if j == 0:
					continue
				
				if self.has_edge(i, j):
					continue
				
				if rng.randf() < extra_prob:
					var from_v: Vertice = self.vertices[i]
					var to_v: Vertice = self.vertices[j]
					var params := self._random_edge_params(from_v.role, to_v.role, rng)
					self.add_edge(i, j, params["weight"], params["capacity"])

func dijkstra(source_id: int, target_id: int) -> Array:
	if not has_vertex(source_id):
		return []
	if not has_vertex(target_id):
		return []
	
	var dist: Dictionary = {}
	var prev: Dictionary = {}
	var unvisited: Array = []
	
	# Inicializar distancias y predecesores
	for id in vertices.keys():
		dist[id] = INF
		prev[id] = -1
		unvisited.append(id)
	
	dist[source_id] = 0.0
	
	while not unvisited.is_empty():
		var u: int = -1
		var min_dist: float = INF
		
		# Tomar el nodo no visitado con menor distancia
		for id in unvisited:
			var d: float = dist[id]
			if d < min_dist:
				min_dist = d
				u = id
		
		# No hay más alcanzables
		if u == -1 or min_dist == INF:
			break
		
		unvisited.erase(u)
		
		# Si ya llegamos al destino, paramos
		if u == target_id:
			break
		
		# Relajar vecinos
		var neighbors: Array = get_neighbors_ids(u)
		for v in neighbors:
			if not unvisited.has(v):
				continue
			
			var w: float = get_weight(u, v, INF)
			if w == INF:
				continue
			
			var alt: float = dist[u] + w
			if alt < dist[v]:
				dist[v] = alt
				prev[v] = u
	
	# Si la distancia al destino sigue siendo infinita, no hay camino
	if dist[target_id] == INF:
		return []
	
	# Reconstruir camino
	var path: Array = []
	var curr: int = target_id
	
	while curr != -1:
		path.push_front(curr)
		curr = prev.get(curr, -1)
	
	if path.is_empty() or path[0] != source_id:
		return []
	
	return path

func print_path_info(g: Grafo, from_id: int, to_id: int) -> void:
	var path: Array = g.dijkstra(from_id, to_id)
	print("Dijkstra ", from_id, " -> ", to_id, " path: ", path)
	
	if path.is_empty():
		print("  (no hay camino)")
		return
	
	var total: float = 0.0
	for i in range(path.size() - 1):
		var u: int = path[i]
		var v: int = path[i + 1]
		total += g.get_weight(u, v, INF)
	print("  Distancia total: ", total)

#Metodo para hallar vertices alcanzables desde CENTRO_CONTROL
func _get_reachable_from(start_id: int) -> Dictionary:
	var visited: Dictionary = {}
	if not self.vertices.has(start_id):
		return visited
	
	var queue: Array = [start_id]
	visited[start_id] = true
	
	while not queue.is_empty():
		var u = queue.pop_front()
		if self.edges.has(u):
			for v in self.edges[u].keys():
				if not visited.has(v):
					visited[v] = true
					queue.append(v)
	
	return visited

#Metodo para hallar vertices que pueden llegar al CLIENTE
func _get_can_reach_to(target_id: int) -> Dictionary:
	var visited: Dictionary = {}
	if not self.vertices.has(target_id):
		return visited
	
	var queue: Array = [target_id]
	visited[target_id] = true
	
	while not queue.is_empty():
		var u = queue.pop_front()
		for from_id in self.edges.keys():
			if self.edges[from_id].has(u) and not visited.has(from_id):
				visited[from_id] = true
				queue.append(from_id)
	
	return visited

func get_control_id() -> int:
	for id in self.vertices.keys():
		var v: Vertice = self.vertices[id]
		if v.role == Vertice.VertexRole.CENTRO_CONTROL:
			return id
	return -1

func get_infected_id() -> int:
	for id in self.vertices.keys():
		var v: Vertice = self.vertices[id]
		if v.is_infected:
			return id
	return -1

func clear() -> void:
	vertices.clear()
	edges.clear()
