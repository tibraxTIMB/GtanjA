/* GTanjA physics core – arcade units, not certified vehicle simulation */
(function(root){
function loadStats(cargo){const mass=cargo.reduce((n,o)=>n+o.kg,0);return {mass,balance:mass?cargo.reduce((n,o)=>n+o.kg*(o.x+o.w/2-3),0)/mass:0};}
function step(p,input,dt){
 const mass=Math.max(0,input.mass||0),load=Math.min(1,mass/500),attached=input.attached;
 const throttle=input.forward===input.reverse?0:input.forward?1:-1;
 const target=throttle*(throttle<0?55:125)*(attached?1-.28*load:1);
 const rate=(throttle===0?6:Math.sign(target)!==Math.sign(p.v)&&p.v!==0?8:4.5)/(1+load*.8);
 const v=p.v+(target-p.v)*Math.min(1,dt*rate);
 const steer=p.steer+(input.turn*.55-p.steer)*Math.min(1,dt*8);
 const a=p.a+v*Math.tan(steer)/42*dt,x=p.x+Math.cos(a)*v*dt,y=p.y+Math.sin(a)*v*dt;
 const hx=x-23*Math.cos(a),hy=y-23*Math.sin(a),ox=p.x-23*Math.cos(p.a),oy=p.y-23*Math.sin(p.a);
 const b=attached?p.b+(-(hx-ox)*Math.sin(p.b)+(hy-oy)*Math.cos(p.b))/43:a;
 const angle=(a,b)=>Math.atan2(Math.sin(a-b),Math.cos(a-b));
 return {x,y,a,b,v,steer,hx,hy,tx:hx-43*Math.cos(b),ty:hy-43*Math.sin(b),jackknife:attached&&target<0&&Math.abs(angle(a,b))>1.35&&Math.abs(angle(a,b))>Math.abs(angle(p.a,p.b))};
}
root.GTPhysics={step,loadStats};
})(globalThis);