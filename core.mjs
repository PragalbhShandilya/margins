export const VERSION = 3;
export const uid = () => globalThis.crypto.randomUUID();
export const types = ['Books', 'Movies', 'Life'];
export const blank = () => ({version:VERSION,quotes:[],following:[],profile:{name:'A reader',bio:''},moment:{enabled:false,source:'library',quoteId:'',mood:'forest',image:'',frequency:1,start:'09:00',end:'20:00',nextAt:null,lastAt:null}});
export function cleanQuote(q, existing = {}) {
  if (!q || typeof q !== 'object') throw Error('This quote is not valid.');
  if(typeof q.text!=='string')throw Error('Write a quote as text.');
  const text = String(q.text??'').trim(), author = String(q.author??'').trim(), source = String(q.source??'').trim();
  if (!text || text.length > 2000) throw Error('Write a quote between 1 and 2,000 characters.');
  if(author.length>120||source.length>200) throw Error('Keep names under 120 characters and context under 200.');
  if(!types.includes(q.type)) throw Error('Choose Books, Movies, or From life.');
  return {id:existing.id||q.id||uid(),text,author:author||'Unknown',source,type:q.type,saved:!!q.saved,createdAt:typeof (existing.createdAt||q.createdAt)==='string'&&Number.isFinite(Date.parse(existing.createdAt||q.createdAt))?new Date(existing.createdAt||q.createdAt).toISOString():new Date().toISOString(),updatedAt:new Date().toISOString(),origin:typeof q.origin==='string'?q.origin.slice(0,100):'',visibility:q.visibility==='public'?'public':'private',publishedBy:typeof q.publishedBy==='string'?q.publishedBy:''};
}
export function validateMoment(m, quotes=[]) {
  if(!m||typeof m!=='object')throw Error('Choose your moment settings.');
  if(!/^([01]\d|2[0-3]):[0-5]\d$/.test(m.start)||!/^([01]\d|2[0-3]):[0-5]\d$/.test(m.end)||m.start>=m.end) throw Error('Choose an end time after the start time.');
  if(![1,2,3].includes(Number(m.frequency)))throw Error('Choose a reminder frequency.');
  if(!['library','favorites','channels','quote'].includes(m.source))throw Error('Choose a quote collection.');
  if(m.source==='quote'&&!quotes.some(q=>q.id===m.quoteId))throw Error('Choose a quote that is still in your library.');
  if(!['forest','sea','paper','photo'].includes(m.mood))throw Error('Choose a card background.');
  if(m.mood==='photo'&&!/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/.test(m.image||''))throw Error('Choose a photo for your card.');
  if((m.image||'').length>900000)throw Error('This photo is too large. Choose a smaller one.');
  return {...m,frequency:Number(m.frequency),enabled:!!m.enabled};
}
export function pool(state, channels=[]) {
 const m=state.moment;
 if(m.source==='quote')return state.quotes.filter(q=>q.id===m.quoteId);
 if(m.source==='favorites')return state.quotes.filter(q=>q.saved);
 if(m.source==='channels')return channels.filter(c=>state.following.includes(c.id)).flatMap(c=>c.quotes.map(q=>({...q,origin:c.title})));
 return state.quotes;
}
// Plan one random slot in each equal segment of the user's local quiet-hours window.
export function nextMoment(m, now=new Date(), random=Math.random) {
 if(!m.enabled)return null;
 validateMoment({...m,source:'library'});
 const [sh,sm]=m.start.split(':').map(Number),[eh,em]=m.end.split(':').map(Number);
 const start=new Date(now);start.setHours(sh,sm,0,0);
 const end=new Date(now);end.setHours(eh,em,0,0);
 const slots=Number(m.frequency),duration=(end-start)/slots;
 for(let i=0;i<slots;i++){
  const a=+start+i*duration,b=+start+(i+1)*duration;
  if(b<=+now)continue;
  const lower=Math.max(a,+now+1000);
  if(lower>=b)continue;
  // If one notification was delivered in this segment, never plan another in it.
  if(m.lastAt&&Date.parse(m.lastAt)>=a&&Date.parse(m.lastAt)<b)continue;
  return new Date(lower+Math.min(.999999,Math.max(0,random()))*(b-lower)).toISOString();
 }
 const tomorrow=new Date(now);tomorrow.setDate(tomorrow.getDate()+1);tomorrow.setHours(sh,sm,0,0);
 return nextMoment({...m,lastAt:null},new Date(+tomorrow-1000),random);
}
export function decode(raw, legacy) {
 if(raw){
  const p=JSON.parse(raw);
  if(p.version!==VERSION||!Array.isArray(p.quotes)||p.quotes.length>5000)throw Error('This collection has an unsupported format.');
  const state=blank(),seen=new Set();
  state.quotes=p.quotes.map(q=>{if(typeof q.id!=='string'||! /^[A-Za-z0-9_-]{1,100}$/.test(q.id)||seen.has(q.id))throw Error('This collection contains invalid or duplicate quote IDs.');seen.add(q.id);return cleanQuote(q,q)});
  state.following=Array.isArray(p.following)?[...new Set(p.following.filter(x=>typeof x==='string'&&x.length<100))].slice(0,200):[];
  state.profile={name:String(p.profile?.name||'A reader').slice(0,60),bio:String(p.profile?.bio||'').slice(0,180)};
  try{state.moment=validateMoment({...state.moment,...p.moment},state.quotes);if(state.moment.nextAt&&!Number.isFinite(Date.parse(state.moment.nextAt)))state.moment.nextAt=null;}catch{state.moment={...blank().moment};}
  return state;
 }
 const state=blank();
 if(legacy){const arr=JSON.parse(legacy);if(!Array.isArray(arr))throw Error('Old collection could not be read.');state.quotes=arr.map(q=>cleanQuote(q));}
 return state;
}
export function filterQuotes(quotes, filter, query='',sort='newest') {
 const words=query.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);
 return quotes.filter(q=>(filter==='All'||filter==='Favorites'&&q.saved||filter===q.type)&&words.every(w=>[q.text,q.author,q.source].join(' ').toLocaleLowerCase().includes(w))).sort((a,b)=>sort==='author'?a.author.localeCompare(b.author):sort==='oldest'?a.createdAt.localeCompare(b.createdAt):b.createdAt.localeCompare(a.createdAt));
}
