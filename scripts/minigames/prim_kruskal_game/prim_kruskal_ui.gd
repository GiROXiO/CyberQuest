extends Control
class_name PrimKruskalUi

@onready var grafo_vista: GrafoVista
var vertices: Dictionary[int, Vertice] = {}
var aristas_resultado : Array[Array] = []

func _ready():
	grafo_vista = get_tree().get_root().find_child("GrafoVista", true, false)
	await get_tree().process_frame  # Espera un frame
	if grafo_vista and grafo_vista.grafo:
		var grafo = grafo_vista.grafo
		print("SI SIRVIO:", grafo)
		for id in grafo.vertices.keys():
			var vertice = grafo.vertices[id]
			print("id:", id)
	else:
		print("no sirvio xd")
	
	for i in range(9):
		print("Con ID: ", i)
		var prueba = prim(i)
		print(prueba)
		print(prueba.size())
		

func prim(inicio_id: int) -> Array:
	var grafo = grafo_vista.grafo
	if not grafo.vertices.has(inicio_id):
		push_error("El vértice inicial no existe en el grafo.")
		return []

	var visitados: Array = [inicio_id]
	var aristas_resultado: Array = []
	var aristas_resultado_arr: Array[Array] = []

	while visitados.size() < grafo.vertices.size():
		var menor_peso: float = INF
		var mejor_arista: Arista = null
		
		for v_id in visitados:
			for destino_id in grafo.vertices[v_id].neighbors:
				if destino_id in visitados:
					continue
				var arista_obj = grafo.edges[v_id][destino_id]
				if arista_obj.weight < menor_peso:
					menor_peso = arista_obj.weight
					mejor_arista = arista_obj

			for origen_id in grafo.vertices.keys():
				if v_id in grafo.vertices[origen_id].neighbors and origen_id not in visitados:
					var arista_obj = grafo.edges[origen_id][v_id]
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


func comparar_arrays(aristas_resultado : Array[Array], aristas_usuario : Array[Array]):
	if aristas_resultado.size() != aristas_usuario.size():
		return false
	
	var comprobar = false;
		
	for i in range(aristas_resultado.size()):
		for j in range(aristas_resultado.size()):
			if aristas_usuario[i] == aristas_resultado[j]:
				comprobar = true
		if !comprobar:
			return false
	
	return true;


func _on_verify_pressed() -> void:
	var aristas_conectadas = grafo_vista.highlighted_edges
	
	if aristas_conectadas.size() == 0:
		print("No se ha conectado nada")
	else:
		var comprobar = comparar_arrays(prim(aristas_conectadas[0][0]), aristas_conectadas);
		print(comprobar) 
