"""Fetch official address point and nearby OSM geometry, without invented fallback."""
import json, math, pathlib, urllib.request, urllib.parse, sys
import osmium
from pyproj import Transformer
def fetch(url, params):
    req = urllib.request.Request(url+"?"+urllib.parse.urlencode(params),headers={"User-Agent":"GTanjA GIS prototype/1.0"})
    with urllib.request.urlopen(req,timeout=90) as response:
        return json.load(response)
def main():
    addresses=fetch("https://ws.geonorge.no/adresser/v1/sok",{"sok":"Gamle Dalavegen 110","kommunenummer":"4622"})
    matches=[a for a in addresses["adresser"] if a.get("nummer")==110 and a.get("adressenavn","").casefold()=="gamle dalavegen"]
    if len(matches)!=1: raise RuntimeError("Address not uniquely resolved")
    point=matches[0]["representasjonspunkt"]
    lat,lon=point["lat"],point["lon"]
    project=Transformer.from_crs(4326,25832,always_xy=True)
    e,n=project.transform(lon,lat)
    features=[]
    class LocalWays(osmium.SimpleHandler):
        def way(self,w):
            tags=dict(w.tags)
            if not ("highway" in tags or "building" in tags or tags.get("amenity")=="recycling"): return
            if any(not node.location.valid() for node in w.nodes): return
            coords=[[node.lon,node.lat] for node in w.nodes]
            if len(coords)<2: return
            if not any(math.hypot(x-e,y-n)<=350 for x,y in (project.transform(*p) for p in coords)): return
            polygon=len(coords)>=4 and coords[0]==coords[-1] and "building" in tags
            features.append({"type":"Feature","geometry":{"type":"Polygon" if polygon else "LineString","coordinates":[coords] if polygon else coords},"properties":{"osm_id":w.id,**tags}})
    LocalWays().apply_file(sys.argv[1] if len(sys.argv)>1 else "hardanger.osm.pbf",locations=True)
    if not features: raise RuntimeError("No mapped geometry returned")
    result={"type":"FeatureCollection","features":features,"address_point":[lon,lat],"attribution":"Address: Kartverket; geometry: © OpenStreetMap contributors, ODbL","surveyed":False}
    path=pathlib.Path(__file__).resolve().parents[1]/"data"/"sandvenhagen.geojson"
    path.parent.mkdir(exist_ok=True)
    path.write_text(json.dumps(result,ensure_ascii=False),encoding="utf-8")
    print(f"Wrote {len(features)} features to {path}")
if __name__=="__main__": main()
