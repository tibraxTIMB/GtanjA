/* Run with Node 18+: node tools/import-osm.mjs
   OSM data © OpenStreetMap contributors, ODbL. */
import {mkdir,writeFile} from 'node:fs/promises';
const bbox='60.350,6.125,60.405,6.235';
const query='[out:json][timeout:90];(way["highway"]('+bbox+');way["natural"="coastline"]('+bbox+');way["building"]('+bbox+'););out geom;';
let data;const errors=[];
for(const endpoint of ['https://overpass-api.de/api/interpreter','https://overpass.kumi.systems/api/interpreter','https://overpass.private.coffee/api/interpreter']){
 try{
  const response=await fetch(endpoint+'?'+new URLSearchParams({data:query}),{signal:AbortSignal.timeout(110000)});
  if(!response.ok)throw Error('HTTP '+response.status);
  const candidate=await response.json();
  if(candidate.remark||!candidate.elements?.some(e=>e.tags?.highway))throw Error(candidate.remark||'No roads');
  data=candidate;break;
 }catch(e){errors.push(endpoint+': '+e.message);console.error(errors.at(-1))}
}
if(!data)throw Error(errors.join('\n'));
const ways=data.elements.filter(e=>e.type==='way'&&e.geometry?.length>1).map(e=>({id:e.id,tags:e.tags,points:e.geometry.map(p=>[p.lon,p.lat])}));
if(!ways.some(w=>w.tags.highway))throw Error('No roads returned');
await mkdir('data',{recursive:true});
await writeFile('data/hardanger-osm.json',JSON.stringify({source:'OpenStreetMap',license:'ODbL-1.0',bbox,ways}));
console.log('Imported '+ways.length+' ways');
