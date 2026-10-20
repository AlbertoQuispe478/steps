import { useEffect, useState } from "react";
import { api } from "../../api";
import { useAuth } from "../../auth/AuthContext";

// HU-05/06 · BD: presupuesto, presupuesto_detalle, estado_presupuesto, orden_trabajo, notificacion
const COLOR = {
  BOR: "bg-gray-200 text-gray-700",
  ENV: "bg-blue-100 text-blue-800",
  APR: "bg-emerald-100 text-emerald-800",
  REC: "bg-red-100 text-red-800",
  VEN: "bg-amber-100 text-amber-800",
};
const ESTADOS = {
  BOR: "Borrador",
  ENV: "Enviado",
  APR: "Aprobado",
  REC: "Rechazado",
  VEN: "Vencido",
};
const bs = (n) =>
  `Bs. ${Number(n).toLocaleString("es-BO", { minimumFractionDigits: 2 })}`;

function Nuevo({ alCrear }) {
  const [op, setOp] = useState({ ordenes: [], servicios: [], repuestos: [] });
  const [f, setF] = useState({ idOrden: "", observacion: "" });
  const [lineas, setLineas] = useState([]);
  const [it, setIt] = useState({ tipo: "servicio", id: "", cantidad: 1 });
  const [err, setErr] = useState({});
  useEffect(() => {
    api("/presupuestos/opciones").then(setOp);
  }, []);
  const catalogo = it.tipo === "servicio" ? op.servicios : op.repuestos;
  const total = lineas.reduce((s, l) => s + l.cantidad * l.precio, 0);

  function agregar() {
    const c = catalogo.find((x) => String(x.id) === String(it.id));
    if (!c || !(Number(it.cantidad) > 0))
      return setErr({ lineas: "Elige un ítem y una cantidad mayor a 0." });
    setErr({});
    setLineas([
      ...lineas,
      {
        tipo: it.tipo,
        id: c.id,
        nombre: c.nombre,
        precio: Number(c.precio),
        cantidad: Number(it.cantidad),
      },
    ]);
  }
  async function guardar(e) {
    e.preventDefault();
    setErr({});
    try {
      await api("/presupuestos", {
        method: "POST",
        body: {
          ...f,
          lineas: lineas.map(({ tipo, id, cantidad }) => ({
            tipo,
            id,
            cantidad,
          })),
        },
      });
      alCrear();
    } catch (ex) {
      setErr(ex.campos || { lineas: ex.message });
    }
  }
  return (
    <form onSubmit={guardar} className="tarjeta mb-6" noValidate>
      <div className="border-b border-borde p-4">
        <h2 className="font-bold">Nuevo presupuesto</h2>
        <p className="text-xs text-suave">
          Solo órdenes en Diagnóstico. Los precios salen del catálogo.
        </p>
      </div>
      <div className="grid gap-4 p-5 sm:grid-cols-2">
        <div>
          <label className="etiqueta" htmlFor="orden">
            Orden
          </label>
          <select
            id="orden"
            className="campo"
            value={f.idOrden}
            onChange={(e) => setF({ ...f, idOrden: e.target.value })}
          >
            <option value="">— Elige —</option>
            {op.ordenes.map((o) => (
              <option key={o.id} value={o.id}>
                {o.nombre}
              </option>
            ))}
          </select>
          <p className="mt-1 min-h-4 text-xs text-peligro">{err.idOrden}</p>
        </div>
        <div>
          <label className="etiqueta" htmlFor="obs">
            Observación
          </label>
          <input
            id="obs"
            className="campo"
            value={f.observacion}
            onChange={(e) => setF({ ...f, observacion: e.target.value })}
          />
        </div>
        <div className="flex flex-wrap items-end gap-2 sm:col-span-2">
          <div>
            <label className="etiqueta">Tipo</label>
            <select
              className="campo"
              value={it.tipo}
              onChange={(e) =>
                setIt({ tipo: e.target.value, id: "", cantidad: 1 })
              }
            >
              <option value="servicio">Servicio (horas)</option>
              <option value="repuesto">Repuesto</option>
            </select>
          </div>
          <div className="min-w-40 flex-1">
            <label className="etiqueta">Ítem</label>
            <select
              className="campo"
              value={it.id}
              onChange={(e) => setIt({ ...it, id: e.target.value })}
            >
              <option value="">— Elige —</option>
              {catalogo.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.nombre} · {bs(c.precio)}
                </option>
              ))}
            </select>
          </div>
          <div className="w-24">
            <label className="etiqueta">Cant.</label>
            <input
              type="number"
              min="0.5"
              step="0.5"
              className="campo"
              value={it.cantidad}
              onChange={(e) => setIt({ ...it, cantidad: e.target.value })}
            />
          </div>
          <button type="button" className="btn btn-ghost" onClick={agregar}>
            + Agregar
          </button>
        </div>
        <p className="min-h-4 text-xs text-peligro sm:col-span-2">
          {err.lineas}
        </p>
        <div className="overflow-x-auto sm:col-span-2">
          <table className="w-full text-sm">
            <tbody>
              {lineas.map((l, i) => (
                <tr key={i} className="border-t border-borde">
                  <td className="py-2">{l.nombre}</td>
                  <td>
                    {l.cantidad} × {bs(l.precio)}
                  </td>
                  <td className="text-right font-semibold">
                    {bs(l.cantidad * l.precio)}
                  </td>
                  <td className="w-10 text-right">
                    <button
                      type="button"
                      aria-label="Quitar"
                      className="text-peligro"
                      onClick={() =>
                        setLineas(lineas.filter((_, j) => j !== i))
                      }
                    >
                      ✕
                    </button>
                  </td>
                </tr>
              ))}
              {lineas.length > 0 && (
                <tr className="border-t-2 border-borde font-extrabold">
                  <td className="py-2" colSpan="2">
                    Total estimado
                  </td>
                  <td className="text-right">{bs(total)}</td>
                  <td />
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      <div className="flex justify-end border-t border-borde p-4">
        <button className="btn btn-exito">Guardar borrador</button>
      </div>
    </form>
  );
}

export default function Presupuestos() {
  const { usuario } = useAuth();
  const roles = usuario.roles;
  const staff = roles.some((r) => ["ADMIN", "RECEP", "MECANICO"].includes(r));
  const puedeResponder = roles.some((r) =>
    ["ADMIN", "RECEP", "CLIENTE"].includes(r),
  );
  const [lista, setLista] = useState([]);
  const [estado, setEstado] = useState("");
  const [sel, setSel] = useState(null);
  const [aviso, setAviso] = useState(null);
  const [nuevo, setNuevo] = useState(false);
  const cargar = () =>
    api(`/presupuestos?estado=${estado}`)
      .then(setLista)
      .catch((e) => setAviso({ ok: false, msg: e.message }));
  const ver = (id) =>
    api(`/presupuestos/${id}`)
      .then(setSel)
      .catch((e) => setAviso({ ok: false, msg: e.message }));
  useEffect(() => {
    cargar();
  }, [estado]);

  async function accion(ruta, cuerpo, ok) {
    setAviso(null);
    try {
      await api(ruta, { method: "POST", body: cuerpo });
      setAviso({ ok: true, msg: ok });
      await cargar();
      if (sel) ver(sel.id);
    } catch (e) {
      setAviso({ ok: false, msg: e.message });
    }
  }
  return (
    <>
      {aviso && (
        <div
          role="status"
          className={`mb-4 rounded-lg p-3 text-sm font-semibold ${aviso.ok ? "bg-emerald-100 text-emerald-800" : "bg-red-100 text-red-800"}`}
        >
          {aviso.msg}
        </div>
      )}
      {nuevo && (
        <Nuevo
          alCrear={() => {
            setNuevo(false);
            setAviso({ ok: true, msg: "Borrador guardado." });
            cargar();
          }}
        />
      )}
      <div className="tarjeta mb-6 overflow-hidden">
        <div className="flex flex-wrap items-center gap-2 border-b border-borde p-4">
          <select
            className="campo w-auto"
            value={estado}
            onChange={(e) => setEstado(e.target.value)}
          >
            <option value="">Todos los estados</option>
            {Object.entries(ESTADOS).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
          {staff && (
            <button className="btn ml-auto" onClick={() => setNuevo(!nuevo)}>
              {nuevo ? "Cerrar" : "+ Nuevo presupuesto"}
            </button>
          )}
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-suave">
              <tr>
                {[
                  "# Presup.",
                  "Orden",
                  "Cliente",
                  "Vehículo",
                  "Monto",
                  "Estado",
                  "",
                ].map((h) => (
                  <th key={h} className="px-4 py-3">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {lista.map((p) => (
                <tr
                  key={p.id}
                  className="border-t border-borde hover:bg-slate-50"
                >
                  <td className="px-4 py-3 font-bold">{p.codigo}</td>
                  <td className="px-4 py-3">{p.ot}</td>
                  <td className="px-4 py-3">{p.cliente}</td>
                  <td className="px-4 py-3">{p.vehiculo}</td>
                  <td className="px-4 py-3">{bs(p.total)}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold uppercase ${COLOR[p.estado]}`}
                    >
                      {p.estado_nombre}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      className="btn btn-ghost btn-sm"
                      onClick={() => ver(p.id)}
                    >
                      Ver
                    </button>
                  </td>
                </tr>
              ))}
              {!lista.length && (
                <tr>
                  <td colSpan="7" className="px-4 py-8 text-center text-suave">
                    No hay presupuestos con ese filtro.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      {sel && (
        <div className="tarjeta">
          <div className="flex flex-wrap items-center justify-between gap-2 border-b border-borde p-4">
            <div>
              <h2 className="font-bold">
                Presupuesto {sel.codigo} · {sel.ot}
              </h2>
              <p className="text-xs text-suave">
                {sel.cliente} · {sel.vehiculo}
              </p>
            </div>
            <span
              className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold uppercase ${COLOR[sel.estado]}`}
            >
              {sel.estado_nombre}
            </span>
          </div>
          {sel.lineas.map((l) => (
            <div
              key={l.id}
              className="flex justify-between gap-4 border-b border-borde px-5 py-3 text-sm"
            >
              <span>
                {l.descripcion}{" "}
                <span className="text-suave">
                  ({Number(l.cantidad)} × {bs(l.precio_unitario)})
                </span>
              </span>
              <span>{bs(l.subtotal)}</span>
            </div>
          ))}
          <div className="flex justify-between bg-slate-50 px-5 py-4 font-extrabold">
            <span>Total</span>
            <span>{bs(sel.total)}</span>
          </div>
          <div className="flex flex-wrap gap-2 p-4">
            {sel.estado === "BOR" && staff && (
              <button
                className="btn"
                onClick={() =>
                  accion(
                    `/presupuestos/${sel.id}/enviar`,
                    undefined,
                    "Enviado al cliente.",
                  )
                }
              >
                Enviar al cliente
              </button>
            )}
            {sel.estado === "ENV" && puedeResponder && (
              <>
                <button
                  className="btn btn-exito flex-1"
                  onClick={() =>
                    accion(
                      `/presupuestos/${sel.id}/responder`,
                      { decision: "APR" },
                      "Presupuesto aprobado.",
                    )
                  }
                >
                  Aprobar
                </button>
                <button
                  className="btn btn-peligro flex-1"
                  onClick={() =>
                    confirm("¿Rechazar el presupuesto?") &&
                    accion(
                      `/presupuestos/${sel.id}/responder`,
                      { decision: "REC" },
                      "Presupuesto rechazado.",
                    )
                  }
                >
                  Rechazar
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}
