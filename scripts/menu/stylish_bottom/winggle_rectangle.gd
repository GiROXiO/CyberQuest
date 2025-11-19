extends Polygon2D

var origin_polygons: PackedVector2Array

@export var intensity: float = 1.0
@export var duration: float = 1.0
var curtime: float
var prepos
var frompos
var target_offset: Array[Vector2]

func _ready() -> void:
	origin_polygons = polygon
	
	prepos = origin_polygons
	frompos = prepos
	target_offset = add_vector2array_offset(prepos, random_vector2array_offset(intensity))
	pass

func _physics_process(delta: float) -> void:
	curtime += delta
	if curtime >= duration:
		frompos = target_offset
		target_offset = add_vector2array_offset(prepos, random_vector2array_offset(intensity))
		curtime = 0
	
	for i in range(polygon.size()):
		var tar = prepos[i] + target_offset[i]
		var t = curtime/duration
		polygon[i] = lerp(frompos[i],target_offset[i],t)  
	
	pass
	
func add_vector2array_offset(base: Array[Vector2], add: Array[Vector2]) -> Array[Vector2]:
	var ret: Array[Vector2]
	
	for i in base.size():
		ret.insert(i, (base[i] + add[i]))
	
	return ret

func random_vector2array_offset(max : float) -> Array[Vector2]:
	var arrVector2: Array[Vector2]
	
	for i in origin_polygons.size():
		arrVector2.insert(i, random_offset(max))
		pass
		
	return arrVector2

func random_offset(max : float) -> Vector2:
	return Vector2(randf_range(-max,max),randf_range(-max,max))
