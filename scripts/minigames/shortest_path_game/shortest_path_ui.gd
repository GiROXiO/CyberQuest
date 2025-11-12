extends Control
class_name CaminoMinimoUi

signal minigame_completed(success: bool)

@onready var info_label: Label = $Label
@onready var check_button: Button = $CheckButton

var grafo: Grafo = null
var grafo_vista: GrafoVista = null

var source_id: int = -1
var target_id: int = -1
var shortest_path: Array = []
var user_path: Array = []

func _ready() -> void:
	if self.info_label:
		self.info_label.text = "Caminos Minimos con Dijkstra"
	if self.check_button:
		self.check_button.text = "Verificar Camino"
		#self.check_button.pressed.connect(self._on_check_button_pressed)

func set_graph(p_grafo: Grafo) -> void:
	self.grafo = p_grafo

func set_graph_view(p_view: GrafoVista) -> void:
	self.grafo_vista = p_view

func start_minigame() -> void:
	if self.grafo == null:
		return
	
	self.source_id = self.grafo.get_control_id()
	self.target_id = self.grafo.get_infected_id()
	
	print("[ShortestPathUi] source_id=", source_id, " target_id=", target_id)
	
	if self.source_id == -1 or self.target_id == -1:
		print("[ShortestPathUi] No se pudo determinar source o target.")
		return
	
	self.shortest_path = self.grafo.dijkstra(self.source_id, self.target_id)
	print("[ShortestPathUi] shortest_path calculado: ", shortest_path)
	
	if shortest_path.is_empty():
		print("[ShortestPathUi] No hay camino desde el Centro de Control hasta el infectado.")
	else:
		if info_label:
			info_label.text = "Encuentra el camino mínimo desde el Centro de Control hasta el nodo infectado."

func on_vertex_clicked_from_graph(vertex_id: int) -> void:
	print("[ShortestPathUi] Clic en vértice desde grafo: ", vertex_id)
	user_path.append(vertex_id)
	print("[ShortestPathUi] user_path actual: ", user_path)

func _on_check_button_pressed() -> void:
	print("[ShortestPathUi] (temp) Verificar camino. user_path = ", user_path, " shortest_path = ", shortest_path)
