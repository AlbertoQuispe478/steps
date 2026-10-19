-- ============================================================
-- SEMILLAS (Steps): catálogos, roles, permisos por pantalla y usuarios demo.
-- Códigos únicos por catálogo: RCB = orden Recibida, REC = presupuesto Rechazado.
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO tipo_identificacion (codigo, nombre) VALUES ('CI','Cédula de identidad'),('NIT','NIT'),('PAS','Pasaporte'),('CEX','Cédula de extranjero');
INSERT INTO estado_usuario (codigo, nombre) VALUES ('ACT','Activo'),('INA','Inactivo'),('BLO','Bloqueado');
INSERT INTO estado_asignacion (codigo, nombre) VALUES ('VIG','Vigente'),('FIN','Finalizada');
INSERT INTO tipo_rol (codigo, nombre) VALUES ('OPE','Operativo'),('EXT','Externo');
INSERT INTO tipo_funcion (codigo, nombre) VALUES ('PAN','Pantalla');

INSERT INTO estado_orden (codigo, nombre, es_terminal) VALUES
('RCB','Recibido',FALSE),('DIA','Diagnóstico',FALSE),('APR','Aprobado',FALSE),
('REP','En reparación',FALSE),('FIN','Finalizado',FALSE),('ENT','Entregado',TRUE),('ANU','Anulado',TRUE);

INSERT INTO tipo_comprobante (codigo, nombre) VALUES ('REC','Recibo'),('FAC','Factura');  -- el id 1 (Recibo) es el default de pago
INSERT INTO tipo_pago (codigo, nombre) VALUES ('EFE','Efectivo'),('QR','QR'),('TRA','Transferencia'),('TAR','Tarjeta');
INSERT INTO estado_pago (codigo, nombre, es_terminal) VALUES ('PEN','Pendiente',FALSE),('CON','Confirmado',TRUE),('FAL','Fallido',TRUE),('ANU','Anulado',TRUE);
INSERT INTO estado_factura (codigo, nombre, es_terminal) VALUES ('PEN','Pendiente',FALSE),('EMI','Emitida',FALSE),('ANU','Anulada',TRUE);  -- 'EMI' lo usa v_kpi_venta_diaria

INSERT INTO tipo_servicio (codigo, nombre, precio_hora) VALUES ('MAN','Mantenimiento',100),('REP','Reparación',120),('DIA','Diagnóstico',80);
INSERT INTO tipo_repuesto (codigo, nombre) VALUES ('FIL','Filtros'),('FRE','Frenos'),('ACE','Aceites'),('ELE','Eléctricos'),('MOT','Motor');

INSERT INTO tipo_operacion (codigo, nombre) VALUES
('AUTH_LOGIN','Inicio de sesión'),('AUTH_LOGIN_FALLIDO','Intento de sesión fallido'),('AUTH_BLOQUEO','Cuenta bloqueada'),
('CLIENTE_REGISTRAR','Registro de cliente'),('ORDEN_CREAR','Creación de orden'),('ORDEN_CAMBIAR_ESTADO','Cambio de estado de orden'),
('PRESUPUESTO_ENVIAR','Envío de presupuesto'),('PRESUPUESTO_RESPONDER','Respuesta a presupuesto'),
('PAGO_REGISTRAR','Registro de pago'),('FACTURA_EMITIR','Emisión de factura');

-- Roles y permisos: una función por pantalla (mismo criterio que el repo de referencia).
INSERT INTO rol (id_tipo_rol, codigo, nombre)
SELECT t.id_tipo_rol, v.c, v.n FROM (VALUES ('OPE','ADMIN','Administrador'),('OPE','RECEP','Recepcionista'),('OPE','MECANICO','Mecánico'),('EXT','CLIENTE','Cliente')) v(t,c,n)
JOIN tipo_rol t ON t.codigo = v.t;

INSERT INTO funcion (id_tipo_funcion, codigo, nombre, ruta, metodo_http)
SELECT (SELECT id_tipo_funcion FROM tipo_funcion WHERE codigo='PAN'), v.c, v.n, '/'||v.c, 'GET'
FROM (VALUES ('dashboard','Dashboard'),('recepcion','Recepción'),('ordenes','Órdenes de trabajo'),('presupuestos','Presupuestos'),
             ('citas','Citas'),('inventario','Inventario'),('pagos','Pagos y facturas'),('reportes','Reportes (BI)')) v(c,n);

INSERT INTO rol_funcion (id_rol, id_funcion)
SELECT r.id_rol, f.id_funcion FROM (VALUES
 ('ADMIN','dashboard'),('ADMIN','recepcion'),('ADMIN','ordenes'),('ADMIN','presupuestos'),('ADMIN','citas'),('ADMIN','inventario'),('ADMIN','pagos'),('ADMIN','reportes'),
 ('RECEP','dashboard'),('RECEP','recepcion'),('RECEP','ordenes'),('RECEP','presupuestos'),('RECEP','citas'),('RECEP','inventario'),('RECEP','pagos'),
 ('MECANICO','dashboard'),('MECANICO','ordenes'),('MECANICO','presupuestos'),
 ('CLIENTE','dashboard'),('CLIENTE','ordenes')) v(r,f)
JOIN rol r ON r.codigo = v.r JOIN funcion f ON f.codigo = v.f;

-- Usuarios demo (contraseñas solo para desarrollo).
INSERT INTO persona (id_tipo_identificacion, numero_identificacion, nombre, apellido, email, telefono, id_estado_usuario)
SELECT (SELECT id_tipo_identificacion FROM tipo_identificacion WHERE codigo='CI'), v.d, v.n, v.a, v.m, v.t,
       (SELECT id_estado_usuario FROM estado_usuario WHERE codigo='ACT')
FROM (VALUES ('1000001','Alberto','Quispe','alberto@steps.test','70000001'),('1000002','Carmen','Ríos','carmen@steps.test','70000002'),
             ('1000003','Luis','Pérez','luis@steps.test','70000003'),('1000004','Carlos','Mamani','carlos@steps.test','70000004')) v(d,n,a,m,t);

INSERT INTO usuario (id_persona, username, password_hash)
SELECT p.id_persona, v.u, crypt(v.pw, gen_salt('bf', 10))
FROM (VALUES ('alberto@steps.test','aquispe','Admin12345'),('carmen@steps.test','crios','Recep12345'),
             ('luis@steps.test','lperez','Mecanico12345'),('carlos@steps.test','cmamani','Cliente12345')) v(m,u,pw)
JOIN persona p ON p.email = v.m;

INSERT INTO usuario_rol_asignacion (id_usuario, id_rol, id_estado_asignacion)
SELECT u.id_usuario, r.id_rol, (SELECT id_estado_asignacion FROM estado_asignacion WHERE codigo='VIG')
FROM (VALUES ('aquispe','ADMIN'),('crios','RECEP'),('lperez','MECANICO'),('cmamani','CLIENTE')) v(u,r)
JOIN usuario u ON u.username = v.u JOIN rol r ON r.codigo = v.r;

-- IS-A: cada persona se especializa según su rol.
INSERT INTO recepcionista (id_persona, turno) SELECT id_persona, 'MAÑANA' FROM persona WHERE email='carmen@steps.test';
INSERT INTO mecanico (id_persona, especialidad, valor_hora) SELECT id_persona, 'Mecánica general', 60 FROM persona WHERE email='luis@steps.test';
INSERT INTO cliente (id_persona) SELECT id_persona FROM persona WHERE email='carlos@steps.test';
