// Bound browser readiness waits so a blocked service worker cannot leave a control spinning forever.
export function withTimeout(promise,ms=10000,message='Device notifications are not ready. Reload Margins and try again.'){
 let timer;return Promise.race([promise,new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error(message)),ms)})]).finally(()=>clearTimeout(timer));
}
// Callers clear local credentials only after the server acknowledges revocation.
export async function confirmSignout(api,token){
 if(!token)return false;
 await api('/api/signout',{method:'POST'});
 return true;
}
