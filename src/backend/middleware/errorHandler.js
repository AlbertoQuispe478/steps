// Error con código HTTP; "campos" opcional indica qué campo del formulario falló.
function httpError(status, message, campos) { const e = new Error(message); e.status = status; e.campos = campos; return e; }

function errorHandler(err, _req, res, _next) {
  const status = err.status || 500;
  if (status === 500) console.error(err);
  res.status(status).json({ error: status === 500 ? 'Error interno del servidor.' : err.message, ...(err.campos ? { campos: err.campos } : {}) });
}
module.exports = { httpError, errorHandler };
