// Cliente HTTP único. Agrega el token y convierte los errores del backend en Error con mensaje.
export async function api(ruta, { method = 'GET', body } = {}) {
  const sesion = JSON.parse(localStorage.getItem('steps_sesion') || 'null');
  const r = await fetch(`/api${ruta}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...(sesion ? { Authorization: `Bearer ${sesion.token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const datos = await r.json().catch(() => ({}));
  if (!r.ok) { const e = new Error(datos.error || 'No se pudo completar la operación.'); e.status = r.status; throw e; }
  return datos;
}
