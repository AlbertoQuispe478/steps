// Una prueba por criterio de aceptación de HU-02. Requiere BD con 04_funcion_clientes.sql aplicado.
const { test, before, after } = require("node:test");
const assert = require("node:assert");
const request = require("supertest");
const app = require("../../src/backend/app");
const { sequelize } = require("../../src/backend/config/db");

const sufijo = Date.now();
const nuevo = (o = {}) => ({
  tipo: "CI",
  documento: `T${sufijo}`,
  nombre: "Prueba",
  apellido: "Cliente",
  correo: `test-${sufijo}@steps.test`,
  ...o,
});
let tokenRecep, tokenMec;
const entrar = async (u, p) =>
  (
    await request(app)
      .post("/api/auth/login")
      .send({ username: u, password: p })
  ).body.token;
const post = (token, cuerpo) =>
  request(app)
    .post("/api/clientes")
    .set("Authorization", `Bearer ${token}`)
    .send(cuerpo);

before(async () => {
  await sequelize.query(
    `UPDATE usuario SET intento_fallido = 0, bloqueado_hasta = NULL`,
  );
  tokenRecep = await entrar("crios", "Recep12345");
  tokenMec = await entrar("lperez", "Mecanico12345");
});
after(async () => {
  await sequelize.query(
    `DELETE FROM persona WHERE email LIKE 'test-%@steps.test'`,
  );
  await sequelize.close();
});

test("CA-01 registra persona y cliente con estado activo", async () => {
  const r = await post(
    tokenRecep,
    nuevo({ nit: "123", razon_social: "Prueba SRL" }),
  );
  assert.equal(r.status, 201);
  const [[c]] = await sequelize.query(
    `SELECT c.nit, eu.codigo AS estado FROM cliente c JOIN persona p USING (id_persona) JOIN estado_usuario eu USING (id_estado_usuario) WHERE c.id_cliente = ${r.body.id}`,
  );
  assert.equal(c.nit, "123");
  assert.equal(c.estado, "ACT");
});
test("CA-02 rechaza documento repetido (409)", async () => {
  const r = await post(
    tokenRecep,
    nuevo({ correo: `test-otro-${sufijo}@steps.test` }),
  );
  assert.equal(r.status, 409);
  assert.ok(r.body.campos.documento);
});
test("CA-03 rechaza correo repetido aunque cambie la capitalización", async () => {
  const r = await post(
    tokenRecep,
    nuevo({ documento: `T2${sufijo}`, correo: `TEST-${sufijo}@steps.test` }),
  );
  assert.equal(r.status, 409);
  assert.ok(r.body.campos.correo);
});
test("CA-04 exige los campos obligatorios (422 con un mensaje por campo)", async () => {
  const r = await post(tokenRecep, { tipo: "CI" });
  assert.equal(r.status, 422);
  for (const k of ["documento", "nombre", "apellido", "correo"])
    assert.ok(r.body.campos[k], k);
});
test("CA-05 un mecánico no puede registrar clientes (403)", async () => {
  assert.equal(
    (await post(tokenMec, nuevo({ documento: `T3${sufijo}` }))).status,
    403,
  );
});
test("CA-06 el registro queda en la bitácora", async () => {
  const [[b]] = await sequelize.query(
    `SELECT count(*)::int AS n FROM bitacora_operacion b JOIN tipo_operacion t USING (id_tipo_operacion) WHERE t.codigo = 'CLIENTE_REGISTRAR'`,
  );
  assert.ok(b.n >= 1);
});
test("CA-07 el listado se puede filtrar por texto", async () => {
  const r = await request(app)
    .get(`/api/clientes?q=T${sufijo}`)
    .set("Authorization", `Bearer ${tokenRecep}`);
  assert.equal(r.status, 200);
  assert.equal(r.body.length, 1);
});
