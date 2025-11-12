extends Area2D
class_name VerticeVista

signal vertex_clicked(vertex_id: int)

@export var show_hint: bool = true

@onready var info_card: Node2D = $InfoCard
@onready var info_label: Label = $InfoCard/ColorRect/Label
@onready var info_icon: TextureRect = $InfoCard/ColorRect/Icon
@onready var hint_label: Label = $InfoCard/ColorRect/HintLabel
@onready var id_label: Label = $IdLabel

@onready var info_bg: ColorRect = $InfoCard/ColorRect

enum MinigameMode {
	BFS_DFS,
	CAMINOS_MINIMOS,
	ARBOL_EXPANSION_MINIMA,
	FLUJO_MAXIMO
}

var vertex: Vertice = null

var radius: float = 18.0
var aura_radius: float = 26.0
var aura_time: float = 0.0
var selected: bool = false

var is_dragging_card: bool= false
var drag_offset_card: Vector2 = Vector2.ZERO

var debug_last_inside: bool = false

func setup(p_vertex: Vertice, p_position: Vector2) -> void:
	self.vertex = p_vertex
	self.position = p_position
	self.selected = false
	self.aura_time = 0.0
	
	if self.info_label != null and self.vertex != null:
		self.info_label.text = self._get_role_name(self.vertex.role)
	
	if self.info_icon != null and self.vertex != null:
		self.info_icon.texture = self._get_role_icon(self.vertex.role)
	
	if self.hint_label != null and self.vertex != null:
		if self.vertex.hint != "":
			self.hint_label.text = self.vertex.hint
		else:
			self.hint_label.text = "No hay nada por aca"
	
	if self.id_label and self.vertex != null:
		self.id_label.text = str(self.vertex.id)
	
	if self.info_card != null:
		self.info_card.visible = false
	
	print("VerticeVista creado para id=", vertex.id, " rol=", vertex.role)
	queue_redraw()

func _ready() -> void:
	# ajustar colisión al radio
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D.shape
		if shape is CircleShape2D:
			(shape as CircleShape2D).radius = radius
	
	z_index = 1
	
	set_process_input(true)
	
	if self.info_card:
		self.info_card.z_index = 90
		self.info_card.z_as_relative = false
	
	set_process(true)

func _process(delta: float) -> void:
	if selected:
		aura_time += delta
	else:
		aura_time = 0.0
	
	# DEBUG: ver si el mouse está dentro de la tarjeta en cada frame
	if info_card and info_card.visible and info_bg:
		var mouse_pos := get_viewport().get_mouse_position()
		var inside := _is_point_in_card(mouse_pos)
		if inside != debug_last_inside:
			debug_last_inside = inside
	
	if self.is_dragging_card and self.info_card:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		self.info_card.global_position = mouse_pos + drag_offset_card
		queue_redraw()
	
	queue_redraw()

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected = not selected
		
		if self.info_card != null:
			self.info_card.visible = selected
		
		if vertex != null:
			# DEBUG: mostrar toda la info del vértice en consola
			#print("--- VÉRTICE CLICKEADO ---")
			#print("ID: ", vertex.id)
			#print("Rol: ", _get_role_name(vertex.role), " (", vertex.role, ")")
			#print("Infectado: ", vertex.is_infected)
			#print("Es nodo con pista (is_key_vertex): ", vertex.is_key_vertex)
			#print("Pista (hint): ", vertex.hint if vertex.hint != "" else "No hay nada que ver por aca")
			#print("Vecinos (neighbors): ", vertex.get_neighbors())
			#print("-------------------------")
			emit_signal("vertex_clicked", vertex.id)
		else:
			emit_signal("vertex_clicked", -1)
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not self.info_card or not self.info_bg:
		return
	if not self.info_card.visible:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		
		var inside := self._is_point_in_card(mouse_pos)
		
		if event.pressed:
			if inside:
				is_dragging_card = true
				self.drag_offset_card = self.info_card.global_position - mouse_pos
		else:
			self.is_dragging_card = false

func _is_point_in_card(screen_pos: Vector2) -> bool:
	if not self.info_bg:
		return false
	
	var rect := self.info_bg.get_global_rect()
	var inside := rect.has_point(screen_pos)
	return inside

func _draw() -> void:
	var base_color = Color(0.2, 0.8, 0.4)
	var outline_color = Color(0.1, 0.4, 0.2)
	
	if vertex != null:
		# Centro de Control → azul
		if vertex.role == Vertice.VertexRole.CENTRO_CONTROL:
			base_color = Color(0.2, 0.4, 1.0)
			outline_color = Color(0.1, 0.2, 0.6)
	
	if selected:
		# aura
		var pulse = 0.5 + 0.5 * sin(aura_time * 4.0)
		var current_radius = lerp(aura_radius, aura_radius + 6.0, pulse)
		draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.9, 0.4, 0.3))

	# círculo
	draw_circle(Vector2.ZERO, radius + 2.0, outline_color)
	draw_circle(Vector2.ZERO, radius, base_color)
	
	self._draw_connection_line()

func _draw_connection_line() -> void:
	if not self.info_card or not self.info_card.visible or not self.info_bg:
		return
	
	#Se obtiene la posicion global del vertice
	var vertex_global: Vector2 = global_position
	
	#Rect global de la tarjeta
	var rect: Rect2 = self.info_bg.get_global_rect()
	var rect_min := rect.position
	var rect_max := rect.position + rect.size
	var card_center: Vector2 = rect.get_center()
	
	#Verificamos en que posicion esta la tarjeta con respecto al vertice
	var delta: Vector2 = card_center - vertex_global
	
	var origin_local: Vector2
	
	if abs(delta.x) > abs(delta.y):
		if delta.x >= 0.0:
			#Tarjeta a la derecha = origen en el lado derecho
			origin_local = Vector2(self.radius, 0.0)
		else:
			#Tarjeta a la izquierda = origen en el lado izquierdo
			origin_local = Vector2(-self.radius, 0.0)
	else:
		if delta.y >= 0.0:
			#Trajeta abajo = origen en el lado inferior
			origin_local = Vector2(0.0, self.radius)
		else:
			#Trajeta arriba = origen en el lado superior
			origin_local = Vector2(0.0, -self.radius)
	
	#Punto de la tarjeta mas cercano al vertice
	var target_global := Vector2(
		clampf(vertex_global.x, rect_min.x, rect_max.x),
		clampf(vertex_global.y, rect_min.y, rect_max.y)
	)
	
	var target_local: Vector2 = to_local(target_global)
	
	draw_line(origin_local, target_local, Color(0.356, 0.371, 0.386), 2.0)

func _get_role_name(role: int) -> String:
	match role:
		Vertice.VertexRole.CENTRO_CONTROL:
			return "Centro de Control"
		Vertice.VertexRole.ROUTER_CORE:
			return "Router Core"
		Vertice.VertexRole.ROUTER_BORDE:
			return "Router de Borde"
		Vertice.VertexRole.FIREWALL:
			return "Firewall"
		Vertice.VertexRole.SERVIDOR_APP:
			return "Servidor de Aplicaciones"
		Vertice.VertexRole.SERVIDOR_DB:
			return "Servidor de Base de Datos"
		Vertice.VertexRole.SERVIDOR_MAIL:
			return "Servidor de Correo"
		Vertice.VertexRole.GATEWAY_VPN:
			return "Gateway VPN"
		Vertice.VertexRole.IDS:
			return "Sistema IDS"
		Vertice.VertexRole.CLIENTE:
			return "Cliente Final"
		_:
			return "Nodo"

func _get_role_icon(role: int) -> Texture2D:
	match role:
		Vertice.VertexRole.CENTRO_CONTROL:
			return preload("res://art/icons/centroControl.png")
		Vertice.VertexRole.ROUTER_CORE:
			return preload("res://art/icons/routerCore.png")
		Vertice.VertexRole.ROUTER_BORDE:
			return preload("res://art/icons/routerBorde.png")
		Vertice.VertexRole.FIREWALL:
			return preload("res://art/icons/firewall.png")
		Vertice.VertexRole.SERVIDOR_APP:
			return preload("res://art/icons/servidorApp.png")
		Vertice.VertexRole.SERVIDOR_DB:
			return preload("res://art/icons/servidorDB.png")
		Vertice.VertexRole.SERVIDOR_MAIL:
			return preload("res://art/icons/servidorMail.png")
		Vertice.VertexRole.GATEWAY_VPN:
			return preload("res://art/icons/vpnGateway.png")
		Vertice.VertexRole.IDS:
			return preload("res://art/icons/ids.png")
		Vertice.VertexRole.CLIENTE:
			return preload("res://art/icons/cliente.png")
		_:
			return null

func set_minigame_mode(mode: int, bfs_dfs_completed: bool) -> void:
	if not self.hint_label:
		return
	
	match mode:
		self.MinigameMode.BFS_DFS:
			if self.show_hint and not bfs_dfs_completed:
				self.hint_label.visible = true
			else:
				self.hint_label.visible = false
		
		_:
			self.hint_label.visible = false

func set_color(color: Color) -> void:
	modulate = color

func set_selected_state(p_selected: bool) -> void:
	self.selected = p_selected
	
	if self.info_card:
		self.info_card.visible = selected
	
	if not self.selected:
		self.aura_time = 0.0
	
	queue_redraw()
