const API = import.meta.env.VITE_API_URL || '/api';
let csrf = sessionStorage.getItem('csrf') || '';
async function request(path, options={}) {
  const headers = new Headers(options.headers || {});
  if (!(options.body instanceof FormData)) headers.set('content-type','application/json');
  if (csrf && !['GET','HEAD','OPTIONS'].includes((options.method||'GET').toUpperCase())) headers.set('x-csrf-token',csrf);
  const r = await fetch(API + path, {...options, headers, credentials:'include'});
  const text = await r.text(); let data={};
  try { data=text?JSON.parse(text):{} } catch { data={error:'invalid_server_response'} }
  if (!r.ok) throw new Error(data.error || `HTTP ${r.status}`);
  return data;
}
export const api={
  async register(body){const d=await request('/auth/register',{method:'POST',body:JSON.stringify(body)}); csrf=d.csrf_token; sessionStorage.setItem('csrf',csrf); return d},
  async login(body){const d=await request('/auth/login',{method:'POST',body:JSON.stringify(body)}); csrf=d.csrf_token; sessionStorage.setItem('csrf',csrf); return d},
  async logout(){const d=await request('/auth/logout',{method:'POST',body:'{}'}); csrf=''; sessionStorage.removeItem('csrf'); return d},
  me:()=>request('/auth/me'), buildings:()=>request('/buildings'), applications:()=>request('/applications'),
  createApplication:(body)=>request('/applications',{method:'POST',body:JSON.stringify(body)}), documents:()=>request('/documents'),
  uploadDocument:(form)=>request('/documents',{method:'POST',body:form}), deleteDocument:(id)=>request(`/documents/${id}`,{method:'DELETE',body:'{}'}),
  plans:()=>request('/billing'), checkout:(plan_id)=>request('/billing/checkout',{method:'POST',body:JSON.stringify({plan_id})}), portal:()=>request('/billing/portal',{method:'POST',body:'{}'})
};
