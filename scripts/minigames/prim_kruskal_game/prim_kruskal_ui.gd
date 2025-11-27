extends Control
class_name PrimKruskalUi

signal minigame_completed(success: bool)

@onready var grafo_vista: GrafoVista
@onready var grafo: Grafo
@onready var infoLabel : Label = $infoLabel


var vertices: Dictionary[int, Vertice] = {}
var aristas_resultado : Array[Array] = []
var aristas_texto = "";
var mst_edges: Array = []



func _ready():
	grafo_vista = get_tree().get_root().find_child("GrafoVista", true, false)
	await get_tree().process_frame  # Espera un frame
	if grafo_vista and grafo_vista.grafo:
		grafo = grafo_vista.grafo
		grafo.is_directed = false
		mst_edges = grafo.kruskal().duplicate()
		for id in grafo.vertices.keys():
			var vertice = grafo.vertices[id]
			#print("id:", id)
	
func set_graph(p_grafo: Grafo) -> void:
	grafo = p_grafo

func set_graph_view(p_view: GrafoVista) -> void:
	grafo_vista = p_view

func comparar_arrays(aristas_resultado: Array, aristas_usuario: Array) -> bool:
	if aristas_resultado.size() != aristas_usuario.size():
		return false

	var res_sorted = []
	var usr_sorted = []

	for a in aristas_resultado:
		var copia = a.duplicate()
		copia.sort()
		res_sorted.append(copia)

	for a in aristas_usuario:
		var copia = a.duplicate()
		copia.sort()
		usr_sorted.append(copia)

	res_sorted.sort()
	usr_sorted.sort()

	return res_sorted == usr_sorted

func comparar_arrays_exacto(aristas_resultado: Array, aristas_usuario: Array) -> bool:
	return aristas_resultado == aristas_usuario

func quitar_espacios_str(texto : String) -> String:
	var new_text = ""
	
	for i in range(texto.length()):
		if texto[i] != " ":
			new_text += texto[i]
	
	return new_text


func aplanar_array(arr: Array) -> Array:
	var resultado = []
	for sub in arr:
		resultado += sub  
	return resultado


func verify_text(text: String):
	var regex = RegEx.new()
	regex.compile(r"^(\d+-\d+)(,\d+-\d+)*$") 
	return regex.search(text) != null	


func _on_verify_pressed() -> void:
	if aristas_texto.length() <= 0:
		infoLabel.text = "Rellene el campo con el formato establecido (Ej: 1-2, 3-4, 1-3)"
		return;
	
	if !verify_text(aristas_texto):
		infoLabel.text = "Se debe seguir el formato establecido (Ej: 1-2, 3-4, 1-3)"
		return;
	
	var arr = self.aristas_texto.split(",")
	var result = []
	var highlighted_edges : Array[Array] = []
	
	for parte in arr:
		result.append(parte.split("-"))
		
	for x in result:
		highlighted_edges.append( [ int(x[0]), int(x[1]) ] )
	
	if Dialogic.VAR.PRIM_KRUSKAL:
		var result_prim = grafo.prim(0)
		
		if comparar_arrays(result_prim, highlighted_edges):
			self.minigame_completed.emit(true)
		else:
			pass
			#print(result_prim)
		
	else:
		var result_kruskal = grafo.kruskal()
		
		if comparar_arrays(result_kruskal, highlighted_edges):
			self.minigame_completed.emit(true)
		else:
			pass
			#print(result_kruskal)

func _on_line_edit_text_changed(new_text: String) -> void:
	self.aristas_texto = quitar_espacios_str(new_text)




func _on_show_path_pressed() -> void:
	if aristas_texto.length() <= 0:
		infoLabel.text = "Rellene el campo con el formato establecido (Ej: 1-2, 3-4, 1-3)"
		return

	if !verify_text(aristas_texto):
		infoLabel.text = "Se debe seguir el formato establecido (Ej: 1-2, 3-4, 1-3)"
		return

	var arr = aristas_texto.split(",")
	var edges = []  
	
	for parte in arr:
		var p = parte.split("-")
		edges.append([int(p[0]), int(p[1])])


	self.grafo_vista.set_path_edges_mod2(edges)


func edges_to_path(edges) -> Array[int]:
	if edges.is_empty():
		return []

	var path: Array[int] = []
	path.append(edges[0][0])

	for e in edges:
		path.append(e[1])

	return path

func get_mst_edges() -> Array:
	return mst_edges.duplicate()
