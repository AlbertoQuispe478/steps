// src/backend/middleware/errorHandler.js

const logger = require("../utils/logger");

// Error con código HTTP; "campos" opcional indica qué campo del formulario falló.
function httpError(status, message, campos) {
  const e = new Error(message);
  e.status = status;
  e.campos = campos;
  return e;
}

function errorHandler(err, _req, res, _next) {
  const status = err.status || 500;

  // Usamos el logger (Winston) en lugar de console.error para evitar el warning de ESLint
  if (status === 500) {
    logger.error(err);
  }

  res.status(status).json({
    error: status === 500 ? "Error interno del servidor." : err.message,
    ...(err.campos ? { campos: err.campos } : {}),
  });
}

module.exports = { httpError, errorHandler };
