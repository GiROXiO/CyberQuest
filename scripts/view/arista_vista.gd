extends Node2D
class_name AristaVista

var edge: Arista = null
var from_pos: Vector2
var to_pos: Vector2


const LINE_WIDTH := 2.0
const ARROW_SIZE := 10.0
const VERTEX_RADIUS := 18.0

@onready var info_label: Label = $Info

enum MinigameMode {
	BFS_DFS,
	CAMINOS_MINIMOS,
	ARBOL_EXPANSION_MINIMA,
	FLUJO_MAXIMO
}

var flow_active: bool = false
var flow_phase: float = 0.0

var game_manager : Node2D;
var current_mode: MinigameMode = MinigameMode.BFS_DFS

func _ready() -> void:
	game_manager = get_node("/root/GameManager")
	game_manager.mode_changed.connect(_on_mode_changed)

func _on_mode_changed(new_mode):
	if current_mode != new_mode:
		print("Modo actual cambiado a: ", new_mode)
		current_mode = new_mode
		queue_redraw()

func setup(p_edge: Arista, p_from_pos: Vector2, p_to_pos: Vector2) -> void:
	self.edge = p_edge
	self.from_pos = p_from_pos
	self.to_pos = p_to_pos
	
	z_index = 0
	
	if self.info_label:
		self.info_label.visible = false
		self.info_label.position = (from_pos + to_pos) * 0.5
		
		self.info_label.add_theme_color_override("font_color", Color(0, 0, 0))
		
		self.info_label.z_index = 100
		self.info_label.z_as_relative = false
	
	queue_redraw()

func set_minigame_mode(mode: int) -> void:
	if not self.info_label or self.edge == null:
		return
	
	match mode:
		self.MinigameMode.BFS_DFS:
			self.info_label.visible = false
		
		self.MinigameMode.CAMINOS_MINIMOS, self.MinigameMode.ARBOL_EXPANSION_MINIMA:
			self.info_label.visible = true
			self.info_label.text = "w=%d" % self.edge.weight
		
		self.MinigameMode.FLUJO_MAXIMO:
			self.info_label.visible = true
			self.info_label.text = "c=%d" % edge.capacity
		
		_:
			self.info_label.visible = false

func set_info_visible(visible: bool) -> void:
	if self.info_label:
		self.info_label.visible = visible

func set_flow_active(active: bool) -> void:
	self.flow_active = active
	if not active:
		flow_phase = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if self.flow_active:
		self.flow_phase = fmod(self.flow_phase + delta * 2.0, 1.0)
		queue_redraw()

func _draw() -> void:
	if self.edge == null:
		return
	
	var dir: Vector2 = self.to_pos - self.from_pos
	var length := dir.length()
	if length <= 0.0:
		return
	
	var n: Vector2 = dir / length
	
	#Punto de inicio
	var start := self.from_pos + n * VERTEX_RADIUS
	
	#Punta de la flecha
	var arrow_tip := to_pos - n * VERTEX_RADIUS
	
	#Final de la linea, antes del inicio de la punta de flecha
	var end := arrow_tip - n * ARROW_SIZE
	
	#Colores
	var base_color := Color(0.0, 0.8, 1.0)
	var glow_color := Color(0.5, 1.0, 1.0)
	
	var segments := 24
	for i in range(segments):
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var p0 := start.lerp(end, t0)
		var p1 := start.lerp(end, t1)

		var col := base_color
		if flow_active:
			var mid_t := (t0 + t1) * 0.5
			# onda que se desplaza a lo largo de la arista
			var wave := 0.5 + 0.5 * sin((mid_t * 4.0 - flow_phase) * TAU)
			col = base_color.lerp(glow_color, wave)

		draw_line(p0, p1, col, LINE_WIDTH, true)
	
	#Dibujamos flecha
	if current_mode != 2:
		var perp := Vector2(-n.y, n.x)
		var p1 := arrow_tip
		var p2 := end + perp * (ARROW_SIZE * 0.5)
		var p3 := end - perp * (ARROW_SIZE * 0.5)
		draw_polygon([p1, p2, p3], [glow_color])
