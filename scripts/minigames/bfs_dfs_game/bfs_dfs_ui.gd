extends Control
class_name BfsDfsUi

signal bfs_dfs_completed(success: bool)

@onready var info_label: Label = $InfoLabel
@onready var check_button: Button = $CheckButton
@onready var mode_selector: OptionButton = $ModeSelector
@onready var message_label: RichTextLabel = $MessageLabel

var grafo: Grafo = null
var grafo_vista: GrafoVista = null

var search_mode: String = "BFS"
var correct_path: Array[int] = []
var player_path: Array[int] = []
var is_playing: bool = false

var player_edges: Array = []
var search_parents: Dictionary = {}

var PISTAS: Dictionary = {
	Vertice.VertexRole.FIREWALL: {
		Vertice.VertexRole.SERVIDOR_DB: "Los registros muestran actividad extraña cercana a la capa externa.",
		Vertice.VertexRole.SERVIDOR_MAIL: "El ataque parece venir desde una ubicación accesible desde el exterior.",
		Vertice.VertexRole.SERVIDOR_APP: "Detecté intentos de bypass en mi perímetro.",
		Vertice.VertexRole.GATEWAY_VPN: "La intrusión no pasó primero por mí, pero sí por una ruta expuesta.",
		Vertice.VertexRole.IDS: "Detecto anomalías desde una zona distinta a mi perímetro."
	},
	Vertice.VertexRole.SERVIDOR_APP: {
		Vertice.VertexRole.FIREWALL: "El código malicioso no provino del perímetro de red.",
		Vertice.VertexRole.SERVIDOR_DB: "La corrupción se propagó desde servicios de aplicación.",
		Vertice.VertexRole.SERVIDOR_MAIL: "Detecté ejecución anómala en capas de procesamiento.",
		Vertice.VertexRole.GATEWAY_VPN: "El exploit no llegó por acceso remoto directo.",
		Vertice.VertexRole.IDS: "Identifico patrones de ataque a nivel de lógica de negocio."
	},
	Vertice.VertexRole.SERVIDOR_DB: {
		Vertice.VertexRole.FIREWALL: "El origen de la corrupción no proviene del borde de la red.",
		Vertice.VertexRole.SERVIDOR_APP: "La inyección vino de la capa de aplicación.",
		Vertice.VertexRole.SERVIDOR_MAIL: "La filtración parece estar entre nodos internos.",
		Vertice.VertexRole.GATEWAY_VPN: "No viene de acceso remoto directo, pero sí de comunicación interna.",
		Vertice.VertexRole.IDS: "Detecto patrones pero no se originan en bases de datos."
	},
	Vertice.VertexRole.SERVIDOR_MAIL: {
		Vertice.VertexRole.FIREWALL: "No parece venir del tráfico exterior directo.",
		Vertice.VertexRole.SERVIDOR_APP: "El malware no se ejecutó primero en aplicaciones.",
		Vertice.VertexRole.SERVIDOR_DB: "El problema no está en almacenamiento centralizado.",
		Vertice.VertexRole.GATEWAY_VPN: "Pudo circular en comunicación, pero no desde correo.",
		Vertice.VertexRole.IDS: "Rastreo el patrón fuera de este canal de mensajes."
	},
	Vertice.VertexRole.GATEWAY_VPN: {
		Vertice.VertexRole.FIREWALL: "La entrada no provino de acceso no autorizado externo.",
		Vertice.VertexRole.SERVIDOR_APP: "No se originó en servicios de aplicación web.",
		Vertice.VertexRole.SERVIDOR_DB: "Pudo haber sido distribuido internamente pero no desde el gateway.",
		Vertice.VertexRole.SERVIDOR_MAIL: "No se originó en comunicación electrónica directa.",
		Vertice.VertexRole.IDS: "Mi canal está limpio, sigue buscando en red interna."
	},
	Vertice.VertexRole.IDS: {
		Vertice.VertexRole.FIREWALL: "No detecto origen inicial en la frontera de red.",
		Vertice.VertexRole.SERVIDOR_APP: "Las aplicaciones no muestran el patrón de origen.",
		Vertice.VertexRole.SERVIDOR_DB: "Los datos almacenados no parecen comprometidos inicialmente.",
		Vertice.VertexRole.SERVIDOR_MAIL: "Los logs del correo no coinciden con el patrón inicial.",
		Vertice.VertexRole.GATEWAY_VPN: "No provino directamente de un acceso remoto controlado."
	},
	Vertice.VertexRole.ROUTER_CORE: {
		Vertice.VertexRole.FIREWALL: "El tráfico anómalo no se originó en el perímetro.",
		Vertice.VertexRole.SERVIDOR_APP: "Rastreo paquetes sospechosos desde el núcleo de red.",
		Vertice.VertexRole.SERVIDOR_DB: "La propagación vino del enrutamiento central.",
		Vertice.VertexRole.SERVIDOR_MAIL: "Detecté redirecciones no autorizadas desde mi core.",
		Vertice.VertexRole.GATEWAY_VPN: "No es un ataque desde conexiones remotas.",
		Vertice.VertexRole.IDS: "Los logs apuntan al tráfico del núcleo de red."
	},
	Vertice.VertexRole.ROUTER_BORDE: {
		Vertice.VertexRole.FIREWALL: "La brecha se abrió en la capa de borde.",
		Vertice.VertexRole.SERVIDOR_APP: "El compromiso llegó desde la frontera de la red.",
		Vertice.VertexRole.SERVIDOR_DB: "Detecté tráfico inusual entrando por el borde.",
		Vertice.VertexRole.SERVIDOR_MAIL: "Los paquetes maliciosos transitaron por aquí primero.",
		Vertice.VertexRole.GATEWAY_VPN: "No vino de VPN, sino de otra entrada externa.",
		Vertice.VertexRole.IDS: "Rastreo el origen en el perímetro de entrada."
	},
	Vertice.VertexRole.CLIENTE: {
		Vertice.VertexRole.FIREWALL: "El endpoint comprometido está dentro de la red.",
		Vertice.VertexRole.SERVIDOR_APP: "El malware se ejecutó primero en un cliente final.",
		Vertice.VertexRole.SERVIDOR_DB: "La infección provino de un usuario comprometido.",
		Vertice.VertexRole.SERVIDOR_MAIL: "El phishing exitoso comprometió este cliente.",
		Vertice.VertexRole.GATEWAY_VPN: "No fue un ataque remoto, sino interno.",
		Vertice.VertexRole.IDS: "Detecté comportamiento anómalo en este endpoint."
	}
}

func _ready() -> void:
	mode_selector.add_item("BFS")
	mode_selector.add_item("DFS")
	check_button.text = "Iniciar"
	check_button.pressed.connect(_on_check_button_pressed)
	info_label.text = "Selecciona un modo y rastrea la infección."
	message_label.text = ""

func set_graph(p_grafo: Grafo) -> void:
	grafo = p_grafo

func set_graph_view(p_view: GrafoVista) -> void:
	grafo_vista = p_view
	if grafo_vista:
		grafo_vista.graph_vertex_clicked.connect(_on_vertex_clicked)
	else:
		push_warning("[BfsDfsUi] grafo_vista no asignado en set_graph_view.")

func _on_check_button_pressed() -> void:
	MusicPlayer.play_music("res://musica/boton2.mp3")
	if grafo == null:
		info_label.text = "No hay grafo cargado."
		return

	var control_id: int = grafo.get_control_id()
	if control_id == -1:
		info_label.text = "No se encontró el Centro de Control."
		return

	var infected_id: int = grafo.get_infected_id()
	if infected_id == -1:
		info_label.text = "No hay nodo infectado definido."
		return

	if grafo.has_method("set_grafo_role_message"):
		for role in PISTAS.keys():
			for related_role in PISTAS[role].keys():
				var msg = PISTAS[role][related_role]
				grafo.set_grafo_role_message(related_role, msg)

	var selected_index: int = mode_selector.get_selected_id()
	search_mode = mode_selector.get_item_text(selected_index)
	message_label.text = ""
	player_path.clear()
	correct_path.clear()
	player_edges.clear()
	search_parents.clear()
	
	if self.grafo_vista:
		if self.grafo_vista.has_method("clear_all_edge_flows"):
			self.grafo_vista.clear_all_edge_flows()
		if self.grafo_vista.has_method("reset_view_state"):
			self.grafo_vista.reset_view_state()
	
	marcar_vertices_con_pista()

	var full_order: Array = []
	if search_mode.begins_with("BFS"):
		full_order = grafo.bfs(control_id)
	else:
		full_order = grafo.dfs(control_id)

	var idx: int = full_order.find(infected_id)
	if idx != -1:
		correct_path = full_order.slice(0, idx + 1)
	else:
		correct_path = full_order.duplicate()

	if correct_path.is_empty():
		info_label.text = "No se generó una ruta válida."
		return

	_build_search_parents(control_id)

	print("[BfsDfsUi] correct_path:", correct_path)
	is_playing = true
	info_label.text = "Rastreo iniciado. Llega al nodo infectado siguiendo %s" % search_mode
	message_label.text = ""
	if grafo_vista and grafo_vista.has_method("reset_highlight"):
		grafo_vista.reset_highlight()
	for v in grafo_vista.get_children():
			if v is VerticeVista:
				v.refresh_hint()

func _on_vertex_clicked(node_id: int, is_selected: bool) -> void:
	if not is_playing:
		return
		
	if not is_selected:
		if not self.player_path.has(node_id):
			return
		
		self.player_path.erase(node_id)
		
		self._rebuild_edges_from_player_path()
		self._update_path_view()
		return
	
	#  Seleccion
	if node_id in self.player_path:
		return
	
	player_path.append(node_id)

	var v: Vertice = grafo.get_vertex(node_id)
	var role_name := _role_to_string(v.role)

	if grafo_vista:
		grafo_vista.highlight_vertex(node_id, Color(0.4, 0.9, 1.0))
	message_label.text += "\nNodo seleccionado: %s" % role_name

	var infected_id: int = grafo.get_infected_id()
	if infected_id == -1:
		message_label.text += "\nNo hay nodo infectado definido."
		return
	
	var infected_vertex: Vertice = grafo.get_vertex(infected_id)
	
	if v.is_key_vertex:
		if PISTAS.has(infected_vertex.role):
			if PISTAS[infected_vertex.role].has(v.role):
				var pista_real = PISTAS[infected_vertex.role][v.role]
				message_label.text += "\nPista: %s" % pista_real

	var idx := player_path.size() - 1
	if correct_path.is_empty():
		message_label.text += "\nUsa 'Iniciar búsqueda' antes de jugar."
		_fail_sequence()
		return

	if idx >= correct_path.size():
		_fail_sequence()
		return

	if node_id != correct_path[idx]:
		_fail_sequence()
		return

	self._add_edge_for_node(node_id)

	if player_path.size() == correct_path.size():
		_success_sequence()

	_update_path_view()

func _rebuild_edges_from_player_path():
	self.player_edges.clear()
	if self.grafo == null:
		return
	if self.correct_path.is_empty():
		return
	
	for node_id in self.player_path:
		self._add_edge_for_node(node_id)

func _add_edge_for_node(node_id: int) -> void:
	if self.player_path.size() <= 1:
		return
	if self.grafo == null:
		return
	if self.correct_path.is_empty():
		return
	
	if node_id == self.correct_path[0]:
		return
	
	if not self.search_parents.has(node_id):
		return
	
	var parent_id: int = self.search_parents[node_id]
	if parent_id == -1:
		return
	
	if not self.player_path.has(parent_id):
		return
	
	# Debe existir arista entre parent_id y node_id
	if not (self.grafo.has_edge(parent_id, node_id) or self.grafo.has_edge(node_id, parent_id)):
		return
	
	var edge: Array = [parent_id, node_id]
	
	# Evitamos duplicados
	for e in self.player_edges:
		if e.size() == 2 and e[0] == edge[0] and e[1] == edge[1]:
			return
	
	self.player_edges.append(edge)

func _update_path_view() -> void:
	if self.grafo_vista == null:
		return
	
	if self.grafo_vista.has_method("set_path_edges_mod2"):
		self.grafo_vista.set_path_edges_mod2(self.player_edges)

func _build_search_parents(start_id: int) -> void:
	self.search_parents.clear()
	if self.grafo == null:
		return
	
	if self.search_mode.begins_with("BFS"):
		_build_parent_map_bfs(start_id)
	else:
		_build_parent_map_dfs(start_id)

func _build_parent_map_bfs(start_id) -> void:
	var visited: Dictionary = {}
	var queue: Array[int] = []
	
	queue.append(start_id)
	visited[start_id] = true
	self.search_parents[start_id] = -1
	
	while not queue.is_empty():
		var current: int = queue.pop_front()
		for neighbor in self.grafo.get_neighbors_ids(current):
			if not visited.has(neighbor):
				visited[neighbor] = true
				self.search_parents[neighbor] = current
				queue.append(neighbor)

func _build_parent_map_dfs(start_id) -> void:
	self.search_parents.clear()
	
	if self.grafo == null:
		return
	if self.correct_path.is_empty():
		return
	
	var root_id: int = self.correct_path[0]
	self.search_parents[root_id] = -1
	
	for i in range(1, self.correct_path.size()):
		var node_id: int = self.correct_path[i]
		var parent_id: int = -1
		
		for j in range(i - 1, -1, -1):
			var candidate: int = self.correct_path[j]
			if self.grafo.has_edge(candidate, node_id) or grafo.has_edge(node_id, candidate):
				parent_id = candidate
				break
		
		self.search_parents[node_id] = parent_id

func _fail_sequence() -> void:
	MusicPlayer.play_music("res://musica/error.mp3")
	is_playing = false
	info_label.text = "Secuencia incorrecta. Intenta nuevamente."
	message_label.text += "\nLa ruta no corresponde."

	player_path.clear()
	player_edges.clear()

	if grafo_vista:
		if grafo_vista.has_method("reset_highlight"):
			grafo_vista.reset_highlight()
		if grafo_vista.has_method("reset_view_state"):
			grafo_vista.reset_view_state()
		if grafo_vista.has_method("flash_error"):
			grafo_vista.flash_error()

func _success_sequence() -> void:
	is_playing = false
	info_label.text = "Rastreo completado. Código de restauración desbloqueado."
	message_label.text += "\nHas identificado todo el recorrido del ataque."
	
	player_edges.clear()
	
	if grafo_vista and grafo_vista.has_method("flash_success"):
		grafo_vista.flash_success()
	if grafo_vista:
		grafo_vista.clear_all_edge_flows()
		if grafo_vista.has_method("reset_highlight"):
			grafo_vista.reset_highlight()
		if grafo_vista.has_method("reset_view_state"):
			grafo_vista.reset_view_state()
		
	emit_signal("bfs_dfs_completed", true)

func _set_message(text: String) -> void:
	if info_label:
		info_label.visible = true
		info_label.text = text

func _clear_message() -> void:
	if info_label:
		info_label.text = ""
		info_label.visible = false

func _role_to_string(role: int) -> String:
	match role:
		Vertice.VertexRole.CENTRO_CONTROL: return "Centro de Control"
		Vertice.VertexRole.ROUTER_CORE: return "Router Core"
		Vertice.VertexRole.ROUTER_BORDE: return "Router de Borde"
		Vertice.VertexRole.FIREWALL: return "Firewall"
		Vertice.VertexRole.SERVIDOR_APP: return "Servidor de Aplicaciones"
		Vertice.VertexRole.SERVIDOR_DB: return "Servidor de Base de Datos"
		Vertice.VertexRole.SERVIDOR_MAIL: return "Servidor de Correo"
		Vertice.VertexRole.GATEWAY_VPN: return "Gateway VPN"
		Vertice.VertexRole.IDS: return "Sistema IDS"
		Vertice.VertexRole.CLIENTE: return "Cliente Infectado"
		_: return "Nodo"

func marcar_vertices_con_pista() -> void:
	if grafo == null:
		return

	var infected_id: int = grafo.get_infected_id()
	if infected_id == -1:
		return

	var infected_vertex: Vertice = grafo.get_vertex(infected_id)
	var infected_role = infected_vertex.role
	print("[DEBUG] Nodo infectado ID: ", infected_id, " Role: ", infected_role)

	for id in grafo.vertices.keys():
		var v: Vertice = grafo.get_vertex(id)
		v.is_key_vertex = false
		v.hint = ""

	if not PISTAS.has(infected_role):
		return

	var pistas_rol = PISTAS[infected_role]

	for id in grafo.vertices.keys():
		if id == infected_id:
			continue

		var v: Vertice = grafo.get_vertex(id)

		if pistas_rol.has(v.role): 
			v.is_key_vertex = true
			v.hint = "Hay pista"
	
	if grafo_vista:
		for child in grafo_vista.get_children():
			if child is VerticeVista:
				child.refresh_hint()
