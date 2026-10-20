const router = require("express").Router();
const { login } = require("./auth.service");

router.post("/login", async (req, res, next) => {
  try {
    const { username, password } = req.body || {};
    if (!username || !password) {
      return res
        .status(422)
        .json({ error: "Usuario y contraseña son obligatorios." });
    }
    const resultado = await login(username, password);
    res.json(resultado);
  } catch (e) {
    next(e);
  }
});

module.exports = router;
