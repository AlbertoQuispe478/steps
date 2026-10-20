const { sequelize, QueryTypes } = require("../../config/db");
const { httpError } = require("../../middleware/errorHandler");

const q = (sql, r, t) =>
  sequelize.query(sql, {
    replacements: r,
    type: QueryTypes.SELECT,
    transaction: t,
  });
const run = (sql, r, t) =>
  sequelize.query(sql, { replacements: r, transaction: t });
const bitacora = (t, u, cod, id, det) =>
  run(
    `INSERT INTO bitacora_operacion (id_usuario, id_tipo_operacion, entidad, id_registro, detalle)
   SELECT :u, id_tipo_operacion, 'orden_trabajo', :id, :det FROM tipo_operacion WHERE codigo = :cod`,
    { u, cod, id, det },
    t,
  );

const NIVELES = ["Vacío", "1/4", "1/2", "3/4", "Lleno"];
// Flujo de estados (estado_orden.codigo) y qué roles pueden aplicar cada uno.
const SIGUIENTE = {
  RCB: ["DIA", "ANU"],
  DIA: ["APR", "ANU"],
  APR: ["REP", "ANU"],
  REP: ["FIN", "ANU"],
  FIN: ["ENT", "ANU"],
};
const QUIEN = {
  DIA: ["ADMIN", "RECEP", "MECANICO"],
  APR: ["ADMIN", "RECEP"],
  REP: ["ADMIN", "RECEP", "MECANICO"],
  FIN: ["ADMIN", "RECEP", "MECANICO"],
  ENT: ["ADMIN", "RECEP"],
  ANU: ["ADMIN", "RECEP"],
};
const ESTADO_ID = `(SELECT id_estado_orden FROM estado_orden WHERE codigo = :nuevo)`;

// Datos para los selectores de la pantalla de recepción.
async function opciones() {
  const [clientes, modelos, mecanicos] = await Promise.all([
    q(
      `SELECT c.id_cliente AS id, p.nombre || ' ' || p.apellido AS nombre, p.numero_identificacion AS documento FROM cliente c JOIN persona p USING (id_persona) ORDER BY p.apellido, p.nombre`,
    ),
    q(
      `SELECT m.id_modelo AS id, mv.nombre || ' ' || m.nombre || COALESCE(' ' || m.anio::text, '') AS nombre FROM modelo_vehiculo m JOIN marca_vehiculo mv USING (id_marca) ORDER BY 2`,
    ),
    q(
      `SELECT m.id_mecanico AS id, p.nombre || ' ' || p.apellido AS nombre FROM mecanico m JOIN persona p USING (id_persona) ORDER BY 2`,
    ),
  ]);
  return { clientes, modelos, mecanicos, niveles: NIVELES };
}

// HU-03 · vehículo (se crea o se reutiliza) + orden en estado RCB + historial + bitácora, en una transacción.
async function crear(e, idUsuario) {
  const campos = {};
  const placa = String(e.placa || "")
    .trim()
    .toUpperCase();
  const idCliente = Number(e.idCliente),
    idModelo = Number(e.idModelo),
    km = Number(e.kilometraje);
  const idMecanico = e.idMecanico ? Number(e.idMecanico) : null;
  if (!/^[A-Z0-9-]{4,20}$/.test(placa))
    campos.placa = "Escribe una placa válida (ej. ABC-123).";
  if (!Number.isInteger(idCliente) || idCliente < 1)
    campos.idCliente = "Elige un cliente.";
  if (!Number.isInteger(idModelo) || idModelo < 1)
    campos.idModelo = "Elige marca y modelo.";
  if (!Number.isInteger(km) || km < 0)
    campos.kilometraje = "Escribe el kilometraje de ingreso.";
  if (!NIVELES.includes(e.nivelGasolina))
    campos.nivelGasolina = "Elige el nivel de gasolina.";
  if (Object.keys(campos).length)
    throw httpError(422, "Revisa los campos marcados.", campos);

  try {
    return await sequelize.transaction(async (t) => {
      const [rec] = await q(
        `SELECT r.id_recepcionista AS id FROM recepcionista r JOIN usuario u ON u.id_persona = r.id_persona WHERE u.id_usuario = :u`,
        { u: idUsuario },
        t,
      );
      if (!rec)
        throw httpError(403, "Tu usuario no tiene perfil de recepcionista.");

      let [v] = await q(
        `SELECT id_vehiculo AS id, id_cliente, kilometraje_actual AS km FROM vehiculo WHERE placa = :placa FOR UPDATE`,
        { placa },
        t,
      );
      if (v && v.id_cliente !== idCliente)
        throw httpError(409, "Revisa los campos marcados.", {
          placa: "Esa placa pertenece a otro cliente.",
        });
      if (v && km < v.km)
        throw httpError(422, "Revisa los campos marcados.", {
          kilometraje: `No puede ser menor al último registrado (${v.km}).`,
        });
      if (v)
        await run(
          `UPDATE vehiculo SET kilometraje_actual = :km, updated_at = CURRENT_TIMESTAMP WHERE id_vehiculo = :id`,
          { km, id: v.id },
          t,
        );
      else
        [v] = await q(
          `INSERT INTO vehiculo (id_cliente, id_modelo, placa, kilometraje_actual) VALUES (:idCliente, :idModelo, :placa, :km) RETURNING id_vehiculo AS id`,
          { idCliente, idModelo, placa, km },
          t,
        );

      const [o] = await q(
        `INSERT INTO orden_trabajo (id_vehiculo, id_estado_orden, id_recepcionista, id_mecanico, kilometraje_ingreso, nivel_gasolina, observacion)
         VALUES (:v, (SELECT id_estado_orden FROM estado_orden WHERE codigo = 'RCB'), :r, :m, :km, :n, :ob) RETURNING id_orden_trabajo AS id`,
        {
          v: v.id,
          r: rec.id,
          m: idMecanico,
          km,
          n: e.nivelGasolina,
          ob: String(e.observacion || "").trim() || null,
        },
        t,
      );
      await run(
        `INSERT INTO orden_estado_historial (id_orden_trabajo, id_estado_orden, id_usuario) SELECT :id, id_estado_orden, :u FROM estado_orden WHERE codigo = 'RCB'`,
        { id: o.id, u: idUsuario },
        t,
      );
      await bitacora(t, idUsuario, "ORDEN_CREAR", o.id, `Placa ${placa}`);
      return { id: o.id, codigo: `OT-${o.id}` };
    });
  } catch (err) {
    if (err.name === "SequelizeForeignKeyConstraintError")
      throw httpError(
        422,
        "El cliente, el modelo o el mecánico elegido no existe.",
      );
    throw err;
  }
}

// HU-04 · admin y recepción ven todo; el mecánico solo lo asignado; el cliente solo lo suyo.
async function listar({ sub, roles }, { q: texto = "", estado = "" }) {
  const alcance = roles.some((r) => ["ADMIN", "RECEP"].includes(r))
    ? "todo"
    : roles.includes("MECANICO")
      ? "mecanico"
      : "cliente";
  return q(
    `SELECT o.id_orden_trabajo AS id, 'OT-' || o.id_orden_trabajo AS codigo, mv.nombre || ' ' || mo.nombre || ' · ' || v.placa AS vehiculo,
            pc.nombre || ' ' || pc.apellido AS cliente, COALESCE(pm.nombre || ' ' || pm.apellido, '—') AS mecanico,
            eo.codigo AS estado, eo.nombre AS estado_nombre, o.total, o.fecha_ingreso
     FROM orden_trabajo o JOIN vehiculo v ON v.id_vehiculo = o.id_vehiculo
     JOIN modelo_vehiculo mo ON mo.id_modelo = v.id_modelo JOIN marca_vehiculo mv ON mv.id_marca = mo.id_marca
     JOIN cliente c ON c.id_cliente = v.id_cliente JOIN persona pc ON pc.id_persona = c.id_persona
     JOIN estado_orden eo ON eo.id_estado_orden = o.id_estado_orden
     LEFT JOIN mecanico m ON m.id_mecanico = o.id_mecanico LEFT JOIN persona pm ON pm.id_persona = m.id_persona
     WHERE (:texto = '' OR v.placa ILIKE :like OR pc.nombre ILIKE :like OR pc.apellido ILIKE :like OR ('OT-' || o.id_orden_trabajo) ILIKE :like)
       AND (:estado = '' OR eo.codigo = :estado)
       AND (:alcance = 'todo'
            OR (:alcance = 'mecanico' AND m.id_persona = (SELECT id_persona FROM usuario WHERE id_usuario = :u))
            OR (:alcance = 'cliente' AND c.id_persona = (SELECT id_persona FROM usuario WHERE id_usuario = :u)))
     ORDER BY o.fecha_ingreso DESC, o.id_orden_trabajo DESC LIMIT 200`,
    { texto, like: `%${texto}%`, estado, alcance, u: sub },
  );
}

// HU-04 · cambia el estado respetando el flujo; cierra el período vigente y abre el nuevo (IDIOM composición).
async function cambiarEstado(id, nuevo, observacion, { sub, roles }) {
  return sequelize.transaction(async (t) => {
    const [o] = await q(
      `SELECT o.id_orden_trabajo AS id, eo.codigo AS estado FROM orden_trabajo o JOIN estado_orden eo USING (id_estado_orden) WHERE o.id_orden_trabajo = :id FOR UPDATE OF o`,
      { id },
      t,
    );
    if (!o) throw httpError(404, "La orden no existe.");
    if (!(SIGUIENTE[o.estado] || []).includes(nuevo))
      throw httpError(422, `No se puede pasar de ${o.estado} a ${nuevo}.`);
    if (!(QUIEN[nuevo] || []).some((r) => roles.includes(r)))
      throw httpError(403, "Tu rol no puede aplicar ese estado.");
    await run(
      `UPDATE orden_estado_historial SET fecha_fin = CURRENT_TIMESTAMP WHERE id_orden_trabajo = :id AND fecha_fin IS NULL`,
      { id },
      t,
    );
    await run(
      `INSERT INTO orden_estado_historial (id_orden_trabajo, id_estado_orden, id_usuario, observacion) SELECT :id, id_estado_orden, :u, :ob FROM estado_orden WHERE codigo = :nuevo`,
      { id, u: sub, ob: observacion || null, nuevo },
      t,
    );
    await run(
      `UPDATE orden_trabajo SET id_estado_orden = ${ESTADO_ID}, updated_at = CURRENT_TIMESTAMP,
               fecha_entrega = CASE WHEN :nuevo = 'ENT' THEN CURRENT_TIMESTAMP ELSE fecha_entrega END WHERE id_orden_trabajo = :id`,
      { id, nuevo },
      t,
    );
    await bitacora(
      t,
      sub,
      "ORDEN_CAMBIAR_ESTADO",
      id,
      `${o.estado} -> ${nuevo}`,
    );
    return { id, estado: nuevo };
  });
}
module.exports = { opciones, crear, listar, cambiarEstado };
