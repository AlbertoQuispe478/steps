-- ============================================================
-- AJUSTES AL ESQUEMA (Steps) — respetan los IDIOMS de Marcelo Flores
-- Se ejecuta DESPUÉS de 01_schema.sql. Nomenclatura: singular, sustantivos.
-- ============================================================

-- IDIOM CLASIFICACIÓN: catálogo de operaciones auditables.
CREATE TABLE tipo_operacion (
    id_tipo_operacion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(40) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- IDIOM MAESTRO-DETALLE (hecho de auditoría): quién hizo qué y cuándo.
-- Solo se inserta; no se edita ni se borra. El usuario puede borrarse sin perder el hecho.
CREATE TABLE bitacora_operacion (
    id_bitacora_operacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario INTEGER,
    id_tipo_operacion SMALLINT NOT NULL,
    entidad VARCHAR(50) NOT NULL,
    id_registro BIGINT,
    detalle TEXT,
    fecha_operacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bitacora_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    CONSTRAINT fk_bitacora_tipo FOREIGN KEY (id_tipo_operacion) REFERENCES tipo_operacion(id_tipo_operacion)
);
CREATE INDEX idx_bitacora_usuario_fecha ON bitacora_operacion (id_usuario, fecha_operacion);
CREATE INDEX idx_bitacora_entidad ON bitacora_operacion (entidad, id_registro);

-- IDIOM COMPOSICIÓN (histórico con período): estados por los que pasa una orden.
-- Misma lógica que usuario_rol_asignacion: fecha_inicio / fecha_fin.
CREATE TABLE orden_estado_historial (
    id_orden_estado_historial BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_orden_trabajo INTEGER NOT NULL,
    id_estado_orden SMALLINT NOT NULL,
    id_usuario INTEGER,
    fecha_inicio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin TIMESTAMP,
    observacion TEXT,
    CONSTRAINT fk_oeh_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_trabajo(id_orden_trabajo) ON DELETE CASCADE,
    CONSTRAINT fk_oeh_estado FOREIGN KEY (id_estado_orden) REFERENCES estado_orden(id_estado_orden),
    CONSTRAINT fk_oeh_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    CONSTRAINT chk_oeh_fechas CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);
-- Una orden tiene un solo estado vigente a la vez.
CREATE UNIQUE INDEX uq_orden_estado_vigente ON orden_estado_historial (id_orden_trabajo) WHERE fecha_fin IS NULL;