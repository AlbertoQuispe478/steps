require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { autenticar, requiere } = require("./middleware/auth");
const { errorHandler } = require("./middleware/errorHandler");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/api/health", (_req, res) => res.json({ ok: true }));
app.use("/api/auth", require("./modules/auth/auth.routes"));
app.use("/api/clientes", require("./modules/clientes/clientes.routes"));
app.use("/api/ordenes", require("./modules/ordenes/ordenes.routes"));
// Ruta de prueba del RBAC; se reemplaza cuando exista el módulo de reportes (HU-10).
app.get("/api/reportes/ping", autenticar, requiere("reportes"), (_req, res) =>
  res.json({ ok: true }),
);

app.use(errorHandler);
module.exports = app;
