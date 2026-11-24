"""Convert a licensed Kartverket GeoTIFF into a local Godot height grid.
Usage: python import_terrain.py source.tif --license LICENSE --source-url URL
Dependencies: rasterio, numpy, pyproj (open source).
"""
import argparse,json
from pathlib import Path
import numpy as np
import rasterio
from rasterio.warp import reproject, Resampling
from rasterio.transform import from_origin
from pyproj import Transformer
p=argparse.ArgumentParser()
p.add_argument("input")
p.add_argument("--license",required=True)
p.add_argument("--source-url",required=True)
p.add_argument("--step",type=int,default=10,choices=[1,2,5,10,20])
p.add_argument("--radius",type=int,default=3500)
a=p.parse_args()
if a.radius<=0: p.error("radius must be positive")
e,n=Transformer.from_crs(4326,25832,always_xy=True).transform(6.18,60.3775)
size=2*a.radius//a.step+1
if size>2001: p.error("Use a smaller tile for mobile memory")
grid=np.full((size,size),np.nan,dtype=np.float32)
with rasterio.open(a.input) as src:
    if src.crs is None: raise ValueError("Missing source CRS")
    reproject(rasterio.band(src,1),grid,src_crs=src.crs,src_transform=src.transform,src_nodata=src.nodata,dst_crs="EPSG:25832",dst_transform=from_origin(e-a.radius-a.step/2,n+a.radius+a.step/2,a.step,a.step),dst_nodata=np.nan,resampling=Resampling.bilinear)
if not np.isfinite(grid).all(): raise ValueError("Incomplete terrain coverage: no fabricated elevations")
root=Path(__file__).resolve().parents[1]/"data"
root.mkdir(exist_ok=True)
(root/"terrain.f32").write_bytes(grid.astype("<f4").tobytes())
(root/"terrain.json").write_text(json.dumps({"width":size,"height":size,"step":a.step,"x0":-a.radius,"z0":-a.radius,"crs":"EPSG:25832","origin":[e,n],"min":float(grid.min()),"max":float(grid.max()),"source":a.source_url,"license":a.license,"attribution":"Kartverket (verify source metadata)","format":"little-endian float32 row-major north to south"},indent=2))
