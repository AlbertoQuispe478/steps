// Una prueba por criterio de aceptación de HU-01. Requiere la BD levantada (docker compose up -d).
const { test, after, beforeEach } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../../src/backend/app');
const { sequelize } = require('../../src/backend/config/db');

const login = (username, password) => request(app).post('/api/auth/login').send({ username, password });
beforeEach(() => sequelize.query(`UPDATE usuario SET intento_fallido = 0, bloqueado_hasta = NULL`));
after(() => sequelize.close());

test('CA-01 credenciales correctas abren sesión con funciones del rol', async () => {
  const r = await login('crios', 'Recep12345');
  assert.equal(r.status, 200);
  assert.ok(r.body.token);
  assert.ok(r.body.usuario.funciones.includes('recepcion'));
  assert.ok(!r.body.usuario.funciones.includes('reportes'));
});
test('CA-02 contraseña incorrecta devuelve 401 y cuenta el intento', async () => {
  const r = await login('lperez', 'mala');
  assert.equal(r.status, 401);
  const [[u]] = await sequelize.query(`SELECT intento_fallido FROM usuario WHERE username = 'lperez'`);
  assert.equal(u.intento_fallido, 1);
});
test('CA-03 cinco fallos bloquean la cuenta (423)', async () => {
  for (let i = 0; i < 5; i++) await login('lperez', 'mala');
  assert.equal((await login('lperez', 'Mecanico12345')).status, 423);
});
test('CA-04 sin usuario o contraseña devuelve 422', async () => {
  assert.equal((await login('', '')).status, 422);
});
test('CA-05 ruta protegida sin token devuelve 401', async () => {
  assert.equal((await request(app).get('/api/auth/me')).status, 401);
});
test('CA-06 cliente sin permiso de reportes recibe 403 explícito', async () => {
  const { body } = await login('cmamani', 'Cliente12345');
  const r = await request(app).get('/api/reportes/ping').set('Authorization', `Bearer ${body.token}`);
  assert.equal(r.status, 403);
  assert.match(r.body.error, /reportes/);
});
test('CA-07 el inicio de sesión queda en la bitácora', async () => {
  await login('aquispe', 'Admin12345');
  const [[b]] = await sequelize.query(`SELECT count(*)::int AS n FROM bitacora_operacion b JOIN tipo_operacion t USING (id_tipo_operacion) WHERE t.codigo = 'AUTH_LOGIN'`);
  assert.ok(b.n >= 1);
});