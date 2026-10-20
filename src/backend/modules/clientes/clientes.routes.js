const router = require("express").Router();
const { registrar, listar } = require("./clientes.service");
const { autenticar, requiere } = require("../../middleware/auth");

router.use(autenticar, requiere("clientes"));
router.get("/", async (req, res, next) => {
  try {
    res.json(await listar(String(req.query.q || "").trim()));
  } catch (e) {
    next(e);
  }
});
router.post("/", async (req, res, next) => {
  try {
    res.status(201).json(await registrar(req.body || {}, req.usuario.sub));
  } catch (e) {
    next(e);
  }
});
module.exports = router;
