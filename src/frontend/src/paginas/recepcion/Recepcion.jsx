import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../../api";

// Componentes fuera de la función para evitar perder el foco
const Campo = ({
  etiqueta,
  k,
  valor,
  onChange,
  err,
  tipo = "text",
  ph = "",
}) => (
  <div>
    <label className="etiqueta" htmlFor={k}>
      {etiqueta}
    </label>
    <input
      id={k}
      type={tipo}
      className="campo"
      placeholder={ph}
      value={valor}
      onChange={onChange}
    />
    <p className="mt-1 min-h-4 text-xs text-peligro">{err}</p>
  </div>
);

const Selector = ({ etiqueta, k, valor, onChange, lista, vacio, err }) => (
  <div>
    <label className="etiqueta" htmlFor={k}>
      {etiqueta}
    </label>
    <select id={k} className="campo" value={valor} onChange={onChange}>
      <option value="">{vacio}</option>
      {lista.map((o) => (
        <option key={o.id ?? o} value={o.id ?? o}>
          {o.nombre ?? o}
        </option>
      ))}
    </select>
    <p className="mt-1 min-h-4 text-xs text-peligro">{err}</p>
  </div>
);

const VACIO = {
  placa: "",
  idCliente: "",
  idModelo: "",
  kilometraje: "",
  nivelGasolina: "",
  idMecanico: "",
  observacion: "",
};

export default function Recepcion() {
  const nav = useNavigate();
  const [op, setOp] = useState({
    clientes: [],
    modelos: [],
    mecanicos: [],
    niveles: [],
  });
  const [f, setF] = useState(VACIO);
  const [err, setErr] = useState({});
  const [aviso, setAviso] = useState("");
  const [enviando, setEnviando] = useState(false);

  useEffect(() => {
    api("/ordenes/opciones")
      .then((data) => {
        setOp(data);
        // Si hay modelos, seleccionar el primero por defecto para facilitar la vida al usuario
        if (data.modelos && data.modelos.length > 0) {
          setF((prev) => ({ ...prev, idModelo: data.modelos[0].id }));
        }
      })
      .catch((e) => setAviso(e.message));
  }, []);

  const cambia = (k) => (e) => setF({ ...f, [k]: e.target.value });

  async function crear(e) {
    e.preventDefault();
    setErr({});
    setAviso("");
    setEnviando(true);
    try {
      await api("/ordenes", { method: "POST", body: f });
      nav("/ordenes");
    } catch (ex) {
      setErr(ex.campos || {});
      setAviso(ex.message);
    } finally {
      setEnviando(false);
    }
  }

  return (
    <form onSubmit={crear} className="tarjeta" noValidate>
      <div className="border-b border-borde p-4">
        <h2 className="font-bold">Nueva orden de trabajo</h2>
        <p className="text-xs text-suave">
          Registra el ingreso del vehículo al taller.
        </p>
      </div>
      {aviso && (
        <div
          role="alert"
          className="m-5 mb-0 rounded-lg bg-red-100 p-3 text-sm font-semibold text-red-800"
        >
          {aviso}
        </div>
      )}
      <div className="grid gap-x-4 gap-y-1 p-5 sm:grid-cols-2">
        <Campo
          k="placa"
          etiqueta="Placa"
          ph="ABC-123"
          valor={f.placa}
          onChange={cambia("placa")}
          err={err.placa}
        />

        <Selector
          k="idCliente"
          etiqueta="Cliente"
          valor={f.idCliente}
          onChange={cambia("idCliente")}
          lista={op.clientes.map((c) => ({
            id: c.id,
            nombre: `${c.nombre} · ${c.documento}`,
          }))}
          vacio="— Elige —"
          err={err.idCliente}
        />

        <Selector
          k="idModelo"
          etiqueta="Marca / modelo"
          valor={f.idModelo}
          onChange={cambia("idModelo")}
          lista={op.modelos}
          vacio="— Elige —"
          err={err.idModelo}
        />

        <Campo
          k="kilometraje"
          etiqueta="Kilometraje de ingreso"
          tipo="number"
          ph="Ej. 45000" // Placeholder en lugar de valor por defecto
          valor={f.kilometraje}
          onChange={cambia("kilometraje")}
          err={err.kilometraje}
        />

        <Selector
          k="nivelGasolina"
          etiqueta="Nivel de gasolina"
          valor={f.nivelGasolina}
          onChange={cambia("nivelGasolina")}
          lista={op.niveles}
          vacio="— Elige —"
          err={err.nivelGasolina}
        />

        <Selector
          k="idMecanico"
          etiqueta="Mecánico (opcional)"
          valor={f.idMecanico}
          onChange={cambia("idMecanico")}
          lista={op.mecanicos}
          vacio="— Sin asignar —"
          err={err.idMecanico}
        />

        <div className="sm:col-span-2">
          <label className="etiqueta" htmlFor="obs">
            Observaciones
          </label>
          <textarea
            id="obs"
            rows="3"
            className="campo"
            placeholder="Problema reportado por el cliente…"
            value={f.observacion}
            onChange={cambia("observacion")}
          />
        </div>
      </div>
      <div className="flex justify-end gap-2 border-t border-borde p-4">
        <button
          type="button"
          className="btn btn-ghost"
          onClick={() => {
            setF(VACIO);
            setErr({});
          }}
        >
          Limpiar
        </button>
        <button className="btn btn-exito" disabled={enviando}>
          {enviando ? "Creando…" : "Crear orden"}
        </button>
      </div>
    </form>
  );
}
