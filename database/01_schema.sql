-- ============================================================
-- SISTEMA DE GESTIÓN DE TALLER MECÁNICO (Albert / Tuulapp Core)
-- Diseño basado en IDIOMS (Clasificación, IS-A, Maestro-Detalle,
-- Reflexión, Composición)
-- Nomenclatura: singular, sustantivos, sin verbos
-- PostgreSQL 15+
-- ============================================================

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

CREATE TABLE estado_usuario (
    id_estado_usuario SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE tipo_rol (
    id_tipo_rol SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE tipo_funcion (
    id_tipo_funcion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE estado_asignacion (
    id_estado_asignacion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE estado_orden (
    id_estado_orden SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    es_terminal BOOLEAN DEFAULT FALSE
);

CREATE TABLE tipo_servicio (
    id_tipo_servicio SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio_hora DECIMAL(10,2) DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE tipo_repuesto (
    id_tipo_repuesto SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE estado_pago (
    id_estado_pago SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    es_terminal BOOLEAN DEFAULT FALSE
);

CREATE TABLE tipo_pago (
    id_tipo_pago SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE tipo_comprobante (
    id_tipo_comprobante SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE estado_factura (
    id_estado_factura SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    es_terminal BOOLEAN DEFAULT FALSE
);

CREATE TABLE estado_presupuesto (
    id_estado_presupuesto SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    es_terminal BOOLEAN DEFAULT FALSE
);

CREATE TABLE estado_cita (
    id_estado_cita SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    es_terminal BOOLEAN DEFAULT FALSE
);

CREATE TABLE tipo_notificacion (
    id_tipo_notificacion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    plantilla TEXT
);

CREATE TABLE estado_notificacion (
    id_estado_notificacion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL
);

CREATE TABLE marca_vehiculo (
    id_marca SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE modelo_vehiculo (
    id_modelo INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_marca SMALLINT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    anio SMALLINT,
    CONSTRAINT fk_modelo_marca FOREIGN KEY (id_marca) REFERENCES marca_vehiculo(id_marca),
    CONSTRAINT uk_modelo UNIQUE (id_marca, nombre, anio)
);

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
    CONSTRAINT fk_persona_tipo_id FOREIGN KEY (id_tipo_identificacion) REFERENCES tipo_identificacion(id_tipo_identificacion),
    CONSTRAINT fk_persona_estado FOREIGN KEY (id_estado_usuario) REFERENCES estado_usuario(id_estado_usuario)
);

CREATE TABLE usuario (
    id_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    ultimo_acceso TIMESTAMP,
    intento_fallido SMALLINT DEFAULT 0,
    bloqueado_hasta TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE
);

CREATE TABLE cliente (
    id_cliente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    nit VARCHAR(20),
    razon_social VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE
);

CREATE TABLE mecanico (
    id_mecanico INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    especialidad VARCHAR(100),
    grado_academico VARCHAR(50),
    valor_hora DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mecanico_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE
);

CREATE TABLE recepcionista (
    id_recepcionista INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE,
    turno VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recepcionista_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE CASCADE
);

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
    CONSTRAINT fk_vehiculo_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_vehiculo_modelo FOREIGN KEY (id_modelo) REFERENCES modelo_vehiculo(id_modelo)
);

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
    CONSTRAINT fk_orden_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo),
    CONSTRAINT fk_orden_estado FOREIGN KEY (id_estado_orden) REFERENCES estado_orden(id_estado_orden),
    CONSTRAINT fk_orden_recepcionista FOREIGN KEY (id_recepcionista) REFERENCES recepcionista(id_recepcionista),
    CONSTRAINT fk_orden_mecanico FOREIGN KEY (id_mecanico) REFERENCES mecanico(id_mecanico),
    CONSTRAINT chk_fechas_orden CHECK (fecha_entrega IS NULL OR fecha_entrega > fecha_ingreso)
);

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
    CONSTRAINT fk_repuesto_tipo FOREIGN KEY (id_tipo_repuesto) REFERENCES tipo_repuesto(id_tipo_repuesto)
);

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
    CONSTRAINT fk_detalle_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_trabajo(id_orden_trabajo) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_servicio FOREIGN KEY (id_tipo_servicio) REFERENCES tipo_servicio(id_tipo_servicio),
    CONSTRAINT fk_detalle_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto(id_repuesto),
    CONSTRAINT chk_detalle_origen CHECK (id_tipo_servicio IS NOT NULL OR id_repuesto IS NOT NULL)
);

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
    CONSTRAINT fk_movimiento_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto(id_repuesto),
    CONSTRAINT fk_movimiento_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_trabajo(id_orden_trabajo),
    CONSTRAINT chk_tipo_movimiento CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA', 'AJUSTE'))
);

-- ============================================================
-- 4. SEGURIDAD (Roles y Funciones)
-- ============================================================

CREATE TABLE rol (
    id_rol INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_rol SMALLINT NOT NULL,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_rol_tipo FOREIGN KEY (id_tipo_rol) REFERENCES tipo_rol(id_tipo_rol)
);

CREATE TABLE funcion (
    id_funcion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_funcion SMALLINT NOT NULL,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    ruta VARCHAR(200),
    metodo_http VARCHAR(10),
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_funcion_tipo FOREIGN KEY (id_tipo_funcion) REFERENCES tipo_funcion(id_tipo_funcion)
);

CREATE TABLE rol_funcion (
    id_rol_funcion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol INTEGER NOT NULL,
    id_funcion INTEGER NOT NULL,
    CONSTRAINT fk_rf_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol) ON DELETE CASCADE,
    CONSTRAINT fk_rf_funcion FOREIGN KEY (id_funcion) REFERENCES funcion(id_funcion) ON DELETE CASCADE,
    CONSTRAINT uk_rol_funcion UNIQUE (id_rol, id_funcion)
);

-- ============================================================
-- 5. IDIOM: REFLEXIÓN (Jerarquías)
-- ============================================================

CREATE TABLE funcion_dependencia (
    id_funcion_dependencia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_funcion_padre INTEGER NOT NULL,
    id_funcion_hija INTEGER NOT NULL,
    CONSTRAINT fk_fd_padre FOREIGN KEY (id_funcion_padre) REFERENCES funcion(id_funcion) ON DELETE CASCADE,
    CONSTRAINT fk_fd_hija FOREIGN KEY (id_funcion_hija) REFERENCES funcion(id_funcion) ON DELETE CASCADE,
    CONSTRAINT uk_funcion_dependencia UNIQUE (id_funcion_padre, id_funcion_hija),
    CONSTRAINT chk_funciones_diferentes CHECK (id_funcion_padre <> id_funcion_hija)
);

CREATE TABLE repuesto_equivalencia (
    id_repuesto_equivalencia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_repuesto_principal INTEGER NOT NULL,
    id_repuesto_equivalente INTEGER NOT NULL,
    CONSTRAINT fk_re_principal FOREIGN KEY (id_repuesto_principal) REFERENCES repuesto(id_repuesto) ON DELETE CASCADE,
    CONSTRAINT fk_re_equivalente FOREIGN KEY (id_repuesto_equivalente) REFERENCES repuesto(id_repuesto) ON DELETE CASCADE,
    CONSTRAINT uk_repuesto_equivalencia UNIQUE (id_repuesto_principal, id_repuesto_equivalente),
    CONSTRAINT chk_repuestos_diferentes CHECK (id_repuesto_principal <> id_repuesto_equivalente)
);

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
    CONSTRAINT fk_ura_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_ura_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol),
    CONSTRAINT fk_ura_estado FOREIGN KEY (id_estado_asignacion) REFERENCES estado_asignacion(id_estado_asignacion),
    CONSTRAINT chk_fechas_asignacion CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);

-- ============================================================
-- 7. NUEVOS MÓDULOS TUULAPP (B2B / Gestión)
-- ============================================================

-- 7.1 Presupuesto (Diagnóstico previo a la reparación)
CREATE TABLE presupuesto (
    id_presupuesto BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_orden_trabajo INTEGER NOT NULL,
    id_estado_presupuesto SMALLINT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_envio TIMESTAMP,
    fecha_respuesta TIMESTAMP,
    monto_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    observacion TEXT,
    CONSTRAINT fk_presupuesto_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_trabajo(id_orden_trabajo) ON DELETE CASCADE,
    CONSTRAINT fk_presupuesto_estado FOREIGN KEY (id_estado_presupuesto) REFERENCES estado_presupuesto(id_estado_presupuesto)
);

CREATE TABLE presupuesto_detalle (
    id_presupuesto_detalle BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_presupuesto BIGINT NOT NULL,
    id_tipo_servicio SMALLINT,
    id_repuesto INTEGER,
    descripcion VARCHAR(200),
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_pdetalle_presupuesto FOREIGN KEY (id_presupuesto) REFERENCES presupuesto(id_presupuesto) ON DELETE CASCADE,
    CONSTRAINT fk_pdetalle_servicio FOREIGN KEY (id_tipo_servicio) REFERENCES tipo_servicio(id_tipo_servicio),
    CONSTRAINT fk_pdetalle_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto(id_repuesto),
    CONSTRAINT chk_pdetalle_origen CHECK (id_tipo_servicio IS NOT NULL OR id_repuesto IS NOT NULL)
);

-- 7.2 Agendamiento (Calendario del taller)
CREATE TABLE cita (
    id_cita BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_vehiculo INTEGER NOT NULL,
    id_recepcionista INTEGER,
    id_estado_cita SMALLINT NOT NULL,
    fecha_hora_inicio TIMESTAMP NOT NULL,
    fecha_hora_fin TIMESTAMP NOT NULL,
    motivo VARCHAR(200),
    observacion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cita_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo),
    CONSTRAINT fk_cita_recepcionista FOREIGN KEY (id_recepcionista) REFERENCES recepcionista(id_recepcionista),
    CONSTRAINT fk_cita_estado FOREIGN KEY (id_estado_cita) REFERENCES estado_cita(id_estado_cita),
    CONSTRAINT chk_cita_fechas CHECK (fecha_hora_fin > fecha_hora_inicio)
);

-- 7.3 Notificaciones (Comunicación automática)
CREATE TABLE notificacion (
    id_notificacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_notificacion SMALLINT NOT NULL,
    id_estado_notificacion SMALLINT NOT NULL,
    id_persona_destino INTEGER NOT NULL,
    id_orden_trabajo INTEGER,
    id_cita BIGINT,
    asunto VARCHAR(150),
    mensaje TEXT NOT NULL,
    canal VARCHAR(20) DEFAULT 'WHATSAPP', -- WHATSAPP, SMS, EMAIL
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_envio TIMESTAMP,
    CONSTRAINT fk_notif_tipo FOREIGN KEY (id_tipo_notificacion) REFERENCES tipo_notificacion(id_tipo_notificacion),
    CONSTRAINT fk_notif_estado FOREIGN KEY (id_estado_notificacion) REFERENCES estado_notificacion(id_estado_notificacion),
    CONSTRAINT fk_notif_persona FOREIGN KEY (id_persona_destino) REFERENCES persona(id_persona),
    CONSTRAINT fk_notif_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_trabajo(id_orden_trabajo),
    CONSTRAINT fk_notif_cita FOREIGN KEY (id_cita) REFERENCES cita(id_cita)
);

-- 7.4 Encuesta de Satisfacción (Post-entrega)
CREATE TABLE encuesta (
    id_encuesta BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_orden_trabajo INTEGER NOT NULL UNIQUE,
    puntuacion SMALLINT CHECK (puntuacion BETWEEN 1 AND 5),
    comentario TEXT,
    fecha_envio TIMESTAMP,
    fecha_respuesta TIMESTAMP,
    CONSTRAINT fk_encuesta_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_trabajo(id_orden_trabajo) ON DELETE CASCADE
);

-- 7.5 Pago y Factura (Consolidado)
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
    CONSTRAINT fk_pago_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_trabajo(id_orden_trabajo),
    CONSTRAINT fk_pago_tipo FOREIGN KEY (id_tipo_pago) REFERENCES tipo_pago(id_tipo_pago),
    CONSTRAINT fk_pago_estado FOREIGN KEY (id_estado_pago) REFERENCES estado_pago(id_estado_pago),
    CONSTRAINT fk_pago_tipo_comprobante FOREIGN KEY (id_tipo_comprobante) REFERENCES tipo_comprobante(id_tipo_comprobante)
);

CREATE TABLE factura (
    id_factura BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pago BIGINT UNIQUE,
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
    CONSTRAINT fk_factura_pago FOREIGN KEY (id_pago) REFERENCES pago(id_pago),
    CONSTRAINT fk_factura_estado FOREIGN KEY (id_estado_factura) REFERENCES estado_factura(id_estado_factura)
);

-- ============================================================
-- 8. DATOS INICIALES (Seeders) para los nuevos módulos
-- ============================================================

INSERT INTO estado_presupuesto (codigo, nombre, es_terminal) VALUES
('BOR', 'Borrador', FALSE),
('ENV', 'Enviado al Cliente', FALSE),
('APR', 'Aprobado', TRUE),
('REC', 'Rechazado', TRUE),
('VEN', 'Vencido', TRUE);

INSERT INTO estado_cita (codigo, nombre, es_terminal) VALUES
('PRO', 'Programada', FALSE),
('CON', 'Confirmada', FALSE),
('ATE', 'Atendida', TRUE),
('CAN', 'Cancelada', TRUE),
('AUS', 'No Asistió', TRUE);

INSERT INTO tipo_notificacion (codigo, nombre, plantilla) VALUES
('PRESUP', 'Presupuesto Enviado', 'Hola {cliente}, tu presupuesto para {vehiculo} es de {monto} Bs. Responde APROBAR o RECHAZAR.'),
('LISTO', 'Vehículo Listo', 'Hola {cliente}, tu vehículo {vehiculo} ya está listo para retirar. Total a pagar: {monto} Bs.'),
('CITA', 'Recordatorio de Cita', 'Hola {cliente}, te recordamos tu cita para {vehiculo} el día {fecha} a las {hora}.'),
('ENCUESTA', 'Encuesta de Satisfacción', 'Hola {cliente}, ¿cómo calificas nuestro servicio? Responde del 1 al 5.');

INSERT INTO estado_notificacion (codigo, nombre) VALUES
('PEN', 'Pendiente'),
('ENV', 'Enviada'),
('FAL', 'Fallida'),
('LEI', 'Leída');

-- ============================================================
-- 9. VISTAS PARA BUSINESS INTELLIGENCE (KPIs Tuulapp)
-- ============================================================

-- KPI: Ventas y facturación por día
CREATE OR REPLACE VIEW v_kpi_venta_diaria AS
SELECT 
    DATE(f.fecha_emision) AS fecha,
    COUNT(DISTINCT f.id_factura) AS cantidad_factura,
    SUM(f.monto_total) AS ingreso_total
FROM factura f
WHERE f.id_estado_factura = (SELECT id_estado_factura FROM estado_factura WHERE codigo = 'EMI')
GROUP BY DATE(f.fecha_emision);

-- KPI: Rendimiento por Mecánico
CREATE OR REPLACE VIEW v_kpi_mecanico AS
SELECT 
    p.nombre || ' ' || p.apellido AS mecanico,
    COUNT(ot.id_orden_trabajo) AS total_ordenes,
    SUM(ot.total) AS monto_generado,
    AVG(EXTRACT(EPOCH FROM (ot.fecha_entrega - ot.fecha_ingreso))/3600) AS horas_promedio
FROM mecanico m
JOIN persona p ON p.id_persona = m.id_persona
LEFT JOIN orden_trabajo ot ON ot.id_mecanico = m.id_mecanico AND ot.fecha_entrega IS NOT NULL
GROUP BY m.id_mecanico, p.nombre, p.apellido;

-- KPI: Tasa de Aprobación de Presupuestos
CREATE OR REPLACE VIEW v_kpi_presupuesto AS
SELECT 
    ep.codigo AS estado,
    COUNT(*) AS cantidad,
    SUM(pr.monto_total) AS monto_total
FROM presupuesto pr
JOIN estado_presupuesto ep ON ep.id_estado_presupuesto = pr.id_estado_presupuesto
GROUP BY ep.codigo;