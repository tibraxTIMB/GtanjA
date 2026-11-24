(function(root){
const path=[[90,140],[620,140],[620,510],[90,510]];const lapLength=path.reduce((n,p,i)=>n+Math.hypot(p[0]-path[(i+1)%path.length][0],p[1]-path[(i+1)%path.length][1]),0);
function pose(distance){let d=((distance%lapLength)+lapLength)%lapLength;for(let i=0;i<4;i++){const a=path[i],b=path[(i+1)%4],len=Math.hypot(b[0]-a[0],b[1]-a[1]);if(d<len)return {x:a[0]+(b[0]-a[0])*d/len,y:a[1]+(b[1]-a[1])*d/len,a:Math.atan2(b[1]-a[1],b[0]-a[0])};d-=len}}
function vehicles(clock,rivals){return rivals.map((r,i)=>({...r,...pose(clock*r.speed+i*150)}))}
function blocked(x,y,radius,vehicles){return vehicles.some(o=>[0, -35].some(offset=>Math.hypot(x-o.x-offset*Math.cos(o.a),y-o.y-offset*Math.sin(o.a))<radius+12))}
function advance(state,rivals,dt,player){return rivals.map((r,i)=>{const old=state[i]||{distance:i*150,speed:r.speed};const p=pose(old.distance),ahead=pose(old.distance+65);const near=Math.hypot(ahead.x-player.x,ahead.y-player.y)<65||Math.hypot(p.x-player.x,p.y-player.y)<55;const speed=old.speed+((near?0:r.speed)-old.speed)*Math.min(1,dt*3);return {distance:old.distance+speed*dt,speed};});}
function live(state,rivals){return rivals.map((r,i)=>({...r,...pose(state[i]?.distance??i*150)}))}
root.GTTraffic={lapLength,pose,vehicles,blocked,advance,live};
})(globalThis);