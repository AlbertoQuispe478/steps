const router = require("express").Router();
const s = require("./ordenes.service");
const { autenticar, requiere } = require("../../middleware/auth");
const wrap = (fn) => (req, res, next) => fn(req, res).catch(next);

router.use(autenticar);
router.get(
  "/opciones",
  requiere("recepcion"),
  wrap(async (_q, res) => res.json(await s.opciones())),
); // HU-03
router.post(
  "/",
  requiere("recepcion"),
  wrap(async (req, res) =>
    res.status(201).json(await s.crear(req.body || {}, req.usuario.sub)),
  ),
); // HU-03
router.get(
  "/",
  requiere("ordenes"),
  wrap(async (req, res) =>
    res.json(
      await s.listar(req.usuario, {
        q: String(req.query.q || "").trim(),
        estado: String(req.query.estado || ""),
      }),
    ),
  ),
); // HU-04
router.patch(
  "/:id/estado",
  requiere("ordenes"),
  wrap(async (req, res) =>
    res.json(
      await s.cambiarEstado(
        Number(req.params.id),
        String(req.body?.estado || ""),
        req.body?.observacion,
        req.usuario,
      ),
    ),
  ),
); // HU-04
module.exports = router;
