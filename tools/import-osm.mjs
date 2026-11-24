/* Run with Node 18+: node tools/import-osm.mjs
   OSM data © OpenStreetMap contributors, ODbL. */
import {mkdir,writeFile} from 'node:fs/promises';
const bbox='60.350,6.125,60.405,6.235';
const query='[out:json][timeout:90];(way["highway"]('+bbox+');way["natural"="coastline"]('+bbox+');way["building"]('+bbox+'););out geom;';
const response=await fetch('https://overpass-api.de/api/interpreter',{method:'POST',body:new URLSearchParams({data:query})});
if(!response.ok)throw Error('Overpass HTTP '+response.status);
const data=await response.json();
const ways=data.elements.filter(e=>e.type==='way'&&e.geometry?.length>1).map(e=>({id:e.id,tags:e.tags,points:e.geometry.map(p=>[p.lon,p.lat])}));
if(!ways.some(w=>w.tags.highway))throw Error('No roads returned');
await mkdir('data',{recursive:true});
await writeFile('data/hardanger-osm.json',JSON.stringify({source:'OpenStreetMap',license:'ODbL-1.0',bbox,ways}));
console.log('Imported '+ways.length+' ways');
