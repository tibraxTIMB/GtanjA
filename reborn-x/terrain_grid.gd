extends Node3D
var heights := PackedFloat32Array()
var w := 0
var d := 0
var step_m := 10.0
var x0 := 0.0
var z0 := 0.0

func load_grid() -> bool:
	if not FileAccess.file_exists("res://data/terrain.json") or not FileAccess.file_exists("res://data/terrain.f32"):
		return false
	var meta = JSON.parse_string(FileAccess.get_file_as_string("res://data/terrain.json"))
	if not meta is Dictionary:
		return false
	w = int(meta.get("width",0))
	d = int(meta.get("height",0))
	step_m = float(meta.get("step",0))
	x0 = float(meta.get("x0",0))
	z0 = float(meta.get("z0",0))
	if w<2 or d<2 or w*d>1000000 or step_m<=0:
		return false
	heights = FileAccess.get_file_as_bytes("res://data/terrain.f32").to_float32_array()
	if heights.size()!=w*d:
		return false
	for h in heights:
		if not is_finite(h):
			return false
	return true

func build() -> void:
	# Tiles share their edge samples; identical triangles for visuals and physics.
	for z in range(0,d-1,64):
		for x in range(0,w-1,64):
			build_tile(x,z,mini(x+64,w-1),mini(z+64,d-1))

func vertex(x:int,z:int) -> Vector3:
	return Vector3(x0+x*step_m,heights[z*w+x],z0+z*step_m)

func build_tile(ax:int,az:int,bx:int,bz:int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(az,bz):
		for x in range(ax,bx):
			for v in [vertex(x,z),vertex(x+1,z),vertex(x,z+1),vertex(x+1,z),vertex(x+1,z+1),vertex(x,z+1)]:
				st.add_vertex(v)
	st.generate_normals()
	st.index()
	var mesh := st.commit()
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32,0.43,0.25)
	visual.material_override = mat
	add_child(visual)
	visual.create_trimesh_collision()

func height_at(x:float,z:float) -> float:
	var gx := (x-x0)/step_m
	var gz := (z-z0)/step_m
	if gx<0 or gz<0 or gx>w-1 or gz>d-1 or heights.size()!=w*d:
		return NAN
	var ix := mini(int(gx),w-2)
	var iz := mini(int(gz),d-2)
	var u := gx-ix
	var v := gz-iz
	var a := heights[iz*w+ix]
	var b := heights[iz*w+ix+1]
	var c := heights[(iz+1)*w+ix]
	var e := heights[(iz+1)*w+ix+1]
	if u+v<=1:
		return a+(b-a)*u+(c-a)*v
	return e+(c-e)*(1-u)+(b-e)*(1-v)
