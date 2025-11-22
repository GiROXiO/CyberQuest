extends Control
class_name MaxFlowUi

signal minigame_completed(success: bool)

@onready var title_label: Label = $TitleLabel
@onready var message_label: Label = $MessageLabel
@onready var add_flow_button: Button = $Buttons/AddFlowButton
@onready var verify_button: Button = $Buttons/VerifyButton

var grafo: Grafo = null
var grafo_vista: GrafoVista = null

var source_id: int = -1
var sink_id: int = -1

# Camino que el jugador está armando ahora mismo
var current_path: Array[int] = []

# Flujo total que ha sumado el jugador
var user_total_flow: int = 0

# Flujo máximo correcto (calculado con Ford-Fulkerson en Grafo)
var optimal_max_flow: int = 0

# Flujo ya usado por el jugador en cada arista: { from_id: { to_id: flow_int } }
var used_flow: Dictionary = {}


func _ready() -> void:
	if title_label:
		title_label.text = "Flujo Máximo con Ford-Fulkerson"
	
	if message_label:
		message_label.text = ""
	
	if add_flow_button:
		add_flow_button.text = "Añadir flujo"
		add_flow_button.pressed.connect(_on_add_flow_pressed)
	
	if verify_button:
		verify_button.text = "Verificar flujo"
		verify_button.pressed.connect(_on_verify_pressed)


func set_graph(p_grafo: Grafo) -> void:
	grafo = p_grafo


func set_graph_view(p_view: GrafoVista) -> void:
	grafo_vista = p_view


func start_minigame() -> void:
	if grafo == null:
		push_warning("[MaxFlowUi] No hay grafo asignado.")
		return
	
	# Fuente: Centro de Control, Sumidero: Cliente
	source_id = grafo.get_control_id()
	sink_id = grafo.get_client_id()
	
	if source_id == -1 or sink_id == -1:
		push_warning("[MaxFlowUi] No se pudo determinar fuente o sumidero.")
		return
	
	self._reconectar_grafo()
	
	# Calculamos el flujo máximo correcto UNA sola vez
	optimal_max_flow = grafo.max_flow(source_id, sink_id)
	print("[MaxFlowUi] Flujo máximo correcto=", optimal_max_flow)
	
	# Reset estado del minijuego
	current_path.clear()
	user_total_flow = 0
	used_flow.clear()
	_clear_message()
	
	if grafo_vista:
		if grafo_vista.has_method("reset_view_state"):
			grafo_vista.reset_view_state()
		if grafo_vista.has_method("refresh_from_graph"):
			grafo_vista.refresh_from_graph()
		if grafo_vista.has_method("clear_all_edge_flows"):
			grafo_vista.clear_all_edge_flows()
		# Ayuda visual mínima: resaltar fuente y sumidero
		grafo_vista.highlight_vertex(source_id, Color(0.2, 0.9, 0.4))
		grafo_vista.highlight_vertex(sink_id, Color(0.9, 0.4, 0.2))
	
	_set_message("Selecciona caminos desde el Centro de Control hasta el Cliente.\n" +
		"Pulsa 'Añadir flujo' para sumar el flujo de cada camino.")


# Llamado desde GameManager al hacer click en un vértice del grafo
func on_vertex_clicked_from_graph(vertex_id: int, is_selected: bool) -> void:
	if grafo == null:
		return
	
	_clear_message()
	
	if not is_selected:
		# Si deseleccionan, para no complicarnos con casos intermedios
		# simplemente reseteamos el camino actual.
		if not current_path.is_empty():
			current_path.clear()
			if grafo_vista:
				grafo_vista.set_path_edges([])
		_set_message("Camino reiniciado.")
		return
	
	# --- Selección ---
	if current_path.is_empty():
		# El primer vértice DEBE ser la fuente
		if vertex_id != source_id:
			_set_message("Debes iniciar en el Centro de Control.")
			return
		current_path.append(vertex_id)
		if grafo_vista:
			grafo_vista.set_path_edges(current_path)
		_set_message("Camino iniciado. Llega hasta el Cliente.")
	else:
		var last_id: int = current_path.back()
		# Solo permitimos avanzar por aristas válidas
		if not grafo.has_edge(last_id, vertex_id):
			_set_message("Solo puedes moverte por aristas existentes.")
			return
		
		current_path.append(vertex_id)
		if grafo_vista:
			grafo_vista.set_path_edges(current_path)
		
		if vertex_id == sink_id:
			_set_message("Camino completo. Pulsa 'Añadir flujo' para usarlo.")
		else:
			_set_message("Sigue extendiendo el camino hasta el Cliente.")


# Botón "Añadir flujo"
func _on_add_flow_pressed() -> void:
	if grafo == null:
		return
	
	if current_path.size() < 2:
		_set_message("Primero selecciona un camino desde el Centro de Control hasta el Cliente.")
		return
	
	if current_path.front() != source_id or current_path.back() != sink_id:
		_set_message("El camino debe empezar en el Centro de Control y terminar en el Cliente.")
		return
	
	# Calculamos la capacidad residual mínima del camino (bottleneck)
	var bottleneck: int =self._compute_path_bottleneck(current_path)
	
	if bottleneck <= 0:
		_set_message("Este camino ya está totalmente saturado. No aporta más flujo.")
		return
	
	# Aplicamos el flujo al camino
	_apply_flow_to_path(current_path, bottleneck)
	user_total_flow += bottleneck
	
	_set_message("Se añadió flujo " + str(bottleneck) +
		". Flujo total acumulado: " + str(user_total_flow) + ".")
	
	# Reset para que el jugador arme otro camino
	current_path.clear()
	if grafo_vista:
		self.grafo_vista.reset_view_state()
		# Re-marcamos fuente y sumidero para no perder referencia
		grafo_vista.highlight_vertex(source_id, Color(0.2, 0.9, 0.4))
		grafo_vista.highlight_vertex(sink_id, Color(0.9, 0.4, 0.2))


# Botón "Verificar flujo"
func _on_verify_pressed() -> void:
	if grafo == null:
		return
	
	if user_total_flow == optimal_max_flow:
		_set_message("¡Correcto! El flujo máximo es " + str(user_total_flow) + ".")
		minigame_completed.emit(true)
	else:
		_set_message("Aún no has encontrado el flujo máximo.\n" +
			"Tu flujo: " + str(user_total_flow) +
			" | Flujo máximo real: " + str(optimal_max_flow))


# ----------------- Helpers internos -----------------

func _clear_message() -> void:
	if message_label:
		message_label.text = ""


func _set_message(text: String) -> void:
	if message_label:
		message_label.text = text


# Capacidad residual mínima en el camino actual (enteros)
func _compute_path_bottleneck(path: Array[int]) -> int:
	var bottleneck: int = 0
	var first: bool = true
	
	for i in range(path.size() - 1):
		var u: int = path[i]
		var v: int = path[i + 1]
		
		var edge: Arista = grafo.get_edge(u, v)
		if edge == null:
			# Esto no debería pasar si validamos has_edge antes
			return 0
		
		var capacity: int = edge.capacity
		
		var used_from_u: Dictionary = used_flow.get(u, {})
		var already_used: int = int(used_from_u.get(v, 0))
		
		var residual: int = capacity - already_used
		if residual < 0:
			residual = 0
		
		if first:
			bottleneck = residual
			first = false
		else:
			if residual < bottleneck:
				bottleneck = residual
	
	return bottleneck


# UTILS
func _apply_flow_to_path(path: Array[int], amount: int) -> void:
	for i in range(path.size() - 1):
		var u: int = path[i]
		var v: int = path[i + 1]
		
		var used_from_u: Dictionary = used_flow.get(u, {})
		var prev: int = int(used_from_u.get(v, 0))
		used_from_u[v] = prev + amount
		used_flow[u] = used_from_u
		
		# Si quieres reflejar el flujo en la vista, aquí sería el lugar:
		if grafo_vista and grafo_vista.has_method("set_edge_flow"):
			grafo_vista.set_edge_flow(u, v, used_from_u[v])

func _reconectar_grafo() -> void:
	if self.grafo == null:
		return
	
	var source := self.source_id
	var sink := self.sink_id
	
	var main_path: Array[int] = self.grafo.dijkstra(source, sink)
	
	if main_path.is_empty():
		self.grafo.add_edge(source, sink, 1, randi_range(12, 22))
		main_path = [source, sink]
	
	# HALLAMOS VERTICES QUE NO ESTAN EN EL CAMINO PRINCIPAL
	var all_ids: Array[int] = self.grafo.get_vertices_ids()
	var off_path_nodes: Array[int] = []
	for id in all_ids:
		if not main_path.has(id) and id != source and id != sink:
			off_path_nodes.append(id)
	
	# RECONECTAMOS CON RUTAS SIMPLES CON UN VERTICE INTERMEDIO
	if off_path_nodes.is_empty():
		if main_path.size() >= 3:
			var mid := main_path[int(main_path.size() / 2)]
			if not self.grafo.has_edge(source, mid):
				self.grafo.add_edge(source, mid, 1, randi_range(10, 20))
			if not self.grafo.has_edge(mid, sink):
				self.grafo.add_edge(mid, sink, 1, randi_range(10, 20))
		return
	
	# CREAMOS RUTAS ALTERNAS CON LOS VERTICES QUE ESTAN FUERA DEL CAMINO PRINCIPAL
	off_path_nodes.shuffle()
	
	for node in off_path_nodes:
		if not self.grafo.has_edge(source, node):
			self.grafo.add_edge(source, node, 1, randi_range(10, 20))
		
		if not self.grafo.has_edge(node, sink):
			self.grafo.add_edge(node, sink, 1, randi_range(10,20))
