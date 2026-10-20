const jwt = require("jsonwebtoken");

// Middleware para verificar que el usuario esté autenticado
function autenticar(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Token no proporcionado." });
  }

  const token = authHeader.split(" ")[1];
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || "secreto");
    req.usuario = payload;
    next();
  } catch (err) {
    return res.status(401).json({ error: "Token inválido o expirado." });
  }
}

// Middleware para verificar que el usuario tenga una función específica
function requiere(funcionRequerida) {
  return (req, res, next) => {
    // El usuario debe estar autenticado primero
    if (!req.usuario || !req.usuario.funciones) {
      return res
        .status(403)
        .json({ error: "Acceso denegado. No autenticado." });
    }

    // Verificar si el usuario tiene la función
    const tienePermiso = req.usuario.funciones.includes(funcionRequerida);
    if (!tienePermiso) {
      return res.status(403).json({
        error: `Permiso necesario: ${funcionRequerida}`,
        funcion: funcionRequerida,
      });
    }

    next();
  };
}

module.exports = { autenticar, requiere };
