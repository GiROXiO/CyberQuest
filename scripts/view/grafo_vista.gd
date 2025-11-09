extends Node2D
class_name GrafoVista

var grafo: Grafo

var vertice_scene: PackedScene = preload("res://scenes/grafo/verticeVista.tscn")

func _ready() -> void:
	grafo = Grafo.new()
	grafo.generate_random(1)
	self._draw_vertices()

func _draw_vertices() -> void:
	for child in get_children():
		child.queue_free()
	
	if grafo == null:
		return
	
	var ids: Array = grafo.get_vertices_ids()
	if ids.is_empty():
		return
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = viewport_size * 0.5

	# Como solo hay 1 vértice, simplemente lo ponemos en el centro
	var id: int = ids[0]
	var vnode := vertice_scene.instantiate() as VerticeVista
	vnode.position = center
	add_child(vnode)
