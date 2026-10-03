// Riung asset library — original monster characters + icon family.
// <riung-monster monster="waswas" state="wild|tamed"></riung-monster>  (fills container)
// <riung-icon name="home" size="24" color="#B4BAE0"></riung-icon>
(function(){
const INK='#1B1E33';
const C={
 meronta:{t:'#6E7BA6',tl:'#93A0C6',w:'#4A5170',wl:'#61688A'},
 waswas:{t:'#E8A94E',tl:'#F2C67F',w:'#8F7443',wl:'#A98F5C'},
 kabut:{t:'#9AA2B8',tl:'#BCC2D2',w:'#5E6474',wl:'#7A8092'},
 cermin:{t:'#B39DDB',tl:'#CFC0EA',w:'#6E6386',wl:'#8A7EA4'},
 sempurna:{t:'#F2766F',tl:'#F8A19B',w:'#8F4B47',wl:'#AC6560'},
 mengelak:{t:'#5FB0A0',tl:'#8CC9BD',w:'#3E6E65',wl:'#578B80'},
 hakim:{t:'#8B5CF6',tl:'#B39BF9',w:'#54406E',wl:'#6F5A8C'},
};
window.RIUNG_MONSTER_COLORS={meronta:'#6E7BA6',waswas:'#E8A94E',kabut:'#9AA2B8',cermin:'#B39DDB',sempurna:'#F2766F',mengelak:'#5FB0A0',hakim:'#8B5CF6'};
const P=n=>(+n).toFixed(1);
const spiky=(cx,cy,r1,r2,n)=>{let d='';for(let i=0;i<n*2;i++){const r=i%2?r2:r1,a=Math.PI*i/n-Math.PI/2;d+=(i?'L':'M')+P(cx+r*Math.cos(a))+','+P(cy+r*Math.sin(a));}return d+'Z';};
const eye=(x,y,r,o={})=>{const w=o.wild,look=o.look||0;
 return `<ellipse cx="${x}" cy="${y}" rx="${r}" ry="${P(r*1.12)}" fill="#FDFDFF"/><circle cx="${P(x+look)}" cy="${P(y+(w?0:r*0.14))}" r="${P(w?r*0.34:r*0.52)}" fill="${INK}"/>`+(w?'':`<circle cx="${P(x+look+r*0.22)}" cy="${P(y-r*0.14)}" r="${P(r*0.16)}" fill="#fff"/>`);};
const brow=(x,y,len,ang,sw=4)=>{const a=ang*Math.PI/180,dx=Math.cos(a)*len/2,dy=Math.sin(a)*len/2;
 return `<line x1="${P(x-dx)}" y1="${P(y-dy)}" x2="${P(x+dx)}" y2="${P(y+dy)}" stroke="${INK}" stroke-width="${sw}" stroke-linecap="round"/>`;};
const smile=(x,y,w,d)=>`<path d="M${x-w} ${y} Q${x} ${y+d} ${x+w} ${y}" stroke="${INK}" stroke-width="4" fill="none" stroke-linecap="round"/>`;
const jag=(x,y,w)=>{let d=`M${x-w} ${y}`;const n=4,s=(2*w)/n;for(let i=1;i<=n;i++)d+=` L${P(x-w+s*i-s/2)} ${y+(i%2?6:-2)} L${P(x-w+s*i)} ${y}`;return `<path d="${d}" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linejoin="round" stroke-linecap="round"/>`;};
const blush=(x,y)=>`<ellipse cx="${x}" cy="${y}" rx="8" ry="4.5" fill="#F27C86" opacity="0.4"/>`;
const sparkle=(x,y,s,c='#FFE9C2')=>LOW?'':`<path d="M${x} ${y-s} Q${P(x+s*0.22)} ${P(y-s*0.22)} ${x+s} ${y} Q${P(x+s*0.22)} ${P(y+s*0.22)} ${x} ${y+s} Q${P(x-s*0.22)} ${P(y+s*0.22)} ${x-s} ${y} Q${P(x-s*0.22)} ${P(y-s*0.22)} ${x} ${y-s}Z" fill="${c}"/>`;
// truntum batik-star dot motif (subtle Indonesian ornament)
let LOW=false; // low-detail mode for small sizes
const truntum=(x,y,c)=>LOW?'':`<g fill="${c}" opacity="0.45"><circle cx="${x}" cy="${y-5}" r="1.8"/><circle cx="${x}" cy="${y+5}" r="1.8"/><circle cx="${x-5}" cy="${y}" r="1.8"/><circle cx="${x+5}" cy="${y}" r="1.8"/><circle cx="${x}" cy="${y}" r="1.3"/></g>`;
const aura=(w,c)=>w?`<path d="${spiky(100,112,90,76,14)}" fill="${c.w}" opacity="0.22"/>`:`<circle cx="100" cy="112" r="88" fill="${c.t}" opacity="0.16"/>`;
const drop=(x,y,s=1)=>`<path d="M${x} ${y} c ${3*s} ${5*s} ${3*s} ${8*s} 0 ${10*s} c ${-3*s} ${-2*s} ${-3*s} ${-5*s} 0 ${-10*s} z" fill="#9FD8FF"/>`;

const D={
meronta(s){const w=s==='wild',c=C.meronta,b=w?c.w:c.t,l=w?c.wl:c.tl;
 // sagging, melting blob: slumped dome + side drips + puddle base (it wallows)
 return aura(w,c)
 +`<ellipse cx="100" cy="174" rx="62" ry="11" fill="${b}"/>`
 +`<ellipse cx="46" cy="150" rx="8" ry="17" fill="${b}"/><ellipse cx="154" cy="146" rx="7" ry="14" fill="${b}"/>`
 +`<path d="M100 62 C68 64 54 90 50 122 C46 152 64 170 100 170 C136 170 154 152 150 122 C146 90 132 64 100 62 Z" fill="${b}"/>`
 +`<ellipse cx="58" cy="134" rx="9" ry="20" transform="rotate(14 58 134)" fill="${b}"/><ellipse cx="142" cy="134" rx="9" ry="20" transform="rotate(-14 142 134)" fill="${b}"/>`
 +`<ellipse cx="100" cy="148" rx="30" ry="15" fill="${l}" opacity="0.65"/>`+truntum(100,148,'#FDFDFF')
 +eye(82,110,10,{wild:w})+eye(118,110,10,{wild:w})
 +brow(80,94,16,w?-20:-9)+brow(120,94,16,w?20:9)
 +(w?`<ellipse cx="100" cy="136" rx="9" ry="10" fill="${INK}"/><ellipse cx="100" cy="141" rx="5" ry="3" fill="#F27C86"/>`
   +`<path d="M80 122 q-4 22 0 44" stroke="#9FD8FF" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.85"/><path d="M120 122 q4 22 0 44" stroke="#9FD8FF" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.85"/>`
  :smile(100,132,11,7)+blush(74,124)+blush(126,124)+drop(68,116,0.7)+sparkle(150,60,6));},
waswas(s){const w=s==='wild',c=C.waswas,b=w?c.w:c.t,l=w?c.wl:c.tl;
 return aura(w,c)
 +`<ellipse cx="82" cy="180" rx="11" ry="6" fill="${l}"/><ellipse cx="118" cy="180" rx="11" ry="6" fill="${l}"/>`
 +(w?`<path d="M84 64 l-5 -11 l7 -7" stroke="${b}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M116 64 l5 -11 l-7 -7" stroke="${b}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`
    :`<path d="M84 64 q-7 -12 1 -19" stroke="${b}" stroke-width="5" fill="none" stroke-linecap="round"/><circle cx="85" cy="43" r="4.5" fill="${b}"/><path d="M116 64 q7 -12 -1 -19" stroke="${b}" stroke-width="5" fill="none" stroke-linecap="round"/><circle cx="115" cy="43" r="4.5" fill="${b}"/>`)
 +`<circle cx="100" cy="120" r="60" fill="${b}"/><ellipse cx="100" cy="152" rx="32" ry="17" fill="${l}" opacity="0.65"/>`+truntum(100,152,'#FDFDFF')
 +eye(100,104,13,{wild:w})+eye(70,118,8,{wild:w,look:w?-3:0})+eye(130,118,8,{wild:w,look:w?3:0})
 +(w?`<path d="M28 102 q-7 14 0 28" stroke="${c.wl}" stroke-width="4" fill="none" stroke-linecap="round"/><path d="M172 102 q7 14 0 28" stroke="${c.wl}" stroke-width="4" fill="none" stroke-linecap="round"/>`+jag(100,140,12)
  :smile(100,138,11,8)+blush(76,134)+blush(124,134)+sparkle(150,70,6));},
kabut(s){const w=s==='wild',c=C.kabut,b=w?c.w:c.t,l=w?c.wl:c.tl;
 return aura(w,c)
 +`<g fill="${b}"><circle cx="70" cy="122" r="30"/><circle cx="100" cy="100" r="38"/><circle cx="132" cy="120" r="30"/><circle cx="100" cy="132" r="40"/></g>`
 +`<circle cx="42" cy="162" r="8" fill="${b}" opacity="0.6"/><circle cx="162" cy="150" r="6" fill="${b}" opacity="0.5"/>`
 +`<ellipse cx="100" cy="150" rx="26" ry="14" fill="${l}" opacity="0.5"/>`+truntum(100,150,'#FDFDFF')
 +(w?`<path d="M74 106 h14 M112 106 h14" stroke="${INK}" stroke-width="4.5" stroke-linecap="round"/><path d="M140 84 a8 8 0 1 1 -8 -8" stroke="${c.wl}" stroke-width="3.5" fill="none" stroke-linecap="round"/><path d="M88 132 q6 -7 12 0 q6 7 12 0" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`
  :eye(81,106,9)+eye(119,106,9)+smile(100,128,11,8)+blush(70,120)+blush(130,120)+sparkle(146,72,6));},
cermin(s){const w=s==='wild',c=C.cermin,b=w?c.w:c.t,g1=w?'#9BA1B8':'#DCE4FA';
 return aura(w,c)
 +`<ellipse cx="84" cy="176" rx="10" ry="6" fill="${b}"/><ellipse cx="116" cy="176" rx="10" ry="6" fill="${b}"/>`
 +`<circle cx="55" cy="122" r="8" fill="${b}"/><circle cx="145" cy="122" r="8" fill="${b}"/>`
 +`<rect x="60" y="52" width="80" height="120" rx="40" fill="${b}"/><rect x="69" y="61" width="62" height="102" rx="31" fill="${g1}"/>`
 +`<path d="M118 70 l-26 38" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity="0.55"/><path d="M125 84 l-13 19" stroke="#fff" stroke-width="4" stroke-linecap="round" opacity="0.45"/>`
 +truntum(100,58,'#FDFDFF')
 +(w?`<path d="M104 61 l-7 20 l11 9 l-9 18" stroke="#565B73" stroke-width="2.5" fill="none" stroke-linejoin="round"/>`
    +eye(85,118,8,{wild:1})+eye(115,118,8,{wild:1})+brow(83,104,13,-16)+brow(117,104,13,16)+`<path d="M91 140 q9 -7 18 0" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`
  :eye(85,118,8)+eye(115,118,8)+smile(100,136,10,7)+blush(78,130)+blush(122,130)+sparkle(122,74,6,'#fff'));},
sempurna(s){const w=s==='wild',c=C.sempurna,b=w?c.w:c.t,l=w?c.wl:c.tl,rx=w?10:26;
 return aura(w,c)
 +`<ellipse cx="84" cy="172" rx="11" ry="6" fill="${l}"/><ellipse cx="116" cy="172" rx="11" ry="6" fill="${l}"/>`
 +`<circle cx="52" cy="132" r="9" fill="${b}"/>`
 +`<rect x="58" y="72" width="84" height="96" rx="${rx}" fill="${b}"/>`
 +`<path d="M74 148 h52 M74 156 h38" stroke="${l}" stroke-width="3" stroke-linecap="round" opacity="0.8"/>`+truntum(126,153,'#FDFDFF')
 +eye(86,108,9,{wild:w})+eye(116,108,9,{wild:w})
 +brow(84,93,15,w?14:5)+brow(118,93,15,w?-14:-5)
 +(w?`<circle cx="150" cy="88" r="9" fill="${b}"/><g transform="rotate(20 150 78)"><rect x="146" y="42" width="8" height="36" rx="4" fill="#E5E9F7"/><path d="M146 82 l4 9 l4 -9 z" fill="#D94F46"/></g>`
    +`<rect x="86" y="128" width="28" height="11" rx="4.5" fill="${INK}"/><path d="M93 128 v11 M100 128 v11 M107 128 v11" stroke="#fff" stroke-width="1.6" opacity="0.85"/>`
    +`<path d="M40 60 l4 4 l7 -8" stroke="${c.wl}" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M158 130 l4 4 l7 -8" stroke="${c.wl}" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`
  :`<circle cx="148" cy="132" r="9" fill="${b}"/>`+smile(101,130,11,8)+blush(76,122)+blush(126,122)+sparkle(46,56,6));},
mengelak(s){const w=s==='wild',c=C.mengelak,b=w?c.w:c.t,l=w?c.wl:c.tl;
 // diagonal mid-escape comet: leaning body + motion-trail tail toward lower-left (it dodges)
 return aura(w,c)
 +`<path d="M30 ${w?98:104} h24 M22 ${w?118:124} h20 M34 ${w?138:142} h15" stroke="${l}" stroke-width="5" stroke-linecap="round" opacity="${w?0.9:0.5}" transform="rotate(-8 100 120)"/>`
 +`<path d="M100 170 C76 180 48 178 30 164 C50 158 64 146 72 126 C76 146 86 162 100 170 Z" fill="${b}" opacity="0.85"/>`
 +`<path d="M118 36 C140 62 156 94 152 126 C148 158 128 174 104 172 C80 170 64 150 68 120 C72 90 96 62 118 36 Z" fill="${b}"/>`
 +`<path d="M112 44 C96 66 82 94 80 122" stroke="${l}" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.7"/>`
 +`<ellipse cx="112" cy="146" rx="26" ry="15" transform="rotate(-10 112 146)" fill="${l}" opacity="0.6"/>`+truntum(112,146,'#FDFDFF')
 +(w?eye(100,104,9,{wild:1,look:-4})+eye(132,100,9,{wild:1,look:-4})+brow(98,90,14,-14)+brow(134,86,14,-4)
    +`<path d="M104 126 q10 -6 20 2" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`
    +`<ellipse cx="116" cy="116" rx="4" ry="5" fill="#CFE7E2" opacity="0.9"/>`
  :eye(100,104,9)+eye(132,100,9)+smile(116,126,11,8)+blush(90,116)+blush(144,112)+sparkle(152,52,6));},
hakim(s){const w=s==='wild',c=C.hakim,b=w?c.w:c.t,l=w?c.wl:c.tl;
 return aura(w,c)
 // broad boss silhouette with judge collar + gavel
 +`<path d="M100 30 C64 30 44 62 44 106 C44 152 66 178 100 178 C134 178 156 152 156 106 C156 62 136 30 100 30 Z" fill="${b}"/>`
 // horn-like wig curls
 +`<circle cx="56" cy="66" r="12" fill="${l}"/><circle cx="144" cy="66" r="12" fill="${l}"/><circle cx="48" cy="88" r="9" fill="${l}"/><circle cx="152" cy="88" r="9" fill="${l}"/>`
 +`<path d="M78 158 l10 12 l12 -12 l12 12 l10 -12" stroke="#FDFDFF" stroke-width="5" fill="${b}" stroke-linejoin="round" stroke-linecap="round"/>`
 +`<ellipse cx="100" cy="140" rx="34" ry="16" fill="${l}" opacity="0.55"/>`+truntum(100,140,'#FDFDFF')
 +eye(82,96,11,{wild:w})+eye(118,96,11,{wild:w})
 +brow(79,78,18,w?16:6,5)+brow(121,78,18,w?-16:-6,5)
 +(w?`<path d="M88 126 q12 -8 24 0" stroke="${INK}" stroke-width="4" fill="none" stroke-linecap="round"/>`
    +`<g transform="rotate(-30 158 96)"><rect x="150" y="60" width="16" height="26" rx="6" fill="${c.wl}"/><rect x="154" y="86" width="8" height="34" rx="4" fill="${c.wl}"/></g>`
    +`<path d="M30 58 l6 10 M38 50 l4 12 M170 58 l-6 10 M162 50 l-4 12" stroke="${c.wl}" stroke-width="3.5" stroke-linecap="round"/>`
  :smile(100,122,13,9)+blush(72,110)+blush(128,110)
    +`<g transform="rotate(40 156 150)"><rect x="148" y="128" width="16" height="24" rx="7" fill="${l}"/><rect x="152" y="152" width="8" height="28" rx="4" fill="${l}"/></g>`
    +sparkle(44,52,7)+sparkle(160,44,5));},
};

// ---- Cosmetics: attachment points per monster (200x210 viewbox) + launch items ----
// Anchors: head=[x,y,scale,rot], neck=[x,y,scale,rot], base=[x,y,scale]. Base monsters are never redrawn —
// cosmetics are separate <g> layers composed under/over the art via the cosmetic="topi|syal|bantal|bingkai" attribute.
const ANCH={
 meronta:{head:[100,66,1,0],neck:[100,150,1,0],base:[100,176,1.12]},
 waswas:{head:[100,58,1,0],neck:[100,158,1,0],base:[100,182,1]},
 kabut:{head:[100,60,1,0],neck:[100,150,1,0],base:[100,170,1]},
 cermin:{head:[100,50,0.95,0],neck:[100,152,0.95,0],base:[100,178,1]},
 sempurna:{head:[100,70,0.95,0],neck:[100,152,0.95,0],base:[100,176,1]},
 mengelak:{head:[116,40,0.88,-12],neck:[108,148,0.95,-8],base:[98,178,1.05]},
 hakim:{head:[100,28,1.15,0],neck:[100,162,1.15,0],base:[100,182,1.2]},
};
const COS={
 topi:m=>{const[x,y,s,r]=(ANCH[m]||ANCH.hakim).head;return{over:`<g transform="translate(${x} ${y}) rotate(${r||0}) scale(${s})">`
 +`<path d="M-27 3 C-27 -19 -13 -30 0 -30 C13 -30 27 -19 27 3 Z" fill="#F2766F"/>`
 +`<path d="M-20 -6 C-13 -12 13 -12 20 -6 M-23 -14 C-14 -21 14 -21 23 -14" stroke="#D95E56" stroke-width="2.5" fill="none" stroke-linecap="round"/>`
 +`<rect x="-29" y="1" width="58" height="11" rx="5.5" fill="#D95E56"/>`
 +`<path d="M-22 3.5 v6 M-14 3.5 v6 M-6 3.5 v6 M2 3.5 v6 M10 3.5 v6 M18 3.5 v6" stroke="#F8A19B" stroke-width="2" stroke-linecap="round"/>`
 +`<circle cx="0" cy="-33" r="7" fill="#FFE9C2"/><circle cx="0" cy="-33" r="4" fill="none" stroke="#F2C67F" stroke-width="1.5" stroke-dasharray="2 3"/></g>`};},
 syal:m=>{const[x,y,s,r]=(ANCH[m]||ANCH.hakim).neck;return{over:`<g transform="translate(${x} ${y}) rotate(${r||0}) scale(${s})">`
 +`<path d="M16 5 L25 34 L38 30 L28 3 Z" fill="#7C8CFF"/>`
 +`<path d="M26.5 33 l1.5 7 M31.5 31.5 l1.5 7 M36 30 l1.5 7" stroke="#5A66B8" stroke-width="2.5" stroke-linecap="round"/>`
 +`<path d="M20 13 l11 -3.5 M22.5 21 l11 -3.5" stroke="#5A66B8" stroke-width="3" stroke-linecap="round" opacity="0.7"/>`
 +`<rect x="-34" y="-9" width="68" height="17" rx="8.5" fill="#7C8CFF"/>`
 +`<path d="M-24 -9 v17 M-8 -9 v17 M8 -9 v17 M24 -9 v17" stroke="#5A66B8" stroke-width="3" stroke-linecap="round" opacity="0.7"/></g>`};},
 bantal:m=>{const[x,y,s]=(ANCH[m]||ANCH.hakim).base;return{under:`<g transform="translate(${x} ${y}) scale(${s})">`
 +`<rect x="-54" y="-15" width="108" height="31" rx="15.5" fill="#B39DDB"/>`
 +`<rect x="-54" y="-15" width="108" height="31" rx="15.5" fill="none" stroke="#8A7EA4" stroke-width="2"/>`
 +`<path d="M-40 1 h80" stroke="#CFC0EA" stroke-width="2.5" stroke-dasharray="2 6" stroke-linecap="round"/></g>`};},
 bingkai:()=>({over:`<g><rect x="64" y="56" width="72" height="112" rx="36" fill="none" stroke="#FFCE73" stroke-width="5"/>`
 +`<rect x="64" y="56" width="72" height="112" rx="36" fill="none" stroke="#E8A94E" stroke-width="1.8" stroke-dasharray="3 7"/>`
 +`<circle cx="100" cy="53" r="4.5" fill="#FFCE73"/><circle cx="100" cy="171" r="4.5" fill="#FFCE73"/></g>`}), // khusus Si Cermin (bingkai emas mengikuti geometri cermin)
};
const inner=el=>{let d=el.querySelector(':scope > .riung-art');if(!d){d=document.createElement('div');d.className='riung-art';el.appendChild(d);}return d;};
const keepArt=el=>{if(el._mo)return;el._mo=new MutationObserver(()=>{if(el.isConnected&&!el.querySelector(':scope > .riung-art'))setTimeout(()=>el.render(),0);});el._mo.observe(el,{childList:true});};
const st=document.createElement('style');st.textContent='riung-monster{display:block;width:100%;height:100%}riung-icon{display:inline-block;flex-shrink:0;line-height:0}';document.head.appendChild(st);
class RiungMonster extends HTMLElement{
 static get observedAttributes(){return['monster','state','detail','cosmetic'];}
 attributeChangedCallback(){this.render();}
 connectedCallback(){keepArt(this);this.render();requestAnimationFrame(()=>{const cw=this.clientWidth,low=cw>0&&cw<72;if(low!==!!this._low){this._low=low;this.render();}});}
 render(){const m=this.getAttribute('monster')||'hakim',s=this.getAttribute('state')||'tamed',fn=D[m];
  if(!fn||!this.isConnected)return;
  LOW=this.getAttribute('detail')==='low'||!!this._low;
  const cn=this.getAttribute('cosmetic'),co=cn&&COS[cn]?COS[cn](m):null;
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 210">${(co&&co.under)||''}${fn(s)}${(co&&co.over)||''}</svg>`;
  LOW=false;
  inner(this).style.cssText=`display:block;width:100%;height:100%;background:url("data:image/svg+xml,${encodeURIComponent(svg)}") center/contain no-repeat`;
  this.setAttribute('role','img');this.setAttribute('aria-label',m+' ('+s+')');}
}
if(!customElements.get('riung-monster'))customElements.define('riung-monster',RiungMonster);

// ---- Icon family: rounded line, 24 viewBox, stroke 1.9 ----
const I={
home:'M4 10.5 12 4l8 6.5V19a1.5 1.5 0 0 1-1.5 1.5h-4v-5.5h-5v5.5h-4A1.5 1.5 0 0 1 4 19Z',
compass:'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18Z M15.5 8.5l-2.2 5-5 2.2 2.2-5Z',
focus:'M12 8v4l2.8 2.8 M12 21a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z M9.5 3h5',
monster:'M7 4.5 9 7a7 7 0 0 1 6 0l2-2.5 M5 13a7 7 0 0 1 14 0v3.5a4 4 0 0 1-4 4h-6a4 4 0 0 1-4-4Z M9.5 13.2h.01 M14.5 13.2h.01',
user:'M12 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z M5 20c.8-3.4 3.6-5 7-5s6.2 1.6 7 5',
lotus:'M12 20c-1.8-1.4-3-3.8-3-6.5S10.2 8 12 6c1.8 2 3 4.8 3 7.5S13.8 18.6 12 20Z M12 20c-3.4.4-6.4-1-8-4 1.6-1 3.4-1.4 5-1 M12 20c3.4.4 6.4-1 8-4-1.6-1-3.4-1.4-5-1',
moon:'M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5Z',
journal:'M6 4h11a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z M8 4v16 M11.5 9h3.5',
sparkChat:'M12 20a8 8 0 1 0-7-4l-1 4 4-1a8 8 0 0 0 4 1Z M12 9l.9 2.1L15 12l-2.1.9L12 15l-.9-2.1L9 12l2.1-.9Z',
coin:'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18Z M12 8v8 M14.5 10c-.5-1.2-4.8-1.5-4.8.5s5 1 4.8 3-4.3 1.7-5-.3',
flame:'M12 21c3.5 0 6-2.3 6-5.6 0-2.8-1.8-4.6-3.2-6.4C13.6 7.5 13 6 13 4c-3 1.5-4 4-3.8 6-1.5-.3-2.2-1.2-2.4-2.4C5.6 9 6 11.6 6 13.5 6 18 8.5 21 12 21Z M12 21c-1.7 0-3-1.4-3-3.2 0-1.6 1.2-2.8 3-4.3 1.8 1.5 3 2.7 3 4.3 0 1.8-1.3 3.2-3 3.2Z',
check:'M5 12.5 10 17.5 19 7',
lock:'M7 11V8a5 5 0 0 1 10 0v3 M6.5 11h11a1 1 0 0 1 1 1v7a1.5 1.5 0 0 1-1.5 1.5H7A1.5 1.5 0 0 1 5.5 19v-7a1 1 0 0 1 1-1Z M12 15v2',
play:'M8 5.5v13a.6.6 0 0 0 .9.5l10-6.5a.6.6 0 0 0 0-1l-10-6.5a.6.6 0 0 0-.9.5Z',
pause:'M8 5v14 M16 5v14',
heart:'M12 20S4 14.8 4 9.5A4.3 4.3 0 0 1 8.5 5c1.6 0 2.8.8 3.5 2 .7-1.2 1.9-2 3.5-2A4.3 4.3 0 0 1 20 9.5C20 14.8 12 20 12 20Z',
share:'M12 3v12 M8 7l4-4 4 4 M6 12H5a1 1 0 0 0-1 1v6a1.5 1.5 0 0 0 1.5 1.5h13A1.5 1.5 0 0 0 20 19v-6a1 1 0 0 0-1-1h-1',
gear:'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z M19 12a7 7 0 0 0-.2-1.6l2-1.5-2-3.4-2.3 1a7 7 0 0 0-2.8-1.7L13.5 2h-3l-.2 2.8a7 7 0 0 0-2.8 1.7l-2.3-1-2 3.4 2 1.5A7 7 0 0 0 5 12c0 .5.1 1.1.2 1.6l-2 1.5 2 3.4 2.3-1a7 7 0 0 0 2.8 1.7l.2 2.8h3l.2-2.8a7 7 0 0 0 2.8-1.7l2.3 1 2-3.4-2-1.5c.1-.5.2-1 .2-1.6Z',
bell:'M6 10a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5h-15S6 14 6 10Z M10 19a2 2 0 0 0 4 0',
chevR:'M9.5 6l6 6-6 6',
back:'M14.5 6l-6 6 6 6',
close:'M6 6l12 12 M18 6 6 18',
calendar:'M5 6h14a1 1 0 0 1 1 1v12a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 19V7a1 1 0 0 1 1-1Z M8 3.5v4 M16 3.5v4 M4 11h16',
chart:'M5 20V13 M12 20V6 M19 20v-10',
ticket:'M4 9a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v1.5a2 2 0 0 0 0 3V15a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-1.5a2 2 0 0 0 0-3Z M12 7v10',
shield:'M12 3 5 6v5c0 5 3 8.4 7 10 4-1.6 7-5 7-10V6Z M9 11.5l2.2 2.2L15.5 9',
search:'M10.5 17a6.5 6.5 0 1 0 0-13 6.5 6.5 0 0 0 0 13Z M15.5 15.5 21 21',
plus:'M12 5v14 M5 12h14',
star:'M12 3.5l2.5 5.2 5.7.7-4.2 3.9 1.1 5.6-5.1-2.8-5.1 2.8 1.1-5.6L3.8 9.4l5.7-.7Z',
download:'M12 4v11 M7.5 11 12 15.5 16.5 11 M5 19.5h14',
wifiOff:'M2 8.5C4.8 6 8.2 4.5 12 4.5c1 0 2 .1 3 .3 M22 8.5a15 15 0 0 0-4-2.5 M5.5 12.5a9.5 9.5 0 0 1 4-2.2 M18.5 12.5c-.6-.6-1.3-1-2-1.4 M9 16.2a4.7 4.7 0 0 1 3-1 M12 19.5h.01 M3.5 3.5l17 17',
edit:'M14.5 5.5 18.5 9.5 8.5 19.5 4 20l.5-4.5Z M13 7l4 4',
trash:'M5 7h14 M9.5 7V5a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v2 M7 7l1 12a1.5 1.5 0 0 0 1.5 1.4h5A1.5 1.5 0 0 0 16 19L17 7 M10 11v5 M14 11v5',
info:'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18Z M12 11v5 M12 7.5h.01',
crown:'M4.5 8.5 8 11.5 12 6l4 5.5 3.5-3-1.2 9a1.5 1.5 0 0 1-1.5 1.3H7.2a1.5 1.5 0 0 1-1.5-1.3Z',
zap:'M13 3 5 13.5h5L11 21l8-10.5h-5Z',
sun:'M12 17a5 5 0 1 0 0-10 5 5 0 0 0 0 10Z M12 2.5v2 M12 19.5v2 M4.5 12h-2 M21.5 12h-2 M5.4 5.4 6.8 6.8 M17.2 17.2l1.4 1.4 M18.6 5.4l-1.4 1.4 M6.8 17.2l-1.4 1.4',
mail:'M4 6h16a1 1 0 0 1 1 1v10a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17V7a1 1 0 0 1 1-1Z M4 7.5l8 6 8-6',
eyeOpen:'M3 12s3.5-6 9-6 9 6 9 6-3.5 6-9 6-9-6-9-6Z M12 14.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z',
phoneOff:'M8 4h8a1 1 0 0 1 1 1v14a1.5 1.5 0 0 1-1.5 1.5h-7A1.5 1.5 0 0 1 7 19V5a1 1 0 0 1 1-1Z M10.5 17.5h3 M4 4l16 16',
gift:'M4.5 11h15v8A1.5 1.5 0 0 1 18 20.5H6A1.5 1.5 0 0 1 4.5 19Z M3.5 7.5h17V11h-17Z M12 7.5v13 M12 7.5C12 5 10.5 3.5 9 3.5S6.5 5 7 6.2c.5 1.3 5 1.3 5 1.3Z M12 7.5C12 5 13.5 3.5 15 3.5s2.5 1.5 2 2.7c-.5 1.3-5 1.3-5 1.3Z',
};
class RiungIcon extends HTMLElement{
 static get observedAttributes(){return['name','size','color','stroke'];}
 attributeChangedCallback(){this.render();}
 connectedCallback(){keepArt(this);this.render();}
 render(){const n=this.getAttribute('name'),s=this.getAttribute('size')||24,c=this.getAttribute('color')||'#B4BAE0',sw=this.getAttribute('stroke')||1.9;
  if(!I[n]||!this.isConnected)return;
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path d="${I[n]}" stroke="${c}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
  inner(this).style.cssText=`display:inline-block;width:${s}px;height:${s}px;background:url("data:image/svg+xml,${encodeURIComponent(svg)}") center/contain no-repeat`;
  this.setAttribute('aria-hidden','true');}
}
if(!customElements.get('riung-icon'))customElements.define('riung-icon',RiungIcon);
})();
