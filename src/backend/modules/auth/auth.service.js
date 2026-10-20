const { sequelize, QueryTypes } = require("../../config/db");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { httpError } = require("../../middleware/errorHandler");

// Busca al usuario y verifica la contraseña
async function login(username, password) {
  // 1. Buscar usuario y sus datos de persona
  const [usuario] = await sequelize.query(
    `SELECT u.id_usuario, u.password_hash, u.intento_fallido, u.bloqueado_hasta, p.nombre, p.apellido
     FROM usuario u
     JOIN persona p ON p.id_persona = u.id_persona
     WHERE u.username = :username`,
    { replacements: { username }, type: QueryTypes.SELECT },
  );

  if (!usuario) throw httpError(401, "Credenciales incorrectas.");

  // 2. Verificar bloqueo
  if (
    usuario.bloqueado_hasta &&
    new Date(usuario.bloqueado_hasta) > new Date()
  ) {
    throw httpError(
      423,
      "Cuenta bloqueada temporalmente por intentos fallidos.",
    );
  }

  // 3. Verificar contraseña
  const valida = await bcrypt.compare(password, usuario.password_hash);
  if (!valida) {
    // Registrar intento fallido
    const intentos = usuario.intento_fallido + 1;
    let bloqueadoHasta = null;
    if (intentos >= 5) {
      bloqueadoHasta = new Date();
      bloqueadoHasta.setMinutes(bloqueadoHasta.getMinutes() + 5);
    }
    await sequelize.query(
      `UPDATE usuario SET intento_fallido = :intentos, bloqueado_hasta = :bloqueadoHasta WHERE id_usuario = :id`,
      { replacements: { intentos, bloqueadoHasta, id: usuario.id_usuario } },
    );
    throw httpError(401, "Credenciales incorrectas.");
  }

  // 4. Login exitoso: resetear intentos y obtener roles/funciones
  await sequelize.query(
    `UPDATE usuario SET intento_fallido = 0, bloqueado_hasta = NULL, ultimo_acceso = CURRENT_TIMESTAMP WHERE id_usuario = :id`,
    { replacements: { id: usuario.id_usuario } },
  );

  const roles = await sequelize.query(
    `SELECT r.codigo FROM usuario_rol_asignacion ura
     JOIN rol r ON r.id_rol = ura.id_rol
     WHERE ura.id_usuario = :id AND ura.fecha_fin IS NULL`,
    { replacements: { id: usuario.id_usuario }, type: QueryTypes.SELECT },
  );

  const funciones = await sequelize.query(
    `SELECT DISTINCT f.codigo FROM usuario_rol_asignacion ura
     JOIN rol_funcion rf ON rf.id_rol = ura.id_rol
     JOIN funcion f ON f.id_funcion = rf.id_funcion
     WHERE ura.id_usuario = :id AND ura.fecha_fin IS NULL`,
    { replacements: { id: usuario.id_usuario }, type: QueryTypes.SELECT },
  );

  // 5. Generar Token
  const payload = {
    sub: usuario.id_usuario,
    nombre: `${usuario.nombre} ${usuario.apellido}`,
    roles: roles.map((r) => r.codigo),
    funciones: funciones.map((f) => f.codigo),
  };

  const token = jwt.sign(payload, process.env.JWT_SECRET || "secreto", {
    expiresIn: "8h",
  });

  return {
    token,
    usuario: {
      id: usuario.id_usuario,
      nombre: payload.nombre,
      roles: payload.roles,
      funciones: payload.funciones,
    },
  };
}

module.exports = { login };
