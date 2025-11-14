extends Control
class_name CaminoMinimoUi

signal minigame_completed(success: bool)

@onready var title_label: Label = $Label
@onready var check_button: Button = $CheckButton
@onready var info_label: Label = $InfoLabel

var grafo: Grafo = null
var grafo_vista: GrafoVista = null

var source_id: int = -1
var target_id: int = -1
var shortest_path: Array[int] = []
var user_path: Array[int] = []

func _ready() -> void:
	if self.title_label:
		self.title_label.text = "Caminos Minimos con Dijkstra"
	
	if self.check_button:
		self.check_button.text = "Verificar Camino"
		self.check_button.pressed.connect(self._on_check_button_pressed)
	
	self._clear_message()

func set_graph(p_grafo: Grafo) -> void:
	self.grafo = p_grafo

func set_graph_view(p_view: GrafoVista) -> void:
	self.grafo_vista = p_view

func start_minigame() -> void:
	if self.grafo == null:
		print("[ShortestPathUi] Error: No hay grafo asignado")
		return
	
	self.source_id = self.grafo.get_control_id()
	self.target_id = self.grafo.get_infected_id()
	
	print("[ShortestPathUi] source_id=", source_id, " target_id=", target_id)
	
	if self.source_id == -1 or self.target_id == -1:
		print("[ShortestPathUi] No se pudo determinar source o target.")
		return
	
	self.shortest_path = self.grafo.dijkstra(self.source_id, self.target_id)
	print("[ShortestPathUi] shortest_path calculado: ", shortest_path)
	
	self.user_path.clear()
	
	if shortest_path.is_empty():
		print("[ShortestPathUi] No hay camino desde el Centro de Control hasta el infectado.")
	else:
		self._set_message("!Halla el camino minimo con Dijkstra¡")

func on_vertex_clicked_from_graph(vertex_id: int, is_selected: bool) -> void:
	if self.grafo == null:
		return
	if self.shortest_path.is_empty():
		return
	
	self._clear_message()
	
	print("[ShortestPathUi] Clic en vértice desde grafo: ", vertex_id, " is_selected=", is_selected)
	
	if is_selected:
		#Se agrega al camino
		if self.user_path.is_empty():
			#Solo se permite iniciar desde el centro de control
			if vertex_id != self.source_id:
				print("[ShortestPathUi] Debes iniciar en el Centro de Control (id: ", source_id, ").")
				self._set_message("Debes iniciar en el Centro de Control")
				return
			self.user_path.append(vertex_id)
			if self.grafo_vista != null:
				self.grafo_vista.set_path_edges(self.user_path)
		else:
			var last_id: int = self.user_path[user_path.size() - 1]
			
			#Solo se acepta el vertice si es vecino del ultimo vertice seleccionado
			if not self.grafo.has_edge(last_id, vertex_id):
				print("[ShortestPathUi] El vértice ", vertex_id, " no es vecino de ", last_id, ". Ignorando.")
				self._set_message("El vertice no es vecino del ultimo elegido")
				return
			
			#Se evita duplicar el ultimo vertice ingresado
			if vertex_id == last_id:
				print("[ShortestPathUi] El vértice ", vertex_id, " ya se selecciono .Ignorando.")
				return
			
			self.user_path.append(vertex_id)
			if self.grafo_vista != null:
				self.grafo_vista.set_path_edges(self.user_path)
	else:
		#Deseleccionamos el vertice
		if self.user_path.is_empty():
			return
		
		var idx := self.user_path.find(vertex_id)
		if idx == -1:
			return
		
		var to_clear: Array[int] = []
		for i in range(idx + 1, self.user_path.size()):
			to_clear.append(user_path[i])
		
		#Borramos desde el vertice hasta el final del camino
		while self.user_path.size() > idx:
			self.user_path.pop_back()
		
		if self.grafo_vista != null:
			for id in to_clear:
				self.grafo_vista.force_set_vertex_selected(id, false)
				self.grafo_vista.set_path_edges(self.user_path)
	
	print("[ShortestPathUi] user_path actual: ", user_path)

func _on_check_button_pressed() -> void:
	if self.grafo == null:
		return
	if self.shortest_path.is_empty():
		print("[ShortestPathUi] No hay shortest_path para comparar.")
		self._set_message("No hay camino minimo para comparar")
		return
	if user_path.is_empty():
		print("[ShortestPathUi] user_path está vacío.")
		self._set_message("Primero selecciona un camino")
		return
	
	if self.user_path[0] != self.source_id:
		print("[ShortestPathUi] El camino del usuario no inicia en el Centro de Control.")
		self._set_message("Tu camino no inicia en el centro de control")
		return
	
	if self.user_path[self.user_path.size() - 1] != self.target_id:
		print("[ShortestPathUi] El camino del usuario no llega al infectado.")
		self._set_message("Tu camino no llega al nodo infectado")
		return
	
	var ok := self.user_path.size() == self.shortest_path.size()
	if ok:
		for i in range(self.user_path.size()):
			if self.user_path[i] != self.shortest_path[i]:
				ok = false
				break
	
	if ok:
		print("[ShortestPathUi] ¡Camino correcto! Es el camino mínimo.")
		self._set_message("¡Correcto! Has encontrado el camino mínimo")
		self.minigame_completed.emit(true)
	else:
		print("[ShortestPathUi] Camino incorrecto. user_path=", user_path, " shortest_path=", shortest_path)
		self._set_message("Camino incorrecto. Inténtalo de nuevo")

func _set_message(text: String) -> void:
	if self.info_label:
		self.info_label.visible = true
		self.info_label.text = text

func _clear_message() -> void:
	if self.info_label:
		self.info_label.text = ""
		self.info_label.visible = false
