"""Fetch OSM road/building geometry and project to local metres. Uses open-source PROJ."""
import json, math, pathlib, urllib.request, urllib.parse
from pyproj import Transformer
ROOT = pathlib.Path(__file__).resolve().parents[1]
BBOX = "60.350,6.125,60.405,6.235"
LAT, LON = 60.3775, 6.18
query = f'[out:json][timeout:90];(way["highway"]({BBOX});way["building"]({BBOX});way["natural"~"coastline|water|wood"]({BBOX});way["landuse"~"forest|farmland|meadow|grass"]({BBOX}););out geom;'
transformer = Transformer.from_crs(4326,25832,always_xy=True)
E,N = transformer.transform(LON,LAT)
def project(p):
    e,n=transformer.transform(p['lon'],p['lat'])
    return [round(e-E,2),round(N-n,2)]
def main():
    errors = []
    for endpoint in ("https://overpass-api.de/api/interpreter","https://overpass.kumi.systems/api/interpreter"):
        try:
            req = urllib.request.Request(endpoint, data=urllib.parse.urlencode({"data":query}).encode(), headers={"User-Agent":"GTanjA-REBORN-X map importer"})
            with urllib.request.urlopen(req, timeout=120) as response:
                data = json.load(response)
            roads, buildings, landscape = [], [], []
            for e in data.get("elements",[]):
                tags=e.get("tags",{})
                points=[project(p) for p in e.get("geometry",[])]
                if len(points)<2: continue
                if "highway" in tags and tags["highway"] not in ("footway","path","steps","cycleway","bridleway","pedestrian"):
                    roads.append({"id":e["id"],"kind":tags["highway"],"points":points})
                elif "building" in tags and len(points)>=4:
                    buildings.append({"id":e["id"],"points":points})
                elif "natural" in tags or "landuse" in tags:
                    landscape.append({"id":e["id"],"kind":tags.get("natural",tags.get("landuse")),"points":points})
            if not roads: raise ValueError("No road geometry returned")
            out=ROOT/"data"/"hardanger.json"
            out.parent.mkdir(exist_ok=True)
            out.write_text(json.dumps({"source":"OpenStreetMap contributors, ODbL","crs":"EPSG:25832","origin":[E,N],"axis":"east,south","roads":roads,"buildings":buildings,"landscape":landscape},separators=(",",":")))
            print(f"{len(roads)} roads, {len(buildings)} buildings")
            return
        except Exception as exc: errors.append(str(exc))
    raise RuntimeError("; ".join(errors))
if __name__=="__main__": main()
