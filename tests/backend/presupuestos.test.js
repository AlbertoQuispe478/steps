// HU-05 y HU-06: una prueba por criterio. Requiere 04, 05 y 06 aplicados.
const { test, before, after } = require("node:test");
const assert = require("node:assert");
const request = require("supertest");
const app = require("../../src/backend/app");
const { sequelize } = require("../../src/backend/config/db");

const sf = Date.now();
const tk = {};
let carlos, otro, modelo, serv, rep, ord1, ord2, ord3, pres1, pres2;
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
const enDiagnostico = async (placa, idCliente) => {
  const id = (
    await api("post", "ordenes", tk.recep, {
      placa,
      idCliente,
      idModelo: modelo,
      kilometraje: 100,
      nivelGasolina: "1/2",
    })
  ).body.id;
  await api("patch", `ordenes/${id}/estado`, tk.mec, { estado: "DIA" });
  return id;
};
const lineas = () => [
  { tipo: "servicio", id: serv.id, cantidad: 2, precio: 1 },
  { tipo: "repuesto", id: rep.id, cantidad: 1 },
];

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
  otro = (
    await api("post", "clientes", tk.recep, {
      tipo: "CI",
      documento: `P${sf}`,
      nombre: "Otro",
      apellido: "Dueño",
      correo: `test-pre-${sf}@steps.test`,
    })
  ).body.id;
  ord1 = await enDiagnostico(`TP${sf}A`, carlos);
  ord2 = await enDiagnostico(`TP${sf}B`, carlos);
  ord3 = await enDiagnostico(`TP${sf}C`, otro);
  const o = (await api("get", "presupuestos/opciones", tk.mec)).body;
  serv = o.servicios.find((s) => s.nombre === "Mantenimiento");
  rep = o.repuestos.find((r) => r.nombre.includes("FIL-001"));
});
after(async () => {
  const ords = `SELECT id_orden_trabajo FROM orden_trabajo WHERE id_vehiculo IN (SELECT id_vehiculo FROM vehiculo WHERE placa LIKE 'TP${sf}%')`;
  await sequelize.query(
    `DELETE FROM notificacion WHERE id_orden_trabajo IN (${ords})`,
  );
  await sequelize.query(
    `DELETE FROM orden_trabajo WHERE id_orden_trabajo IN (${ords})`,
  );
  await sequelize.query(`DELETE FROM vehiculo WHERE placa LIKE 'TP${sf}%'`);
  await sequelize.query(
    `DELETE FROM persona WHERE email LIKE 'test-pre-%@steps.test'`,
  );
  await sequelize.close();
});

test("CA-01 crea un borrador y el servidor calcula el total con precios del catálogo", async () => {
  const r = await api("post", "presupuestos", tk.mec, {
    idOrden: ord1,
    lineas: lineas(),
  });
  assert.equal(r.status, 201);
  pres1 = r.body.id;
  assert.equal(r.body.total, 2 * Number(serv.precio) + Number(rep.precio));
});
test("CA-02 rechaza una orden que no está en Diagnóstico (422)", async () => {
  const id = (
    await api("post", "ordenes", tk.recep, {
      placa: `TP${sf}D`,
      idCliente: carlos,
      idModelo: modelo,
      kilometraje: 1,
      nivelGasolina: "Lleno",
    })
  ).body.id;
  assert.equal(
    (
      await api("post", "presupuestos", tk.mec, {
        idOrden: id,
        lineas: lineas(),
      })
    ).status,
    422,
  );
});
test("CA-03 rechaza un segundo presupuesto en curso para la misma orden (409)", async () => {
  assert.equal(
    (
      await api("post", "presupuestos", tk.mec, {
        idOrden: ord1,
        lineas: lineas(),
      })
    ).status,
    409,
  );
});
test("CA-04 exige al menos una línea válida (422)", async () => {
  const r = await api("post", "presupuestos", tk.mec, {
    idOrden: ord2,
    lineas: [],
  });
  assert.equal(r.status, 422);
  assert.ok(r.body.campos.lineas);
});
test("CA-05 enviar pasa a Enviado y deja la notificación pendiente al cliente", async () => {
  assert.equal(
    (await api("post", `presupuestos/${pres1}/enviar`, tk.mec)).status,
    200,
  );
  const [[n]] = await sequelize.query(
    `SELECT count(*)::int AS n FROM notificacion WHERE id_orden_trabajo = ${ord1} AND canal = 'WHATSAPP'`,
  );
  assert.equal(n.n, 1);
});
test("CA-06 no se puede enviar dos veces (422)", async () => {
  assert.equal(
    (await api("post", `presupuestos/${pres1}/enviar`, tk.mec)).status,
    422,
  );
});
test("CA-07 un mecánico no puede responder por el cliente (403)", async () => {
  assert.equal(
    (
      await api("post", `presupuestos/${pres1}/responder`, tk.mec, {
        decision: "APR",
      })
    ).status,
    403,
  );
});
test("CA-08 el cliente aprueba: copia las líneas, fija el total y la orden pasa a Aprobado", async () => {
  assert.equal(
    (
      await api("post", `presupuestos/${pres1}/responder`, tk.cli, {
        decision: "APR",
      })
    ).status,
    200,
  );
  const [[o]] = await sequelize.query(
    `SELECT eo.codigo, o.total::float AS total, (SELECT count(*)::int FROM orden_detalle d WHERE d.id_orden_trabajo = o.id_orden_trabajo) AS lineas FROM orden_trabajo o JOIN estado_orden eo USING (id_estado_orden) WHERE o.id_orden_trabajo = ${ord1}`,
  );
  assert.deepEqual([o.codigo, o.lineas], ["APR", 2]);
  assert.ok(o.total > 0);
});
test("CA-09 responder dos veces se rechaza (422)", async () => {
  assert.equal(
    (
      await api("post", `presupuestos/${pres1}/responder`, tk.cli, {
        decision: "REC",
      })
    ).status,
    422,
  );
});
test("CA-10 si el cliente rechaza, la orden sigue en Diagnóstico y se puede presupuestar de nuevo", async () => {
  pres2 = (
    await api("post", "presupuestos", tk.mec, {
      idOrden: ord2,
      lineas: lineas(),
    })
  ).body.id;
  await api("post", `presupuestos/${pres2}/enviar`, tk.mec);
  assert.equal(
    (
      await api("post", `presupuestos/${pres2}/responder`, tk.cli, {
        decision: "REC",
      })
    ).status,
    200,
  );
  assert.equal(
    (
      await api("post", "presupuestos", tk.mec, {
        idOrden: ord2,
        lineas: lineas(),
      })
    ).status,
    201,
  );
});
test("CA-11 el cliente no crea presupuestos (403) y solo ve los suyos", async () => {
  assert.equal(
    (
      await api("post", "presupuestos", tk.cli, {
        idOrden: ord3,
        lineas: lineas(),
      })
    ).status,
    403,
  );
  const p3 = (
    await api("post", "presupuestos", tk.recep, {
      idOrden: ord3,
      lineas: lineas(),
    })
  ).body.id;
  const vistos = (await api("get", "presupuestos", tk.cli)).body.map(
    (p) => p.id,
  );
  assert.ok(vistos.includes(pres1));
  assert.ok(!vistos.includes(p3));
  assert.equal((await api("get", `presupuestos/${p3}`, tk.cli)).status, 404);
});
