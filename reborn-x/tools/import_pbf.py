"""Convert a locally clipped OSM PBF into REBORN X geometry."""
import argparse, json, pathlib
import osmium
from pyproj import Transformer
p=argparse.ArgumentParser()
p.add_argument("pbf")
args=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
transform=Transformer.from_crs(4326,25832,always_xy=True)
e0,n0=transform.transform(6.18,60.3775)
class Importer(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.roads=[]; self.buildings=[]; self.landscape=[]
    def way(self,w):
        tags=dict(w.tags)
        kind=tags.get("highway")
        nature=tags.get("natural",tags.get("landuse"))
        if not (kind or "building" in tags or nature): return
        if not all(n.location.valid() for n in w.nodes): return
        points=[]
        for n in w.nodes:
            e,north=transform.transform(n.lon,n.lat)
            points.append([round(e-e0,2),round(n0-north,2)])
        if len(points)<2: return
        item={"id":w.id,"points":points}
        if kind and kind not in ("footway","path","steps","cycleway","bridleway","pedestrian"):
            self.roads.append(dict(item,kind=kind))
        elif "building" in tags and len(points)>=4 and points[0]==points[-1]:
            self.buildings.append(item)
        elif nature in ("coastline","water","wood","forest","farmland","meadow","grass"):
            self.landscape.append(dict(item,kind=nature))
h=Importer()
h.apply_file(args.pbf,locations=True)
if not h.roads: raise RuntimeError("No roads in extract")
out=root/"data"/"hardanger.json"
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(dict(source="OpenStreetMap contributors, ODbL; Geofabrik extract",crs="EPSG:25832",origin=[e0,n0],axis="east,south",roads=h.roads,buildings=h.buildings,landscape=h.landscape),separators=(",",":")))
print(len(h.roads),len(h.buildings),len(h.landscape))
