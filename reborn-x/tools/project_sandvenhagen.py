"""Project imported GeoJSON using open-source PROJ (pyproj)."""
import json
from pathlib import Path
from pyproj import Transformer
root=Path(__file__).resolve().parents[1]
data=json.loads((root/"data/sandvenhagen.geojson").read_text())
project=Transformer.from_crs(4326,25832,always_xy=True)
origin=project.transform(6.18,60.3775)
def local(p):
    x,y=project.transform(*p)
    return [round(x-origin[0],3),round(origin[1]-y,3)]
features=[]
for f in data["features"]:
    g=f["geometry"]
    coords=g["coordinates"]
    features.append({"type":g["type"],"coordinates":[[local(p) for p in ring] for ring in coords] if g["type"]=="Polygon" else [local(p) for p in coords],"properties":f["properties"]})
out={"crs":"EPSG:25832","origin":list(origin),"axis":"east,south","address_point":local(data["address_point"]),"features":features,"attribution":data["attribution"]}
(root/"data/sandvenhagen-local.json").write_text(json.dumps(out,ensure_ascii=False))
