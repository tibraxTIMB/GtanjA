/* Prototype road graph. Fictional coordinates, not surveyed geography. */
(function(root){
const navNodes=[[107,300],[205,300],[330,300],[330,140],[90,140],[90,300],[90,510],[620,140],[620,300],[620,510],[735,510],[735,490],[900,300],[1000,300],[1500,300],[2150,300],[1000,700],[1500,700],[2150,700],[1000,1050],[1000,1250],[1500,1250],[2150,1250],[90,1050]];
const navEdges=[[0,1],[0,5],[1,2],[2,3],[2,8],[3,4],[3,7],[4,5],[5,6],[6,9],[7,8],[8,9],[9,10],[10,11],[8,12],[12,13],[13,14],[14,15],[13,16],[14,17],[15,18],[16,17],[17,18],[16,19],[19,20],[20,21],[21,22],[17,21],[18,22],[6,23],[23,19]];
function routeBetween(start,end){const dist=(p,q)=>Math.hypot(p[0]-q[0],p[1]-q[1]);const nearest=p=>navNodes.reduce((best,n,i)=>dist(p,n)<dist(p,navNodes[best])?i:best,0);const a=nearest(start),b=nearest(end),d=navNodes.map(()=>Infinity),prev=[],todo=new Set(navNodes.map((_,i)=>i));d[a]=0;while(todo.size){const u=[...todo].reduce((p,q)=>d[p]<=d[q]?p:q);todo.delete(u);if(u===b||!Number.isFinite(d[u]))break;for(const edge of navEdges){const v=edge[0]===u?edge[1]:edge[1]===u?edge[0]:-1;if(v<0||!todo.has(v))continue;const n=d[u]+dist(navNodes[u],navNodes[v]);if(n<d[v]){d[v]=n;prev[v]=u}}}if(!Number.isFinite(d[b]))return [];const path=[];for(let u=b;u!==undefined;u=prev[u])path.unshift(navNodes[u]);return [start,...path,end]}

root.GTWorld={navNodes,navEdges,routeBetween};
})(globalThis);