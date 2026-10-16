import {blank,decode} from './core.mjs';
export const KEY='margins-v3';
export function readState(storage){let raw='',legacy='';try{raw=storage.getItem(KEY)||'';legacy=storage.getItem('margins-data')||'';return {state:decode(raw,legacy),storageCorrupt:false,storageBlocked:false,recoveryRaw:raw||legacy,hasCurrent:!!raw}}catch(e){const blocked=['SecurityError','QuotaExceededError'].includes(e.name);return {state:blank(),storageCorrupt:!blocked,storageBlocked:blocked,recoveryRaw:raw||legacy,hasCurrent:!!raw}}}
export function writeState(storage,state,{quarantined=false}={}){if(quarantined)return {saved:false,reason:'quarantined'};try{storage.setItem(KEY,JSON.stringify(state));return {saved:true}}catch{return {saved:false,reason:'unavailable'}}}
