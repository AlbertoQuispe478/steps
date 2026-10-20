import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api";
import { useAuth } from "../../auth/AuthContext";

// HU-04 · BD: orden_trabajo, estado_orden, orden_estado_historial, vehiculo, cliente, mecanico
const ESTADOS = {
  RCB: "Recibido",
  DIA: "Diagnóstico",
  APR: "Aprobado",
  REP: "En reparación",
  FIN: "Finalizado",
  ENT: "Entregado",
  ANU: "Anulado",
};
const SIGUIENTE = {
  RCB: ["DIA", "ANU"],
  DIA: ["APR", "ANU"],
  APR: ["REP", "ANU"],
  REP: ["FIN", "ANU"],
  FIN: ["ENT", "ANU"],
};
const COLOR = {
  RCB: "bg-blue-100 text-blue-800",
  DIA: "bg-violet-100 text-violet-800",
  APR: "bg-emerald-100 text-emerald-800",
  REP: "bg-amber-100 text-amber-800",
  FIN: "bg-emerald-100 text-emerald-800",
  ENT: "bg-gray-200 text-gray-700",
  ANU: "bg-red-100 text-red-800",
};

export default function Ordenes() {
  const { usuario, tiene } = useAuth();
  const [lista, setLista] = useState([]);
  const [texto, setTexto] = useState("");
  const [estado, setEstado] = useState("");
  const [aviso, setAviso] = useState(null);
  const puedeCambiar = usuario.roles.some((r) =>
    ["ADMIN", "RECEP", "MECANICO"].includes(r),
  );

  const cargar = () =>
    api(`/ordenes?q=${encodeURIComponent(texto)}&estado=${estado}`)
      .then(setLista)
      .catch((e) => setAviso(e.message));
  useEffect(() => {
    cargar();
  }, [texto, estado]);

  async function mover(id, nuevo) {
    if (
      nuevo === "ANU" &&
      !confirm("¿Anular la orden? Esta acción no se puede deshacer.")
    )
      return;
    setAviso(null);
    try {
      await api(`/ordenes/${id}/estado`, {
        method: "PATCH",
        body: { estado: nuevo },
      });
      cargar();
    } catch (e) {
      setAviso(e.message);
    }
  }
  return (
    <div className="tarjeta overflow-hidden">
      <div className="flex flex-wrap items-center gap-2 border-b border-borde p-4">
        <input
          className="campo flex-1"
          placeholder="Buscar por placa, cliente o # orden…"
          value={texto}
          onChange={(e) => setTexto(e.target.value)}
        />
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
        {tiene("recepcion") && (
          <Link to="/recepcion" className="btn">
            + Nueva orden
          </Link>
        )}
      </div>
      {aviso && (
        <div
          role="alert"
          className="m-4 rounded-lg bg-red-100 p-3 text-sm font-semibold text-red-800"
        >
          {aviso}
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-suave">
            <tr>
              {[
                "# Orden",
                "Vehículo",
                "Cliente",
                "Mecánico",
                "Estado",
                "Total",
                puedeCambiar ? "Acción" : "",
              ].map((h) => (
                <th key={h} className="px-4 py-3">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {lista.map((o) => (
              <tr
                key={o.id}
                className="border-t border-borde hover:bg-slate-50"
              >
                <td className="px-4 py-3 font-bold">{o.codigo}</td>
                <td className="px-4 py-3">{o.vehiculo}</td>
                <td className="px-4 py-3">{o.cliente}</td>
                <td className="px-4 py-3">{o.mecanico}</td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold uppercase ${COLOR[o.estado]}`}
                  >
                    {o.estado_nombre}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {Number(o.total) > 0
                    ? `Bs. ${Number(o.total).toLocaleString("es-BO")}`
                    : "—"}
                </td>
                <td className="flex flex-wrap gap-1 px-4 py-3">
                  {puedeCambiar &&
                    (SIGUIENTE[o.estado] || []).map((n) => (
                      <button
                        key={n}
                        className={`btn btn-sm ${n === "ANU" ? "btn-peligro" : "btn-ghost"}`}
                        onClick={() => mover(o.id, n)}
                      >
                        {n === "ANU" ? "Anular" : `→ ${ESTADOS[n]}`}
                      </button>
                    ))}
                </td>
              </tr>
            ))}
            {!lista.length && (
              <tr>
                <td colSpan="7" className="px-4 py-8 text-center text-suave">
                  No hay órdenes con ese filtro.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
