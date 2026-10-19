-- ============================================================
-- SISTEMA DE GESTIÓN DE TALLER MECÁNICO (Albert)
-- Diseño basado en IDIOMS de Marcelo Flores
-- Nomenclatura: singular, sustantivos, sin verbos
-- PostgreSQL 15+
-- ============================================================

-- Limpieza (por si acaso)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- ============================================================
-- 1. IDIOM: CLASIFICACIÓN (Catálogos)
-- ============================================================

CREATE TABLE tipo_identificacion (
    id_tipo_identificacion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE tipo_identificacion IS 'IDIOM: Clasificación - Tipos de documento de identidad';

CREATE TABLE estado_usuario (
    id_estado_usuario SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE estado_usuario IS 'IDIOM: Clasificación - Estado del usuario';

CREATE TABLE tipo_rol (
    id_tipo_rol SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);
COMMENT ON TABLE tipo_rol IS 'IDIOM: Clasificación - Tipos de rol';

CREATE TABLE tipo_funcion (
    id_tipo_funcion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);
COMMENT ON TABLE tipo_funcion IS 'IDIOM: Clasificación - Tipos de función';

CREATE TABLE estado_asignacion (
    id_estado_asignacion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE estado_asignacion IS 'IDIOM: Clasificación - Estado de asignación';

CREATE TABLE estado_orden (
    id_estado_orden SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    es_terminal BOOLEAN DEFAULT FALSE
);
COMMENT ON TABLE estado_orden IS 'IDIOM: Clasificación - Estados de orden de trabajo';

CREATE TABLE tipo_servicio (
    id_tipo_servicio SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio_hora DECIMAL(10,2) DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE tipo_servicio IS 'IDIOM: Clasificación - Tipos de servicio del taller';

CREATE TABLE tipo_repuesto (
    id_tipo_repuesto SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);
COMMENT ON TABLE tipo_repuesto IS 'IDIOM: Clasificación - Tipos de repuesto';

CREATE TABLE estado_pago (
    id_estado_pago SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    es_terminal BOOLEAN DEFAULT FALSE
);
COMMENT ON TABLE estado_pago IS 'IDIOM: Clasificación - Estados del pago';

CREATE TABLE tipo_pago (
    id_tipo_pago SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);
COMMENT ON TABLE tipo_pago IS 'IDIOM: Clasificación - Tipos de pago (QR, efectivo, transferencia)';

CREATE TABLE tipo_comprobante (
    id_tipo_comprobante SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);
COMMENT ON TABLE tipo_comprobante IS 'IDIOM: Clasificación - Tipo de comprobante solicitado por el cliente';

CREATE TABLE estado_factura (
    id_estado_factura SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    es_terminal BOOLEAN DEFAULT FALSE
);
COMMENT ON TABLE estado_factura IS 'IDIOM: Clasificación - Estados de factura (emitida, anulada)';

CREATE TABLE marca_vehiculo (
    id_marca SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    activo BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE marca_vehiculo IS 'IDIOM: Clasificación - Marcas de vehículos';

CREATE TABLE modelo_vehiculo (
    id_modelo INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_marca SMALLINT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    anio SMALLINT,
    CONSTRAINT fk_modelo_marca 
        FOREIGN KEY (id_marca) 
        REFERENCES marca_vehiculo(id_marca),
    CONSTRAINT uk_modelo UNIQUE (id_marca, nombre, anio)
);
COMMENT ON TABLE modelo_vehiculo IS 'IDIOM: Clasificación - Modelos de vehículos';

-- ============================================================
-- 2. IDIOM: IS-A (Persona y sus especializaciones)
-- ============================================================

CREATE TABLE persona (
    id_persona INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_identificacion SMALLINT NOT NULL,
    numero_identificacion VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    direccion TEXT,
    id_estado_usuario SMALLINT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_persona_tipo_id 
        FOREIGN KEY (id_tipo_identificacion) 
        REFERENCES tipo_identificacion(id_tipo_identificacion),
    CONSTRAINT fk_persona_estado 
        FOREIGN KEY (id_estado_usuario) 
        REFERENCES estado_usuario(id_estado_usuario)
);
COMMENT ON TABLE persona IS 'IDIOM: IS-A - Generalización de Persona';

CREATE INDEX idx_persona_email ON persona(email);
CREATE INDEX idx_persona_identificacion ON persona(numero_identificacion);

CREATE TABLE usuario (
    id_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    ultimo_acceso TIMESTAMP,
    intento_fallido SMALLINT DEFAULT 0,
    bloqueado_hasta TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_persona 
        FOREIGN KEY (id_persona) 
        REFERENCES persona(id_persona) 
        ON DELETE CASCADE
);
COMMENT ON TABLE usuario IS 'IDIOM: IS-A - Especialización Usuario';

CREATE TABLE cliente (
    id_cliente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    nit VARCHAR(20),
    razon_social VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cliente_persona 
        FOREIGN KEY (id_persona) 
        REFERENCES persona(id_persona) 
        ON DELETE CASCADE
);
COMMENT ON TABLE cliente IS 'IDIOM: IS-A - Especialización Cliente';

CREATE TABLE mecanico (
    id_mecanico INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    especialidad VARCHAR(100),
    grado_academico VARCHAR(50),
    valor_hora DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mecanico_persona 
        FOREIGN KEY (id_persona) 
        REFERENCES persona(id_persona) 
        ON DELETE CASCADE
);
COMMENT ON TABLE mecanico IS 'IDIOM: IS-A - Especialización Mecánico';

CREATE TABLE recepcionista (
    id_recepcionista INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    turno VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recepcionista_persona 
        FOREIGN KEY (id_persona) 
        REFERENCES persona(id_persona) 
        ON DELETE CASCADE
);
COMMENT ON TABLE recepcionista IS 'IDIOM: IS-A - Especialización Recepcionista';

-- ============================================================
-- 3. IDIOM: MAESTRO-DETALLE (Vehículo, Orden, Repuesto)
-- ============================================================

CREATE TABLE vehiculo (
    id_vehiculo INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente INTEGER NOT NULL,
    id_modelo INTEGER NOT NULL,
    placa VARCHAR(20) NOT NULL UNIQUE,
    color VARCHAR(30),
    kilometraje_actual INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vehiculo_cliente 
        FOREIGN KEY (id_cliente) 
        REFERENCES cliente(id_cliente),
    CONSTRAINT fk_vehiculo_modelo 
        FOREIGN KEY (id_modelo) 
        REFERENCES modelo_vehiculo(id_modelo)
);
COMMENT ON TABLE vehiculo IS 'IDIOM: Maestro-Detalle - Maestro Vehículo';

CREATE INDEX idx_vehiculo_placa ON vehiculo(placa);
CREATE INDEX idx_vehiculo_cliente ON vehiculo(id_cliente);

CREATE TABLE orden_trabajo (
    id_orden_trabajo INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_vehiculo INTEGER NOT NULL,
    id_estado_orden SMALLINT NOT NULL,
    id_recepcionista INTEGER NOT NULL,
    id_mecanico INTEGER,
    fecha_ingreso TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega TIMESTAMP,
    kilometraje_ingreso INTEGER NOT NULL,
    nivel_gasolina VARCHAR(20),
    observacion TEXT,
    total DECIMAL(12,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_orden_vehiculo 
        FOREIGN KEY (id_vehiculo) 
        REFERENCES vehiculo(id_vehiculo),
    CONSTRAINT fk_orden_estado 
        FOREIGN KEY (id_estado_orden) 
        REFERENCES estado_orden(id_estado_orden),
    CONSTRAINT fk_orden_recepcionista 
        FOREIGN KEY (id_recepcionista) 
        REFERENCES recepcionista(id_recepcionista),
    CONSTRAINT fk_orden_mecanico 
        FOREIGN KEY (id_mecanico) 
        REFERENCES mecanico(id_mecanico),
    CONSTRAINT chk_fechas_orden 
        CHECK (fecha_entrega IS NULL OR fecha_entrega > fecha_ingreso)
);
COMMENT ON TABLE orden_trabajo IS 'IDIOM: Maestro-Detalle - Maestro Orden de Trabajo';

CREATE INDEX idx_orden_vehiculo ON orden_trabajo(id_vehiculo);
CREATE INDEX idx_orden_estado ON orden_trabajo(id_estado_orden);
CREATE INDEX idx_orden_fechas ON orden_trabajo(fecha_ingreso, fecha_entrega);

CREATE TABLE repuesto (
    id_repuesto INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_repuesto SMALLINT NOT NULL,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    stock_actual INTEGER DEFAULT 0,
    stock_minimo INTEGER DEFAULT 0,
    precio_compra DECIMAL(10,2) DEFAULT 0,
    precio_venta DECIMAL(10,2) DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_repuesto_tipo 
        FOREIGN KEY (id_tipo_repuesto) 
        REFERENCES tipo_repuesto(id_tipo_repuesto)
);
COMMENT ON TABLE repuesto IS 'IDIOM: Maestro-Detalle - Maestro Repuesto';

CREATE INDEX idx_repuesto_codigo ON repuesto(codigo);
CREATE INDEX idx_repuesto_stock ON repuesto(stock_actual);

CREATE TABLE orden_detalle (
    id_orden_detalle BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_orden_trabajo INTEGER NOT NULL,
    id_tipo_servicio SMALLINT,
    id_repuesto INTEGER,
    descripcion VARCHAR(200),
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_detalle_orden 
        FOREIGN KEY (id_orden_trabajo) 
        REFERENCES orden_trabajo(id_orden_trabajo) 
        ON DELETE CASCADE,
    CONSTRAINT fk_detalle_servicio 
        FOREIGN KEY (id_tipo_servicio) 
        REFERENCES tipo_servicio(id_tipo_servicio),
    CONSTRAINT fk_detalle_repuesto 
        FOREIGN KEY (id_repuesto) 
        REFERENCES repuesto(id_repuesto),
    CONSTRAINT chk_detalle_origen 
        CHECK (id_tipo_servicio IS NOT NULL OR id_repuesto IS NOT NULL)
);
COMMENT ON TABLE orden_detalle IS 'IDIOM: Maestro-Detalle - Detalle de Orden';

CREATE INDEX idx_detalle_orden ON orden_detalle(id_orden_trabajo);

CREATE TABLE movimiento_stock (
    id_movimiento_stock BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_repuesto INTEGER NOT NULL,
    id_orden_trabajo INTEGER,
    tipo_movimiento VARCHAR(20) NOT NULL,
    cantidad INTEGER NOT NULL,
    stock_anterior INTEGER NOT NULL,
    stock_nuevo INTEGER NOT NULL,
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacion TEXT,
    CONSTRAINT fk_movimiento_repuesto 
        FOREIGN KEY (id_repuesto) 
        REFERENCES repuesto(id_repuesto),
    CONSTRAINT fk_movimiento_orden 
        FOREIGN KEY (id_orden_trabajo) 
        REFERENCES orden_trabajo(id_orden_trabajo),
    CONSTRAINT chk_tipo_movimiento 
        CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA', 'AJUSTE'))
);
COMMENT ON TABLE movimiento_stock IS 'IDIOM: Maestro-Detalle - Movimiento histórico de stock';

CREATE INDEX idx_movimiento_repuesto ON movimiento_stock(id_repuesto);
CREATE INDEX idx_movimiento_fecha ON movimiento_stock(fecha_movimiento);

-- ============================================================
-- 4. SEGURIDAD (Roles y Funciones) — ANTES DE REFLEXIÓN
-- ============================================================

CREATE TABLE rol (
    id_rol INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_rol SMALLINT NOT NULL,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_rol_tipo 
        FOREIGN KEY (id_tipo_rol) 
        REFERENCES tipo_rol(id_tipo_rol)
);
COMMENT ON TABLE rol IS 'IDIOM: Maestro-Detalle - Rol del sistema';

CREATE TABLE funcion (
    id_funcion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_funcion SMALLINT NOT NULL,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    ruta VARCHAR(200),
    metodo_http VARCHAR(10),
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_funcion_tipo 
        FOREIGN KEY (id_tipo_funcion) 
        REFERENCES tipo_funcion(id_tipo_funcion)
);
COMMENT ON TABLE funcion IS 'IDIOM: Maestro-Detalle - Función del sistema';

CREATE TABLE rol_funcion (
    id_rol_funcion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol INTEGER NOT NULL,
    id_funcion INTEGER NOT NULL,
    CONSTRAINT fk_rf_rol 
        FOREIGN KEY (id_rol) 
        REFERENCES rol(id_rol) 
        ON DELETE CASCADE,
    CONSTRAINT fk_rf_funcion 
        FOREIGN KEY (id_funcion) 
        REFERENCES funcion(id_funcion) 
        ON DELETE CASCADE,
    CONSTRAINT uk_rol_funcion UNIQUE (id_rol, id_funcion)
);
COMMENT ON TABLE rol_funcion IS 'IDIOM: Maestro-Detalle - Detalle funciones por rol';

-- ============================================================
-- 5. IDIOM: REFLEXIÓN (Jerarquías)
-- ============================================================

CREATE TABLE funcion_dependencia (
    id_funcion_dependencia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_funcion_padre INTEGER NOT NULL,
    id_funcion_hija INTEGER NOT NULL,
    CONSTRAINT fk_fd_padre 
        FOREIGN KEY (id_funcion_padre) 
        REFERENCES funcion(id_funcion) 
        ON DELETE CASCADE,
    CONSTRAINT fk_fd_hija 
        FOREIGN KEY (id_funcion_hija) 
        REFERENCES funcion(id_funcion) 
        ON DELETE CASCADE,
    CONSTRAINT uk_funcion_dependencia UNIQUE (id_funcion_padre, id_funcion_hija),
    CONSTRAINT chk_funciones_diferentes 
        CHECK (id_funcion_padre <> id_funcion_hija)
);
COMMENT ON TABLE funcion_dependencia IS 'IDIOM: Reflexión - Dependencias entre funciones';

CREATE TABLE repuesto_equivalencia (
    id_repuesto_equivalencia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_repuesto_principal INTEGER NOT NULL,
    id_repuesto_equivalente INTEGER NOT NULL,
    CONSTRAINT fk_re_principal 
        FOREIGN KEY (id_repuesto_principal) 
        REFERENCES repuesto(id_repuesto) 
        ON DELETE CASCADE,
    CONSTRAINT fk_re_equivalente 
        FOREIGN KEY (id_repuesto_equivalente) 
        REFERENCES repuesto(id_repuesto) 
        ON DELETE CASCADE,
    CONSTRAINT uk_repuesto_equivalencia UNIQUE (id_repuesto_principal, id_repuesto_equivalente),
    CONSTRAINT chk_repuestos_diferentes 
        CHECK (id_repuesto_principal <> id_repuesto_equivalente)
);
COMMENT ON TABLE repuesto_equivalencia IS 'IDIOM: Reflexión - Repuestos equivalentes';

-- ============================================================
-- 6. IDIOM: COMPOSICIÓN (Histórico con período)
-- ============================================================

CREATE TABLE usuario_rol_asignacion (
    id_asignacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario INTEGER NOT NULL,
    id_rol INTEGER NOT NULL,
    fecha_inicio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin TIMESTAMP,
    id_estado_asignacion SMALLINT NOT NULL,
    observacion TEXT,
    asignado_por INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ura_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES usuario(id_usuario) 
        ON DELETE CASCADE,
    CONSTRAINT fk_ura_rol 
        FOREIGN KEY (id_rol) 
        REFERENCES rol(id_rol),
    CONSTRAINT fk_ura_estado 
        FOREIGN KEY (id_estado_asignacion) 
        REFERENCES estado_asignacion(id_estado_asignacion),
    CONSTRAINT chk_fechas_asignacion 
        CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);
COMMENT ON TABLE usuario_rol_asignacion IS 'IDIOM: Composición - Asignación histórica de rol';

CREATE INDEX idx_ura_usuario ON usuario_rol_asignacion(id_usuario);
CREATE INDEX idx_ura_fechas ON usuario_rol_asignacion(fecha_inicio, fecha_fin);

-- Composición: Pago (maestro) — con tipo de comprobante
CREATE TABLE pago (
    id_pago BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_orden_trabajo INTEGER NOT NULL,
    id_tipo_pago SMALLINT NOT NULL,
    id_estado_pago SMALLINT NOT NULL,
    id_tipo_comprobante SMALLINT NOT NULL DEFAULT 1,
    monto DECIMAL(12,2) NOT NULL,
    moneda VARCHAR(3) DEFAULT 'BOB',
    codigo_qr VARCHAR(255),
    referencia_externa VARCHAR(100),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_confirmacion TIMESTAMP,
    observacion TEXT,
    CONSTRAINT fk_pago_orden 
        FOREIGN KEY (id_orden_trabajo) 
        REFERENCES orden_trabajo(id_orden_trabajo),
    CONSTRAINT fk_pago_tipo 
        FOREIGN KEY (id_tipo_pago) 
        REFERENCES tipo_pago(id_tipo_pago),
    CONSTRAINT fk_pago_estado 
        FOREIGN KEY (id_estado_pago) 
        REFERENCES estado_pago(id_estado_pago),
    CONSTRAINT fk_pago_tipo_comprobante 
        FOREIGN KEY (id_tipo_comprobante) 
        REFERENCES tipo_comprobante(id_tipo_comprobante)
);
COMMENT ON TABLE pago IS 'IDIOM: Composición - Pago de orden (maestro)';

CREATE INDEX idx_pago_orden ON pago(id_orden_trabajo);
CREATE INDEX idx_pago_estado ON pago(id_estado_pago);
CREATE INDEX idx_pago_fecha ON pago(fecha_creacion);

-- Composición: Factura (detalle opcional) — id_pago puede ser NULL
CREATE TABLE factura (
    id_factura BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pago BIGINT UNIQUE, -- NULL permitido: pago sin factura
    id_estado_factura SMALLINT NOT NULL,
    numero_factura VARCHAR(50) UNIQUE,
    cuf VARCHAR(100) UNIQUE,
    nit_cliente VARCHAR(20),
    razon_social VARCHAR(150),
    monto_subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    monto_impuesto DECIMAL(12,2) NOT NULL DEFAULT 0,
    monto_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    xml_firmado TEXT,
    url_pdf VARCHAR(255),
    observacion TEXT,
    CONSTRAINT fk_factura_pago 
        FOREIGN KEY (id_pago) 
        REFERENCES pago(id_pago),
    CONSTRAINT fk_factura_estado 
        FOREIGN KEY (id_estado_factura) 
        REFERENCES estado_factura(id_estado_factura)
);
COMMENT ON TABLE factura IS 'IDIOM: Composición - Factura opcional asociada a pago';

CREATE INDEX idx_factura_numero ON factura(numero_factura);
CREATE INDEX idx_factura_cuf ON factura(cuf);
CREATE INDEX idx_factura_fecha ON factura(fecha_emision);

-- ============================================================
-- 7. DATOS INICIALES (Seeders)
-- ============================================================

INSERT INTO tipo_identificacion (codigo, nombre) VALUES
('CI', 'Cédula de Identidad'),
('NIT', 'NIT'),
('PAS', 'Pasaporte');

INSERT INTO estado_usuario (codigo, nombre) VALUES
('ACT', 'Activo'),
('INA', 'Inactivo'),
('BLO', 'Bloqueado');

INSERT INTO estado_orden (codigo, nombre, es_terminal) VALUES
('REC', 'Recibido', FALSE),
('DIA', 'En Diagnóstico', FALSE),
('APR', 'Aprobado', FALSE),
('REP', 'En Reparación', FALSE),
('FIN', 'Finalizado', TRUE),
('ENT', 'Entregado', TRUE),
('ANU', 'Anulado', TRUE);

INSERT INTO tipo_servicio (codigo, nombre, precio_hora) VALUES
('MANT', 'Mantenimiento General', 80),
('FREN', 'Sistema de Frenos', 100),
('MOTOR', 'Reparación de Motor', 150),
('ELEC', 'Sistema Eléctrico', 120),
('SUSP', 'Suspensión', 110);

INSERT INTO tipo_repuesto (codigo, nombre) VALUES
('FIL', 'Filtros'),
('ACE', 'Aceites'),
('FRE', 'Frenos'),
('ELE', 'Eléctricos'),
('MOT', 'Motor');

INSERT INTO estado_pago (codigo, nombre, es_terminal) VALUES
('PEN', 'Pendiente', FALSE),
('PRO', 'Procesando', FALSE),
('CON', 'Confirmado', TRUE),
('REC', 'Rechazado', TRUE),
('ANU', 'Anulado', TRUE);

INSERT INTO tipo_pago (codigo, nombre) VALUES
('QR', 'Código QR'),
('EFE', 'Efectivo'),
('TRA', 'Transferencia'),
('TAR', 'Tarjeta');

INSERT INTO tipo_comprobante (codigo, nombre) VALUES
('FACTURA', 'Factura Fiscal'),
('RECIBO', 'Recibo Simple'),
('NINGUNO', 'Sin comprobante');

INSERT INTO estado_factura (codigo, nombre, es_terminal) VALUES
('EMI', 'Emitida', TRUE),
('ANU', 'Anulada', TRUE),
('CON', 'Contingencia', FALSE);

INSERT INTO estado_asignacion (codigo, nombre) VALUES
('VIG', 'Vigente'),
('EXP', 'Expirada'),
('REV', 'Revocada');

INSERT INTO tipo_rol (codigo, nombre) VALUES
('SIS', 'Sistema'),
('TAL', 'Taller'),
('CLI', 'Cliente');

INSERT INTO tipo_funcion (codigo, nombre) VALUES
('CRUD', 'CRUD'),
('REP', 'Reporte'),
('ADM', 'Administración'),
('OPS', 'Operación');

INSERT INTO marca_vehiculo (nombre) VALUES
('Toyota'), ('Nissan'), ('Chevrolet'), ('Mazda'), ('Ford'), ('Hyundai');

INSERT INTO modelo_vehiculo (id_marca, nombre, anio) VALUES
(1, 'Corolla', 2019), (1, 'Hilux', 2020),
(2, 'Versa', 2020), (2, 'Sentra', 2021),
(3, 'Spark', 2018), (4, 'Mazda 3', 2021);

INSERT INTO rol (id_tipo_rol, codigo, nombre) VALUES
(1, 'ADMIN', 'Administrador'),
(2, 'MECANICO', 'Mecánico'),
(2, 'RECEP', 'Recepcionista'),
(3, 'CLIENTE', 'Cliente');

INSERT INTO funcion (id_tipo_funcion, codigo, nombre, ruta, metodo_http) VALUES
(1, 'CLIENTE_CREATE', 'Crear Cliente', '/api/cliente', 'POST'),
(1, 'CLIENTE_READ', 'Ver Cliente', '/api/cliente/:id', 'GET'),
(1, 'CLIENTE_UPDATE', 'Editar Cliente', '/api/cliente/:id', 'PUT'),
(1, 'CLIENTE_DELETE', 'Eliminar Cliente', '/api/cliente/:id', 'DELETE'),
(1, 'VEHICULO_CREATE', 'Crear Vehículo', '/api/vehiculo', 'POST'),
(1, 'ORDEN_CREATE', 'Crear Orden', '/api/orden', 'POST'),
(1, 'ORDEN_READ', 'Ver Orden', '/api/orden/:id', 'GET'),
(1, 'ORDEN_UPDATE', 'Actualizar Orden', '/api/orden/:id', 'PUT'),
(4, 'PAGO_CREATE', 'Generar QR de Pago', '/api/pago/qr', 'POST'),
(4, 'PAGO_CONFIRM', 'Confirmar Pago', '/api/pago/confirmar', 'POST'),
(2, 'REP_VENTA', 'Reporte de Ventas', '/api/reporte/venta', 'GET'),
(2, 'REP_STOCK', 'Reporte de Stock', '/api/reporte/stock', 'GET'),
(2, 'REP_MECANICO', 'Reporte por Mecánico', '/api/reporte/mecanico', 'GET'),
(3, 'FACTURA_EMIT', 'Emitir Factura', '/api/factura', 'POST'),
(3, 'FACTURA_ANUL', 'Anular Factura', '/api/factura/:id/anular', 'PUT');

INSERT INTO rol_funcion (id_rol, id_funcion) VALUES
-- ADMIN: todo
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8),(1,9),(1,10),(1,11),(1,12),(1,13),(1,14),(1,15),
-- MECANICO: ver orden, actualizar, reporte propio
(2,7),(2,8),(2,13),
-- RECEPCIONISTA: cliente, vehículo, orden, pago
(3,1),(3,2),(3,5),(3,6),(3,7),(3,9),(3,10),(3,14),
-- CLIENTE: solo ver sus órdenes
(4,7);
