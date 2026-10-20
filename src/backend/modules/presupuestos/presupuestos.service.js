const { sequelize, QueryTypes } = require("../../config/db");
const { httpError } = require("../../middleware/errorHandler");

const q = (s, r, t) =>
  sequelize.query(s, {
    replacements: r,
    type: QueryTypes.SELECT,
    transaction: t,
  });
const run = (s, r, t) =>
  sequelize.query(s, { replacements: r, transaction: t });
const ATIENDE = ["ADMIN", "RECEP"];
const esDe = (roles, lista) => roles.some((r) => lista.includes(r));
const alcanceDe = (roles) =>
  esDe(roles, ATIENDE)
    ? "todo"
    : roles.includes("MECANICO")
      ? "mecanico"
      : "cliente";
const redondea = (n) => Math.round(n * 100) / 100;
const bit = (t, u, cod, id, det) =>
  run(
    `INSERT INTO bitacora_operacion (id_usuario, id_tipo_operacion, entidad, id_registro, detalle)
   SELECT :u, id_tipo_operacion, 'presupuesto', :id, :det FROM tipo_operacion WHERE codigo = :cod`,
    { u, cod, id, det },
    t,
  );

const PERSONA = `(SELECT id_persona FROM usuario WHERE id_usuario = :u)`;
// Cabecera con el alcance de cada rol: administración/recepción todo, mecánico lo asignado, cliente lo suyo.
const CAB = `SELECT p.id_presupuesto AS id, 'P-' || p.id_presupuesto AS codigo, o.id_orden_trabajo AS id_orden, 'OT-' || o.id_orden_trabajo AS ot,
    pc.nombre || ' ' || pc.apellido AS cliente, mv.nombre || ' ' || mo.nombre || ' · ' || v.placa AS vehiculo,
    p.fecha_creacion, p.monto_total AS total, ep.codigo AS estado, ep.nombre AS estado_nombre, p.observacion
  FROM presupuesto p JOIN estado_presupuesto ep ON ep.id_estado_presupuesto = p.id_estado_presupuesto
  JOIN orden_trabajo o ON o.id_orden_trabajo = p.id_orden_trabajo JOIN vehiculo v ON v.id_vehiculo = o.id_vehiculo
  JOIN modelo_vehiculo mo ON mo.id_modelo = v.id_modelo JOIN marca_vehiculo mv ON mv.id_marca = mo.id_marca
  JOIN cliente c ON c.id_cliente = v.id_cliente JOIN persona pc ON pc.id_persona = c.id_persona
  LEFT JOIN mecanico m ON m.id_mecanico = o.id_mecanico
  WHERE (:alcance = 'todo' OR (:alcance = 'mecanico' AND m.id_persona = ${PERSONA}) OR (:alcance = 'cliente' AND c.id_persona = ${PERSONA}))`;

async function opciones() {
  const [ordenes, servicios, repuestos] = await Promise.all([
    q(`SELECT o.id_orden_trabajo AS id, 'OT-' || o.id_orden_trabajo || ' · ' || v.placa AS nombre FROM orden_trabajo o
       JOIN estado_orden eo ON eo.id_estado_orden = o.id_estado_orden JOIN vehiculo v ON v.id_vehiculo = o.id_vehiculo
       WHERE eo.codigo = 'DIA' AND NOT EXISTS (SELECT 1 FROM presupuesto p JOIN estado_presupuesto ep ON ep.id_estado_presupuesto = p.id_estado_presupuesto
                                               WHERE p.id_orden_trabajo = o.id_orden_trabajo AND ep.codigo IN ('BOR','ENV')) ORDER BY 1 DESC`),
    q(
      `SELECT id_tipo_servicio AS id, nombre, precio_hora AS precio FROM tipo_servicio WHERE activo ORDER BY nombre`,
    ),
    q(
      `SELECT id_repuesto AS id, codigo || ' · ' || nombre AS nombre, precio_venta AS precio FROM repuesto WHERE activo ORDER BY nombre`,
    ),
  ]);
  return { ordenes, servicios, repuestos };
}

const listar = ({ sub, roles }, { q: texto = "", estado = "" }) =>
  q(
    `${CAB} AND (:estado = '' OR ep.codigo = :estado)
   AND (:texto = '' OR ('OT-' || o.id_orden_trabajo) ILIKE :like OR pc.nombre ILIKE :like OR pc.apellido ILIKE :like OR v.placa ILIKE :like)
   ORDER BY p.id_presupuesto DESC LIMIT 200`,
    { alcance: alcanceDe(roles), u: sub, estado, texto, like: `%${texto}%` },
  );

async function detalle(id, { sub, roles }) {
  const [p] = await q(`${CAB} AND p.id_presupuesto = :id`, {
    alcance: alcanceDe(roles),
    u: sub,
    id,
  });
  if (!p) throw httpError(404, "El presupuesto no existe.");
  p.lineas = await q(
    `SELECT id_presupuesto_detalle AS id, descripcion, cantidad, precio_unitario, subtotal FROM presupuesto_detalle WHERE id_presupuesto = :id ORDER BY 1`,
    { id },
  );
  return p;
}

// HU-05 · el servidor toma los precios del catálogo (el cliente HTTP no puede fijarlos) y calcula el total.
async function crear(e, { sub }) {
  const campos = {},
    idOrden = Number(e.idOrden),
    lineas = Array.isArray(e.lineas) ? e.lineas : [];
  if (!Number.isInteger(idOrden) || idOrden < 1)
    campos.idOrden = "Elige una orden.";
  if (!lineas.length || lineas.length > 30)
    campos.lineas = "Agrega al menos un servicio o repuesto (máximo 30).";
  else if (
    lineas.some(
      (l) =>
        !["servicio", "repuesto"].includes(l.tipo) ||
        !(Number(l.id) > 0) ||
        !(Number(l.cantidad) > 0),
    )
  )
    campos.lineas = "Revisa el tipo, el ítem y la cantidad de cada línea.";
  if (Object.keys(campos).length)
    throw httpError(422, "Revisa los campos marcados.", campos);

  return sequelize.transaction(async (t) => {
    const [o] = await q(
      `SELECT o.id_orden_trabajo AS id, eo.codigo AS estado FROM orden_trabajo o JOIN estado_orden eo ON eo.id_estado_orden = o.id_estado_orden WHERE o.id_orden_trabajo = :idOrden FOR UPDATE OF o`,
      { idOrden },
      t,
    );
    if (!o) throw httpError(404, "La orden no existe.");
    if (o.estado !== "DIA")
      throw httpError(422, "Revisa los campos marcados.", {
        idOrden: "La orden debe estar en Diagnóstico.",
      });
    const [activo] = await q(
      `SELECT 1 AS x FROM presupuesto p JOIN estado_presupuesto ep ON ep.id_estado_presupuesto = p.id_estado_presupuesto WHERE p.id_orden_trabajo = :idOrden AND ep.codigo IN ('BOR','ENV')`,
      { idOrden },
      t,
    );
    if (activo)
      throw httpError(409, "Revisa los campos marcados.", {
        idOrden: "Esa orden ya tiene un presupuesto en curso.",
      });

    const ids = (tipo) => [
      ...new Set(
        lineas.filter((l) => l.tipo === tipo).map((l) => Number(l.id)),
      ),
    ];
    const sv = ids("servicio").length
      ? await q(
          `SELECT id_tipo_servicio AS id, nombre, precio_hora AS precio FROM tipo_servicio WHERE activo AND id_tipo_servicio IN (:ids)`,
          { ids: ids("servicio") },
          t,
        )
      : [];
    const rp = ids("repuesto").length
      ? await q(
          `SELECT id_repuesto AS id, nombre, precio_venta AS precio FROM repuesto WHERE activo AND id_repuesto IN (:ids)`,
          { ids: ids("repuesto") },
          t,
        )
      : [];
    const filas = lineas.map((l) => {
      const c = (l.tipo === "servicio" ? sv : rp).find(
        (x) => x.id === Number(l.id),
      );
      if (!c)
        throw httpError(422, "Revisa los campos marcados.", {
          lineas: "Un servicio o repuesto elegido ya no existe.",
        });
      return {
        serv: l.tipo === "servicio" ? c.id : null,
        rep: l.tipo === "repuesto" ? c.id : null,
        desc: c.nombre,
        cant: redondea(Number(l.cantidad)),
        precio: Number(c.precio),
      };
    });
    const total = redondea(filas.reduce((s, f) => s + f.cant * f.precio, 0));
    const [p] = await q(
      `INSERT INTO presupuesto (id_orden_trabajo, id_estado_presupuesto, monto_total, observacion)
      VALUES (:idOrden, (SELECT id_estado_presupuesto FROM estado_presupuesto WHERE codigo = 'BOR'), :total, :ob) RETURNING id_presupuesto AS id`,
      { idOrden, total, ob: String(e.observacion || "").trim() || null },
      t,
    );
    for (const f of filas)
      await run(
        `INSERT INTO presupuesto_detalle (id_presupuesto, id_tipo_servicio, id_repuesto, descripcion, cantidad, precio_unitario) VALUES (:p, :serv, :rep, :desc, :cant, :precio)`,
        { p: p.id, ...f },
        t,
      );
    await bit(
      t,
      sub,
      "PRESUPUESTO_ENVIAR",
      p.id,
      `Borrador de ${filas.length} líneas`,
    );
    return { id: p.id, codigo: `P-${p.id}`, total };
  });
}

// HU-05 · Borrador -> Enviado, y deja la notificación pendiente para el cliente (canal WhatsApp).
const enviar = (id, { sub }) =>
  sequelize.transaction(async (t) => {
    const [p] = await q(
      `SELECT p.id_presupuesto AS id, ep.codigo AS estado, p.monto_total AS total, p.id_orden_trabajo AS orden, c.id_persona AS persona,
      pc.nombre AS cliente, mv.nombre || ' ' || mo.nombre || ' ' || v.placa AS vehiculo
    FROM presupuesto p JOIN estado_presupuesto ep ON ep.id_estado_presupuesto = p.id_estado_presupuesto
    JOIN orden_trabajo o ON o.id_orden_trabajo = p.id_orden_trabajo JOIN vehiculo v ON v.id_vehiculo = o.id_vehiculo
    JOIN modelo_vehiculo mo ON mo.id_modelo = v.id_modelo JOIN marca_vehiculo mv ON mv.id_marca = mo.id_marca
    JOIN cliente c ON c.id_cliente = v.id_cliente JOIN persona pc ON pc.id_persona = c.id_persona WHERE p.id_presupuesto = :id FOR UPDATE OF p`,
      { id },
      t,
    );
    if (!p) throw httpError(404, "El presupuesto no existe.");
    if (p.estado !== "BOR")
      throw httpError(422, "Solo se envía un presupuesto en borrador.");
    const [tn] = await q(
      `SELECT plantilla FROM tipo_notificacion WHERE codigo = 'PRESUP'`,
      {},
      t,
    );
    const mensaje = (tn?.plantilla || "Tu presupuesto es de {monto} Bs.")
      .replace("{cliente}", p.cliente)
      .replace("{vehiculo}", p.vehiculo)
      .replace("{monto}", Number(p.total).toFixed(2));
    await run(
      `UPDATE presupuesto SET id_estado_presupuesto = (SELECT id_estado_presupuesto FROM estado_presupuesto WHERE codigo = 'ENV'), fecha_envio = CURRENT_TIMESTAMP WHERE id_presupuesto = :id`,
      { id },
      t,
    );
    await run(
      `INSERT INTO notificacion (id_tipo_notificacion, id_estado_notificacion, id_persona_destino, id_orden_trabajo, asunto, mensaje, canal)
    SELECT tn.id_tipo_notificacion, (SELECT id_estado_notificacion FROM estado_notificacion WHERE codigo = 'PEN'), :persona, :orden, tn.nombre, :mensaje, 'WHATSAPP'
    FROM tipo_notificacion tn WHERE tn.codigo = 'PRESUP'`,
      { persona: p.persona, orden: p.orden, mensaje },
      t,
    );
    await bit(t, sub, "PRESUPUESTO_ENVIAR", id, "Enviado al cliente");
    return { id, estado: "ENV" };
  });

// HU-06 · el cliente dueño (o administración/recepción en su nombre) aprueba o rechaza.
// Al aprobar: copia las líneas a orden_detalle, fija el total de la orden y la pasa a Aprobado.
const responder = (id, decision, { sub, roles }) =>
  sequelize.transaction(async (t) => {
    if (!["APR", "REC"].includes(decision))
      throw httpError(422, "La decisión debe ser aprobar o rechazar.");
    const [p] = await q(
      `SELECT p.id_presupuesto AS id, ep.codigo AS estado, p.monto_total AS total, p.id_orden_trabajo AS orden, c.id_persona AS persona,
      (SELECT id_persona FROM usuario WHERE id_usuario = :u) AS yo, eo.codigo AS estado_orden
    FROM presupuesto p JOIN estado_presupuesto ep ON ep.id_estado_presupuesto = p.id_estado_presupuesto
    JOIN orden_trabajo o ON o.id_orden_trabajo = p.id_orden_trabajo JOIN estado_orden eo ON eo.id_estado_orden = o.id_estado_orden
    JOIN vehiculo v ON v.id_vehiculo = o.id_vehiculo JOIN cliente c ON c.id_cliente = v.id_cliente
    WHERE p.id_presupuesto = :id FOR UPDATE OF p`,
      { id, u: sub },
      t,
    );
    if (!p) throw httpError(404, "El presupuesto no existe.");
    if (!esDe(roles, ATIENDE) && p.persona !== p.yo)
      throw httpError(
        403,
        "Solo el cliente o recepción pueden responder este presupuesto.",
      );
    if (p.estado !== "ENV")
      throw httpError(422, "El presupuesto no está pendiente de respuesta.");
    if (decision === "APR" && p.estado_orden !== "DIA")
      throw httpError(422, "La orden ya no está en Diagnóstico.");

    await run(
      `UPDATE presupuesto SET id_estado_presupuesto = (SELECT id_estado_presupuesto FROM estado_presupuesto WHERE codigo = :decision), fecha_respuesta = CURRENT_TIMESTAMP WHERE id_presupuesto = :id`,
      { id, decision },
      t,
    );
    if (decision === "APR") {
      await run(
        `INSERT INTO orden_detalle (id_orden_trabajo, id_tipo_servicio, id_repuesto, descripcion, cantidad, precio_unitario)
      SELECT :orden, id_tipo_servicio, id_repuesto, descripcion, cantidad, precio_unitario FROM presupuesto_detalle WHERE id_presupuesto = :id`,
        { orden: p.orden, id },
        t,
      );
      await run(
        `UPDATE orden_estado_historial SET fecha_fin = CURRENT_TIMESTAMP WHERE id_orden_trabajo = :orden AND fecha_fin IS NULL`,
        { orden: p.orden },
        t,
      );
      await run(
        `INSERT INTO orden_estado_historial (id_orden_trabajo, id_estado_orden, id_usuario, observacion) SELECT :orden, id_estado_orden, :u, 'Presupuesto aprobado' FROM estado_orden WHERE codigo = 'APR'`,
        { orden: p.orden, u: sub },
        t,
      );
      await run(
        `UPDATE orden_trabajo SET id_estado_orden = (SELECT id_estado_orden FROM estado_orden WHERE codigo = 'APR'), total = :total, updated_at = CURRENT_TIMESTAMP WHERE id_orden_trabajo = :orden`,
        { orden: p.orden, total: p.total },
        t,
      );
    }
    await bit(
      t,
      sub,
      "PRESUPUESTO_RESPONDER",
      id,
      decision === "APR" ? "Aprobado" : "Rechazado",
    );
    return { id, estado: decision };
  });
module.exports = { opciones, listar, detalle, crear, enviar, responder, esDe };
