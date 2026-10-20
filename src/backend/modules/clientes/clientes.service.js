const { sequelize, QueryTypes } = require("../../config/db");
const { httpError } = require("../../middleware/errorHandler");

const EMAIL = /^\S+@\S+\.\S+$/;
const MAX = {
  documento: 20,
  nombre: 100,
  apellido: 100,
  correo: 100,
  telefono: 20,
  nit: 20,
  razon_social: 150,
};
const q = (sql, replacements, transaction) =>
  sequelize.query(sql, { replacements, type: QueryTypes.SELECT, transaction });

// Normaliza (trim, vacío -> null) y valida. Devuelve { datos, campos } con un mensaje por campo.
function validar(entrada) {
  const campos = {},
    datos = {};
  for (const k of [
    "tipo",
    "documento",
    "nombre",
    "apellido",
    "correo",
    "telefono",
    "direccion",
    "nit",
    "razon_social",
  ])
    datos[k] = (entrada[k] ?? "").toString().trim() || null;
  if (!datos.tipo) campos.tipo = "Elige el tipo de documento.";
  if (!datos.documento) campos.documento = "Escribe el número de documento.";
  if (!datos.nombre) campos.nombre = "Escribe los nombres.";
  if (!datos.apellido) campos.apellido = "Escribe los apellidos.";
  if (!datos.correo || !EMAIL.test(datos.correo))
    campos.correo = "Escribe un correo válido.";
  for (const [k, max] of Object.entries(MAX))
    if (datos[k] && datos[k].length > max && !campos[k])
      campos[k] = `Máximo ${max} caracteres.`;
  return { datos, campos };
}

// HU-02 · crea persona + cliente (IS-A) y asienta la bitácora, todo en una transacción.
async function registrar(entrada, idUsuario) {
  const { datos, campos } = validar(entrada);
  if (datos.tipo && !campos.tipo) {
    const [t] = await q(
      `SELECT id_tipo_identificacion AS id FROM tipo_identificacion WHERE codigo = :tipo AND activo`,
      datos,
    );
    if (!t) campos.tipo = "Tipo de documento no válido.";
    else datos.tipoId = t.id;
  }
  if (Object.keys(campos).length)
    throw httpError(422, "Revisa los campos marcados.", campos);

  const dup = await q(
    `SELECT numero_identificacion = :documento AS por_doc, lower(email) = lower(:correo) AS por_correo
                       FROM persona WHERE numero_identificacion = :documento OR lower(email) = lower(:correo)`,
    datos,
  );
  if (dup.some((d) => d.por_doc))
    campos.documento = "Ya existe una persona con ese documento.";
  if (dup.some((d) => d.por_correo))
    campos.correo = "Ese correo ya está registrado.";
  if (Object.keys(campos).length)
    throw httpError(409, "Revisa los campos marcados.", campos);

  try {
    return await sequelize.transaction(async (t) => {
      const [p] = await q(
        `INSERT INTO persona (id_tipo_identificacion, numero_identificacion, nombre, apellido, email, telefono, direccion, id_estado_usuario)
         VALUES (:tipoId, :documento, :nombre, :apellido, lower(:correo), :telefono, :direccion, (SELECT id_estado_usuario FROM estado_usuario WHERE codigo = 'ACT'))
         RETURNING id_persona`,
        datos,
        t,
      );
      const [c] = await q(
        `INSERT INTO cliente (id_persona, nit, razon_social) VALUES (:id, :nit, :razon_social) RETURNING id_cliente`,
        { id: p.id_persona, nit: datos.nit, razon_social: datos.razon_social },
        t,
      );
      await sequelize.query(
        `INSERT INTO bitacora_operacion (id_usuario, id_tipo_operacion, entidad, id_registro, detalle)
         SELECT :u, id_tipo_operacion, 'cliente', :c, :d FROM tipo_operacion WHERE codigo = 'CLIENTE_REGISTRAR'`,
        {
          replacements: {
            u: idUsuario,
            c: c.id_cliente,
            d: `${datos.nombre} ${datos.apellido}`,
          },
          transaction: t,
        },
      );
      return { id: c.id_cliente, idPersona: p.id_persona };
    });
  } catch (e) {
    // dos registros simultáneos: la restricción UNIQUE de la BD es la garantía final
    if (e.name === "SequelizeUniqueConstraintError")
      throw httpError(409, "El documento o el correo ya están registrados.");
    throw e;
  }
}

async function listar(texto = "") {
  return q(
    `SELECT c.id_cliente AS id, p.numero_identificacion AS documento, p.nombre, p.apellido, p.email AS correo,
                   p.telefono, c.nit, eu.nombre AS estado
            FROM cliente c JOIN persona p ON p.id_persona = c.id_persona
            JOIN estado_usuario eu ON eu.id_estado_usuario = p.id_estado_usuario
            WHERE :texto = '' OR p.nombre ILIKE :like OR p.apellido ILIKE :like OR p.numero_identificacion ILIKE :like OR p.email ILIKE :like
            ORDER BY c.created_at DESC LIMIT 200`,
    { texto, like: `%${texto}%` },
  );
}
module.exports = { registrar, listar };
