"""Fetch official address point and nearby OSM geometry, without invented fallback."""
import json, math, pathlib, urllib.request, urllib.parse
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
    query=f'[out:json][timeout:60];(way(around:350,{lat},{lon})["highway"];way(around:350,{lat},{lon})["building"];way(around:350,{lat},{lon})["amenity"="recycling"];);out geom;'
    data=fetch("https://overpass-api.de/api/interpreter",{"data":query})
    features=[]
    for item in data["elements"]:
        coords=[[p["lon"],p["lat"]] for p in item.get("geometry",[])]
        if len(coords)<2: continue
        tags=item.get("tags",{})
        polygon=coords[0]==coords[-1] and "building" in tags
        features.append({"type":"Feature","geometry":{"type":"Polygon" if polygon else "LineString","coordinates":[coords] if polygon else coords},"properties":{"osm_id":item["id"],**tags}})
    if not features: raise RuntimeError("No mapped geometry returned")
    result={"type":"FeatureCollection","features":features,"address_point":[lon,lat],"attribution":"Address: Kartverket; geometry: © OpenStreetMap contributors, ODbL","surveyed":False}
    path=pathlib.Path(__file__).resolve().parents[1]/"data"/"sandvenhagen.geojson"
    path.parent.mkdir(exist_ok=True)
    path.write_text(json.dumps(result,ensure_ascii=False),encoding="utf-8")
    print(f"Wrote {len(features)} features to {path}")
if __name__=="__main__": main()
