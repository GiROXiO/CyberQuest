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
	if self.edges.has(from_id) and self.edges[from_id].has(to_id):
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
				Vertice.VertexRole.GATEWAY_VPN
			]:
				candidates.append(i)
		
		if candidates.is_empty():
			for i in range(1, n):
				candidates.append(i)
		
		var infected_id: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		self.vertices[infected_id].is_infected = true
		
		#Elegimos el nodo con pista
		# Asignar pista únicamente a los nodos que ya tienen hint definido
		for id in self.vertices.keys():
			var v: Vertice = self.vertices[id]
			if v.hint != "":
				v.is_key_vertex = true

		# Si ninguno traía pista pero debe haber al menos uno, elegir el primero no infectado
		var any_key := false
		for v in self.vertices.values():
			if v.is_key_vertex:
				any_key = true
				break

		if not any_key:
			for id in self.vertices.keys():
				if id != infected_id:
					var v := self.vertices[id]
					v.is_key_vertex = true
					if v.hint == "":
						v.hint = "Hay pista"
					break
		# Después de asignar pistas en Grafo.gd
		
			
		
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

func prim(inicio_id: int) -> Array:
	if not self.vertices.has(inicio_id):
		push_error("El vértice inicial no existe en el grafo.")
		return []

	var visitados: Array = [inicio_id]
	var aristas_resultado: Array = []
	var aristas_resultado_arr: Array[Array] = []

	while visitados.size() < self.vertices.size():
		var menor_peso: float = INF
		var mejor_arista: Arista = null
		
		for v_id in visitados:
			for destino_id in self.vertices[v_id].neighbors:
				if destino_id in visitados:
					continue
				var arista_obj = self.edges[v_id][destino_id]
				if arista_obj.weight < menor_peso:
					menor_peso = arista_obj.weight
					mejor_arista = arista_obj

			for origen_id in self.vertices.keys():
				if v_id in self.vertices[origen_id].neighbors and origen_id not in visitados:
					var arista_obj = self.edges[origen_id][v_id]
					if arista_obj.weight < menor_peso:
						menor_peso = arista_obj.weight
						mejor_arista = arista_obj

		if mejor_arista == null:
			break

		aristas_resultado.append(mejor_arista)
		if mejor_arista.from_id in visitados:
			visitados.append(mejor_arista.to_id)
		else:
			visitados.append(mejor_arista.from_id)

	print("Árbol de expansión mínima:")
	for a in aristas_resultado:
		print("Origen:", a.from_id, " - Destino:", a.to_id, " - Peso:", a.weight)
		aristas_resultado_arr.append([a.from_id, a.to_id])

	return aristas_resultado_arr

func kruskal() -> Array:
	var n_vertices := self.vertices.size()
	if n_vertices == 0:
		return []
	if n_vertices == 1:
		return []

	var edges_map := {} 
	for from_id in self.edges.keys():
		for to_id in self.edges[from_id].keys():
			var a_obj: Arista = self.edges[from_id][to_id]
			var a_min: int = min(from_id, to_id)
			var a_max: int = max(from_id, to_id)
			var key := str(a_min) + "-" + str(a_max)

			if not edges_map.has(key):
				edges_map[key] = a_obj
			else:
				var exist: Arista = edges_map[key]
				if a_obj.weight < exist.weight:
					edges_map[key] = a_obj


	var edge_pairs := []
	for k in edges_map.keys():
		var a = edges_map[k]
		edge_pairs.append([a.weight, a])
	edge_pairs.sort()

	var parent := {}
	var rank := {}
	for id in self.vertices.keys():
		parent[id] = id
		rank[id] = 0

	var need_edges := n_vertices - 1
	var result_aristas := []
	var result_pairs := [] 

	for pair in edge_pairs:
		if result_aristas.size() >= need_edges:
			break

		var a: Arista = pair[1]
		var u := a.from_id
		var v := a.to_id

		var ru := u
		while parent[ru] != ru:
			parent[ru] = parent[parent[ru]]
			ru = parent[ru]

		var rv := v
		while parent[rv] != rv:
			parent[rv] = parent[parent[rv]]
			rv = parent[rv]

		if ru != rv:
			if rank[ru] < rank[rv]:
				parent[ru] = rv
			elif rank[rv] < rank[ru]:
				parent[rv] = ru
			else:
				parent[rv] = ru
				rank[ru] += 1

			result_aristas.append(a)
			result_pairs.append([a.from_id, a.to_id])

	if result_aristas.size() < need_edges:
		print("kruskal: grafo no conectado, result size=", result_aristas.size(), " need=", need_edges)

	print("Árbol de expansión mínima (Kruskal):")
	for a in result_aristas:
		print("Origen:", a.from_id, " - Destino:", a.to_id, " - Peso:", a.weight)

	return result_pairs


func dijkstra(source_id: int, target_id: int) -> Array[int]:
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
	var path: Array[int] = []
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

func get_client_id() -> int:
	for id in vertices.keys():
		var v: Vertice = vertices[id]
		if v.role == Vertice.VertexRole.CLIENTE:
			return id
	return -1

func clear() -> void:
	vertices.clear()
	edges.clear()

func bfs(start_id: int) -> Array[int]:
	if not vertices.has(start_id):
		return []
	
	var target_id = get_infected_id()
	if target_id == -1:
		return []

	var queue: Array[int] = [start_id]
	var visited: Array[int] = []
	
	while not queue.is_empty():
		var current = queue.pop_front()

		# Evitar duplicados
		if current not in visited:
			visited.append(current)

		# Si encontramos el infectado, paramos y devolvemos lo visitado
		if current == target_id:
			return visited

		# Expandimos el BFS
		for neighbor in get_neighbors_ids(current):
			if neighbor not in visited and neighbor not in queue:
				queue.append(neighbor)
	
	return visited



func dfs(start_id: int) -> Array[int]:
	if not vertices.has(start_id):
		return []
	
	var target_id = get_infected_id()
	if target_id == -1:
		return []
	
	var stack: Array[int] = [start_id]
	var visited: Array[int] = []
	
	while not stack.is_empty():
		var current = stack.pop_back()
		
		if current not in visited:
			visited.append(current)

			# Si encontramos el infectado, regresamos el recorrido completo hasta ese punto
			if current == target_id:
				return visited
			
			# DFS: agregar en orden inverso para mantener el orden correcto
			var neighbors = get_neighbors_ids(current)
			for i in range(neighbors.size() - 1, -1, -1):
				var neighbor = neighbors[i]
				if neighbor not in visited and neighbor not in stack:
					stack.append(neighbor)

	return visited



func _reconstruct_path(parent: Dictionary, end: int) -> Array[int]:
	var path: Array[int] = []
	var node = end
	while node != null:
		path.insert(0, node)
		node = parent.get(node, null)
	return path


# Utils para Ford Fulkerson
func reset_all_flows() -> void:
	for from_id in self.edges.keys():
		for to_id in self.edges[from_id].keys():
			var e: Arista = self.edges[from_id][to_id]
			if e != null:
				e.flow = 0.0

func get_residual_capacity(from_id: int, to_id: int) -> int:
	var e: Arista = self.get_edge(from_id, to_id)
	if e == null:
		return 0
	var residual := e.capacity - e.flow
	return max(0, residual)

func ford_fulkerson_max_flow(source_id: int, sink_id: int) -> int:
	if not vertices.has(source_id) or not vertices.has(sink_id):
		return 0
	
	# Grafo residual interno: residual[u][v] = capacidad residual (int)
	var residual: Dictionary = {}
	for from_id in edges.keys():
		residual[from_id] = {}
		for to_id in edges[from_id].keys():
			var e: Arista = edges[from_id][to_id]
			residual[from_id][to_id] = e.capacity
	
	var max_flow: int = 0
	var INF := 1_000_000_000
	
	while true:
		var parent: Dictionary = {}
		if not _bfs_residual(source_id, sink_id, residual, parent):
			break
		
		# Bottleneck del camino encontrado
		var path_flow: int = INF
		var v: int = sink_id
		
		while v != source_id:
			var u: int = int(parent[v])
			var cap: int = 0
			if residual.has(u) and residual[u].has(v):
				cap = int(residual[u][v])
			if cap < path_flow:
				path_flow = cap
			v = u
		
		if path_flow <= 0 or path_flow == INF:
			break
		
		max_flow += path_flow
		
		# Actualizar residual (forward y backward)
		v = sink_id
		while v != source_id:
			var u: int = int(parent[v])
			
			# Forward
			if residual.has(u) and residual[u].has(v):
				residual[u][v] = int(residual[u][v]) - path_flow
			
			# Backward
			if not residual.has(v):
				residual[v] = {}
			residual[v][u] = int(residual[v].get(u, 0)) + path_flow
			
			v = u
	
	return max_flow


func _bfs_residual(source_id: int, sink_id: int, residual: Dictionary, parent: Dictionary) -> bool:
	parent.clear()
	var visited: Dictionary = {}
	var queue: Array[int] = []
	
	queue.append(source_id)
	visited[source_id] = true
	
	while not queue.is_empty():
		var u: int = queue.pop_front()
		
		if not residual.has(u):
			continue
		
		for v in residual[u].keys():
			var cap: int = int(residual[u][v])
			if cap > 0 and not visited.has(v):
				parent[v] = u
				visited[v] = true
				if v == sink_id:
					return true
				queue.append(v)
	
	return false

# ----------------- Ford-Fulkerson / Edmonds-Karp -----------------

func max_flow(source_id: int, sink_id: int) -> int:
	# Red residual: residual[u][v] = capacidad residual (entera)
	var residual: Dictionary = {}

	# Inicializamos diccionarios vacíos para todos los vértices
	for id in vertices.keys():
		residual[id] = {}

	# Copiamos capacidades originales a la red residual
	for from_id in edges.keys():
		for to_id in edges[from_id].keys():
			var e: Arista = edges[from_id][to_id]
			var c: int = int(e.capacity)

			# arco forward
			if not residual[from_id].has(to_id):
				residual[from_id][to_id] = 0
			residual[from_id][to_id] = int(residual[from_id][to_id]) + c

			# arco backward debe existir con capacidad 0
			if not residual[to_id].has(from_id):
				residual[to_id][from_id] = 0

	var max_flow_value: int = 0

	while true:
		var parent: Dictionary = {}
		var path_cap: int = _bfs_augmenting_path(residual, source_id, sink_id, parent)

		if path_cap <= 0:
			break  # ya no hay más caminos aumentantes

		# 🟢 Reconstruimos el camino s → … → t para imprimirlo
		var path: Array[int] = []
		var v: int = sink_id

		while v != source_id and parent.has(v):
			path.insert(0, v)
			v = int(parent[v])

		path.insert(0, source_id)

		print("[MaxFlow] Camino aumentante encontrado: ", path, " | capacidad: ", path_cap)

		# Aumentamos el flujo total
		max_flow_value += path_cap

		# Actualizamos la red residual a lo largo de ese camino
		v = sink_id
		while v != source_id:
			var u: int = int(parent[v])

			residual[u][v] = int(residual[u][v]) - path_cap
			residual[v][u] = int(residual[v][u]) + path_cap

			v = u

	print("[MaxFlow] Flujo máximo total: ", max_flow_value)
	return max_flow_value


# BFS en la red residual, devuelve la capacidad del camino (enteros)
func _bfs_augmenting_path(residual: Dictionary, source_id: int, sink_id: int, parent: Dictionary) -> int:
	var visited: Dictionary = {}
	var queue: Array[int] = []
	
	queue.append(source_id)
	visited[source_id] = true
	parent[source_id] = -1
	
	while not queue.is_empty():
		var u: int = queue.pop_front()
		
		for v in residual[u].keys():
			var cap: int = int(residual[u][v])
			if cap > 0 and not visited.has(v):
				visited[v] = true
				parent[v] = u
				queue.append(v)
				
				if v == sink_id:
					# Reconstruimos la capacidad mínima del camino
					var path_cap: int = 0
					var cur: int = sink_id
					var first: bool = true
					
					while cur != source_id:
						var prev: int = int(parent[cur])
						var edge_cap: int = int(residual[prev][cur])
						
						if first:
							path_cap = edge_cap
							first = false
						elif edge_cap < path_cap:
							path_cap = edge_cap
						
						cur = prev
					
					return path_cap
	
	# No se alcanzó el sumidero
	return 0

## Deja solo las aristas listadas en mst_edges y borra el resto.
## mst_edges: Array de pares [u, v] que pertenecen al árbol mínimo.
func keep_only_edges(mst_edges: Array) -> void:
	var allowed: Dictionary = {}
	
	for pair in mst_edges:
		if pair.size() < 2:
			continue
		var u: int = pair[0]
		var v: int = pair[1]
		
		if not allowed.has(u):
			allowed[u] = {}
		allowed[u][v] = true
	
		if not self.is_directed:
			if not allowed.has(v):
				allowed[v] = {}
			allowed[v][u] = true
	
	var to_remove_edges: Array[Array] = []
	
	for from_id in self.edges.keys():
		for to_id in self.edges[from_id].keys():
			var keep: bool = allowed.has(from_id) and allowed[from_id].has(to_id)
			if not keep:
				to_remove_edges.append([from_id, to_id])
	
	for pair in to_remove_edges:
		self.remove_edge(pair[0], pair[1])
	
	self._remove_isolated_vertices()

func _remove_isolated_vertices() -> void:
	var to_remove_vertices: Array[int] = []
	
	var source_id: int = -1
	var sink_id: int = -1
	
	if has_method("get_control_id"):
		source_id = self.get_control_id()
	if has_method("get_client_id"):
		sink_id = self.get_client_id()
	
	for vid in self.vertices.keys():
		if vid == source_id or vid == sink_id:
			continue

		var has_edge: bool = false

		# Aristas salientes
		if self.edges.has(vid) and not self.edges[vid].is_empty():
			has_edge = true

		# Aristas entrantes
		if not has_edge:
			for from_id in self.edges.keys():
				if from_id == vid:
					continue
				if self.edges[from_id].has(vid):
					has_edge = true
					break

		# Si no tiene ninguna arista, lo marcamos para eliminar
		if not has_edge:
			to_remove_vertices.append(vid)

	# Borramos los vértices aislados
	for vid in to_remove_vertices:
		self.remove_vertex(vid)
