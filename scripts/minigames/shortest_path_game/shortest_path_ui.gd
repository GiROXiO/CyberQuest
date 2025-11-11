extends Control
class_name CaminoMinimoUi

@onready var info_label: Label = $Label

var grafo: Grafo = null

func _ready() -> void:
	if self.info_label:
		self.info_label.text = "Caminos Minimos con Dijkstra"

func set_graph(p_grafo: Grafo) -> void:
	self.grafo = p_grafo
