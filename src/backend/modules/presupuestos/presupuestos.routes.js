const router = require("express").Router();
const s = require("./presupuestos.service");
const { autenticar, requiere } = require("../../middleware/auth");
const { httpError } = require("../../middleware/errorHandler");
const ah = (fn) => (req, res, next) => fn(req, res).catch(next);
const staff = (req, _res, next) =>
  s.esDe(req.usuario.roles, ["ADMIN", "RECEP", "MECANICO"])
    ? next()
    : next(httpError(403, "Tu rol no puede gestionar presupuestos."));

router.use(autenticar, requiere("presupuestos"));
router.get(
  "/opciones",
  staff,
  ah(async (_q, res) => res.json(await s.opciones())),
);
router.get(
  "/",
  ah(async (req, res) =>
    res.json(
      await s.listar(req.usuario, {
        q: String(req.query.q || "").trim(),
        estado: String(req.query.estado || ""),
      }),
    ),
  ),
);
router.get(
  "/:id",
  ah(async (req, res) =>
    res.json(await s.detalle(Number(req.params.id), req.usuario)),
  ),
);
router.post(
  "/",
  staff,
  ah(async (req, res) =>
    res.status(201).json(await s.crear(req.body || {}, req.usuario)),
  ),
); // HU-05
router.post(
  "/:id/enviar",
  staff,
  ah(async (req, res) =>
    res.json(await s.enviar(Number(req.params.id), req.usuario)),
  ),
); // HU-05
router.post(
  "/:id/responder",
  ah(async (req, res) =>
    res.json(
      await s.responder(
        Number(req.params.id),
        String(req.body?.decision || ""),
        req.usuario,
      ),
    ),
  ),
); // HU-06
module.exports = router;
