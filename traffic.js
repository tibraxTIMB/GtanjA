(function(root){
const path=[[90,140],[620,140],[620,510],[90,510]];
function pose(distance){let d=((distance%1800)+1800)%1800;for(let i=0;i<4;i++){const a=path[i],b=path[(i+1)%4],len=Math.hypot(b[0]-a[0],b[1]-a[1]);if(d<len)return {x:a[0]+(b[0]-a[0])*d/len,y:a[1]+(b[1]-a[1])*d/len,a:Math.atan2(b[1]-a[1],b[0]-a[0])};d-=len}}
function vehicles(clock,rivals){return rivals.map((r,i)=>({...r,...pose(clock*r.speed+i*150)}))}
function blocked(x,y,radius,vehicles){return vehicles.some(o=>[0, -35].some(offset=>Math.hypot(x-o.x-offset*Math.cos(o.a),y-o.y-offset*Math.sin(o.a))<radius+12))}
root.GTTraffic={pose,vehicles,blocked};
})(globalThis);