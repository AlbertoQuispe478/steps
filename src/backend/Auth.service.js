const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { sequelize, QueryTypes } = require('../../config/db');
const { httpError } = require('../../middleware/errorHandler');

const MAX_INTENTOS = 5, BLOQUEO_MIN = 5;
const q = (sql, replacements) => sequelize.query(sql, { replacements, type: QueryTypes.SELECT });
const run = (sql, replacements) => sequelize.query(sql, { replacements });

// Hecho de auditoría en bitacora_operacion (catálogo tipo_operacion).
const bitacora = (idUsuario, codigo, detalle) => run(
  `INSERT INTO bitacora_operacion (id_usuario, id_tipo_operacion, entidad, id_registro, detalle)
   SELECT :id, id_tipo_operacion, 'usuario', :id, :detalle FROM tipo_operacion WHERE codigo = :codigo`,
  { id: idUsuario, codigo, detalle });

async function login(username, password) {
  const [u] = await q(
    `SELECT u.id_usuario, u.password_hash, u.intento_fallido, p.nombre, p.apellido, p.activo, eu.codigo AS estado,
            COALESCE(u.bloqueado_hasta > CURRENT_TIMESTAMP, FALSE) AS bloqueado
     FROM usuario u JOIN persona p ON p.id_persona = u.id_persona
     JOIN estado_usuario eu ON eu.id_estado_usuario = p.id_estado_usuario WHERE u.username = :username`, { username });

  if (!u) throw httpError(401, 'Usuario o contraseña incorrectos.');
  if (u.bloqueado) throw httpError(423, `Cuenta bloqueada. Intenta de nuevo en ${BLOQUEO_MIN} minutos.`);
  if (!u.activo || u.estado !== 'ACT') throw httpError(403, 'La cuenta está inactiva.');

  if (!(await bcrypt.compare(password, u.password_hash))) {
    const fallos = u.intento_fallido + 1;
    if (fallos >= MAX_INTENTOS) {
      await run(`UPDATE usuario SET intento_fallido = 0, bloqueado_hasta = CURRENT_TIMESTAMP + make_interval(mins => :m) WHERE id_usuario = :id`, { m: BLOQUEO_MIN, id: u.id_usuario });
      await bitacora(u.id_usuario, 'AUTH_BLOQUEO', `${MAX_INTENTOS} intentos fallidos`);
      throw httpError(423, `Demasiados intentos. Cuenta bloqueada ${BLOQUEO_MIN} minutos.`);
    }
    await run(`UPDATE usuario SET intento_fallido = :f WHERE id_usuario = :id`, { f: fallos, id: u.id_usuario });
    await bitacora(u.id_usuario, 'AUTH_LOGIN_FALLIDO', `Intento ${fallos}`);
    throw httpError(401, `Usuario o contraseña incorrectos. Te quedan ${MAX_INTENTOS - fallos} intentos.`);
  }

  // Roles vigentes (composición histórica) y funciones permitidas.
  const permisos = await q(
    `SELECT DISTINCT r.codigo AS rol, f.codigo AS funcion
     FROM usuario_rol_asignacion a
     JOIN estado_asignacion ea ON ea.id_estado_asignacion = a.id_estado_asignacion AND ea.codigo = 'VIG'
     JOIN rol r ON r.id_rol = a.id_rol AND r.activo
     LEFT JOIN rol_funcion rf ON rf.id_rol = r.id_rol
     LEFT JOIN funcion f ON f.id_funcion = rf.id_funcion AND f.activo
     WHERE a.id_usuario = :id AND (a.fecha_fin IS NULL OR a.fecha_fin > CURRENT_TIMESTAMP)`, { id: u.id_usuario });
  if (!permisos.length) throw httpError(403, 'Tu cuenta no tiene un rol vigente.');

  await run(`UPDATE usuario SET intento_fallido = 0, bloqueado_hasta = NULL, ultimo_acceso = CURRENT_TIMESTAMP WHERE id_usuario = :id`, { id: u.id_usuario });
  await bitacora(u.id_usuario, 'AUTH_LOGIN', 'Inicio de sesión');

  const roles = [...new Set(permisos.map(p => p.rol))];
  const funciones = [...new Set(permisos.map(p => p.funcion).filter(Boolean))];
  const token = jwt.sign({ sub: u.id_usuario, roles, funciones }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES || '8h' });
  return { token, usuario: { id: u.id_usuario, nombre: `${u.nombre} ${u.apellido}`, roles, funciones } };
}
module.exports = { login };