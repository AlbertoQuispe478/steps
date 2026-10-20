import { useEffect, useState } from 'react';
import { api } from '../../api';

// HU-02 · BD: persona (documento, nombre, apellido, email, telefono, direccion) + cliente (nit, razon_social)
const VACIO = { tipo: 'CI', documento: '', nombre: '', apellido: '', correo: '', telefono: '', nit: '', razon_social: '', direccion: '' };

export default function Clientes() {
  const [f, setF] = useState(VACIO);
  const [err, setErr] = useState({});
  const [aviso, setAviso] = useState(null);
  const [texto, setTexto] = useState('');
  const [lista, setLista] = useState([]);
  const [guardando, setGuardando] = useState(false);

  const cargar = () => api(`/clientes?q=${encodeURIComponent(texto)}`).then(setLista).catch(e => setAviso({ ok: false, msg: e.message }));
  useEffect(() => { cargar(); }, [texto]);
  const cambia = (k) => (e) => setF({ ...f, [k]: e.target.value });

  async function guardar(e) {
    e.preventDefault(); setGuardando(true); setErr({}); setAviso(null);
    try { await api('/clientes', { method: 'POST', body: f }); setF(VACIO); setAviso({ ok: true, msg: 'Cliente registrado.' }); cargar(); }
    catch (ex) { setErr(ex.campos || {}); setAviso({ ok: false, msg: ex.message }); }
    finally { setGuardando(false); }
  }
  const Campo = ({ k, etiqueta, ...r }) => (
    <div className={r.full ? 'sm:col-span-2' : ''}><label className="etiqueta" htmlFor={k}>{etiqueta}</label>
      <input id={k} className="campo" value={f[k]} onChange={cambia(k)} />
      <p className="mt-1 min-h-4 text-xs text-peligro">{err[k]}</p></div>);

  return (
    <>
      {aviso && <div role="status" className={`mb-4 rounded-lg p-3 text-sm font-semibold ${aviso.ok ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'}`}>{aviso.msg}</div>}
      <form onSubmit={guardar} className="tarjeta mb-6" noValidate>
        <div className="border-b border-borde p-4"><h2 className="font-bold">Nuevo cliente</h2><p className="text-xs text-suave">Se crea una persona y su registro de cliente.</p></div>
        <div className="grid gap-x-4 gap-y-1 p-5 sm:grid-cols-2">
          <div><label className="etiqueta" htmlFor="tipo">Tipo de documento</label>
            <select id="tipo" className="campo" value={f.tipo} onChange={cambia('tipo')}>{['CI', 'NIT', 'PAS', 'CEX'].map(t => <option key={t}>{t}</option>)}</select>
            <p className="mt-1 min-h-4 text-xs text-peligro">{err.tipo}</p></div>
          <Campo k="documento" etiqueta="Número de documento" />
          <Campo k="nombre" etiqueta="Nombres" /><Campo k="apellido" etiqueta="Apellidos" />
          <Campo k="correo" etiqueta="Correo" /><Campo k="telefono" etiqueta="Teléfono" />
          <Campo k="nit" etiqueta="NIT (opcional)" /><Campo k="razon_social" etiqueta="Razón social (opcional)" />
          <Campo k="direccion" etiqueta="Dirección" full />
        </div>
        <div className="flex justify-end gap-2 border-t border-borde p-4">
          <button type="button" className="btn btn-ghost" onClick={() => { setF(VACIO); setErr({}); }}>Limpiar</button>
          <button className="btn btn-exito" disabled={guardando}>{guardando ? 'Guardando…' : 'Registrar cliente'}</button>
        </div>
      </form>

      <div className="tarjeta overflow-hidden">
        <div className="border-b border-borde p-4"><input className="campo" placeholder="Buscar por nombre, documento o correo…" value={texto} onChange={e => setTexto(e.target.value)} /></div>
        <div className="overflow-x-auto"><table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-suave"><tr>{['Documento', 'Nombre', 'Correo', 'Teléfono', 'NIT', 'Estado'].map(h => <th key={h} className="px-4 py-3">{h}</th>)}</tr></thead>
          <tbody>{lista.map(c => (
            <tr key={c.id} className="border-t border-borde hover:bg-slate-50"><td className="px-4 py-3 font-bold">{c.documento}</td><td className="px-4 py-3">{c.nombre} {c.apellido}</td>
              <td className="px-4 py-3">{c.correo}</td><td className="px-4 py-3">{c.telefono || '—'}</td><td className="px-4 py-3">{c.nit || '—'}</td>
              <td className="px-4 py-3"><span className="rounded-full bg-emerald-100 px-2.5 py-0.5 text-[11px] font-bold uppercase text-emerald-800">{c.estado}</span></td></tr>))}
            {!lista.length && <tr><td colSpan="6" className="px-4 py-8 text-center text-suave">Sin resultados. Ajusta la búsqueda o registra un cliente nuevo.</td></tr>}
          </tbody></table></div>
      </div>
    </>
  );
}
