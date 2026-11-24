import {readFile,writeFile} from 'node:fs/promises';
const raw=JSON.parse(await readFile('data/hardanger-osm.json','utf8'));
const [south,west,north,east]=raw.bbox.split(',').map(Number);
const scale=111320,cos=Math.cos((south+north)/2*Math.PI/180);
const point=([lon,lat])=>[Math.round((lon-west)*scale*cos),Math.round((north-lat)*scale)];
const ways=raw.ways.map(w=>({...w,points:w.points.map(point)}));
const nodes=[],edges=[],ids=new Map();
function node(p){const k=p.join(',');if(!ids.has(k)){ids.set(k,nodes.length);nodes.push(p)}return ids.get(k)}
for(const w of ways.filter(w=>w.tags.highway&&!['footway','steps','path','cycleway','bridleway','pedestrian','construction','proposed'].includes(w.tags.highway))){for(let i=1;i<w.points.length;i++){const a=node(w.points[i-1]),b=node(w.points[i]);if(a!==b)edges.push([a,b])}}
if(!edges.length)throw Error('Empty road graph');
await writeFile('data/hardanger-world.json',JSON.stringify({source:raw.source,license:raw.license,units:'approximate metres',width:Math.round((east-west)*scale*cos),height:Math.round((north-south)*scale),nodes,edges,ways}));
console.log(nodes.length+' nodes, '+edges.length+' edges');
