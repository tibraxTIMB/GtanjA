import json, pathlib, math, struct
root=pathlib.Path(__file__).resolve().parents[1]/"data"
m=json.loads((root/"hardanger.json").read_text())
t=json.loads((root/"terrain.json").read_text())
b=json.loads((root/"sandvenhagen-local.json").read_text())
for data in (m,t,b):
    assert data["crs"]=="EPSG:25832"
    assert math.dist(data["origin"],t["origin"])<0.01
assert m["roads"] and b["features"]
w,h=t["width"],t["height"]
raw=(root/"terrain.f32").read_bytes()
assert len(raw)==4*w*h
assert all(math.isfinite(v[0]) for v in struct.iter_unpack("<f",raw))
x,z=b["address_point"]
assert t["x0"]<=x<=t["x0"]+(w-1)*t["step"]
assert t["z0"]<=z<=t["z0"]+(h-1)*t["step"]
print("Geographic data validation passed; not a runtime test")
