// HU-03 y HU-04: una prueba por criterio. Requiere 04 y 05 aplicados a la BD.
const { test, before, after } = require("node:test");
const assert = require("node:assert");
const request = require("supertest");
const app = require("../../src/backend/app");
const { sequelize } = require("../../src/backend/config/db");

const sf = Date.now(),
  P1 = `TT${sf}A`,
  P2 = `TT${sf}B`;
let tk = {},
  carlos,
  otro,
  modelo,
  ordenId;
const entrar = async (u, p) =>
  (
    await request(app)
      .post("/api/auth/login")
      .send({ username: u, password: p })
  ).body.token;
const api = (m, ruta, token, cuerpo) =>
  request(app)
    [m](`/api/${ruta}`)
    .set("Authorization", `Bearer ${token}`)
    .send(cuerpo);
const orden = (o = {}) => ({
  placa: P1,
  idCliente: carlos,
  idModelo: modelo,
  kilometraje: 1000,
  nivelGasolina: "1/2",
  ...o,
});

before(async () => {
  await sequelize.query(
    `UPDATE usuario SET intento_fallido = 0, bloqueado_hasta = NULL`,
  );
  for (const [k, u, p] of [
    ["recep", "crios", "Recep12345"],
    ["mec", "lperez", "Mecanico12345"],
    ["cli", "cmamani", "Cliente12345"],
  ])
    tk[k] = await entrar(u, p);
  const op = (await api("get", "ordenes/opciones", tk.recep)).body;
  carlos = op.clientes.find((c) => c.documento === "1000004").id;
  modelo = op.modelos[0].id;
  const r = await api("post", "clientes", tk.recep, {
    tipo: "CI",
    documento: `T${sf}`,
    nombre: "Otro",
    apellido: "Dueño",
    correo: `test-ord-${sf}@steps.test`,
  });
  otro = r.body.id;
});
after(async () => {
  await sequelize.query(
    `DELETE FROM orden_trabajo WHERE id_vehiculo IN (SELECT id_vehiculo FROM vehiculo WHERE placa LIKE 'TT${sf}%')`,
  );
  await sequelize.query(`DELETE FROM vehiculo WHERE placa LIKE 'TT${sf}%'`);
  await sequelize.query(
    `DELETE FROM persona WHERE email LIKE 'test-ord-%@steps.test'`,
  );
  await sequelize.close();
});

test("CA-01 recepción crea el vehículo y una orden en estado Recibido con su historial", async () => {
  const r = await api(
    "post",
    "ordenes",
    tk.recep,
    orden({ observacion: "Ruido al frenar" }),
  );
  assert.equal(r.status, 201);
  ordenId = r.body.id;
  const [[h]] = await sequelize.query(
    `SELECT count(*) FILTER (WHERE fecha_fin IS NULL)::int AS vigentes, count(*)::int AS total FROM orden_estado_historial WHERE id_orden_trabajo = ${ordenId}`,
  );
  assert.deepEqual([h.vigentes, h.total], [1, 1]);
});
test("CA-02 una placa existente del mismo cliente reutiliza el vehículo y actualiza el kilometraje", async () => {
  assert.equal(
    (await api("post", "ordenes", tk.recep, orden({ kilometraje: 1500 })))
      .status,
    201,
  );
  const [[v]] = await sequelize.query(
    `SELECT count(*)::int AS n, max(kilometraje_actual) AS km FROM vehiculo WHERE placa = '${P1}'`,
  );
  assert.deepEqual([v.n, v.km], [1, 1500]);
});

test("CA-03 una placa de otro cliente se rechaza (409)", async () => {
  // Enviamos un kilometraje mayor (ej. 2000) para que pase la validación de km
  // y así llegue a la validación de placa de otro cliente.
  const r = await api(
    "post",
    "ordenes",
    tk.recep,
    orden({ idCliente: otro, kilometraje: 2000 }),
  );
  assert.equal(r.status, 409);
  assert.ok(r.body.campos.placa);
});

test("CA-04 un kilometraje menor al último registrado se rechaza (422)", async () => {
  const r = await api("post", "ordenes", tk.recep, orden({ kilometraje: 10 }));
  assert.equal(r.status, 422);
  assert.ok(r.body.campos.kilometraje);
});
test("CA-05 faltan datos obligatorios: 422 con un mensaje por campo", async () => {
  const r = await api("post", "ordenes", tk.recep, {});
  assert.equal(r.status, 422);
  for (const k of [
    "placa",
    "idCliente",
    "idModelo",
    "kilometraje",
    "nivelGasolina",
  ])
    assert.ok(r.body.campos[k], k);
});
test("CA-06 un mecánico no puede abrir la recepción (403)", async () => {
  assert.equal(
    (await api("post", "ordenes", tk.mec, orden({ placa: P2 }))).status,
    403,
  );
});
test("CA-07 un cambio de estado válido cierra el período anterior y abre el nuevo", async () => {
  assert.equal(
    (await api("patch", `ordenes/${ordenId}/estado`, tk.mec, { estado: "DIA" }))
      .status,
    200,
  );
  const [[h]] = await sequelize.query(
    `SELECT count(*) FILTER (WHERE fecha_fin IS NULL)::int AS vigentes, count(*)::int AS total FROM orden_estado_historial WHERE id_orden_trabajo = ${ordenId}`,
  );
  assert.deepEqual([h.vigentes, h.total], [1, 2]);
});
test("CA-08 saltarse un estado se rechaza (422)", async () => {
  assert.equal(
    (
      await api("patch", `ordenes/${ordenId}/estado`, tk.recep, {
        estado: "FIN",
      })
    ).status,
    422,
  );
});
test("CA-09 el mecánico no puede aprobar ni entregar (403)", async () => {
  assert.equal(
    (await api("patch", `ordenes/${ordenId}/estado`, tk.mec, { estado: "APR" }))
      .status,
    403,
  );
});
test("CA-10 el cliente solo ve sus órdenes y el filtro por texto funciona", async () => {
  await api("post", "ordenes", tk.recep, orden({ placa: P2, idCliente: otro }));
  const mias = (await api("get", `ordenes?q=TT${sf}`, tk.cli)).body
    .map((o) => o.vehiculo)
    .join();
  assert.ok(mias.includes(P1));
  assert.ok(!mias.includes(P2));
});
test("CA-11 crear y cambiar de estado quedan en la bitácora", async () => {
  const [[b]] = await sequelize.query(
    `SELECT count(DISTINCT t.codigo)::int AS n FROM bitacora_operacion b JOIN tipo_operacion t USING (id_tipo_operacion) WHERE t.codigo IN ('ORDEN_CREAR','ORDEN_CAMBIAR_ESTADO')`,
  );
  assert.equal(b.n, 2);
});
