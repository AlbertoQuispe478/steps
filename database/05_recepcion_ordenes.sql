-- Sprint 2 (HU-03/HU-04): marcas y modelos de ejemplo + perfil de recepcionista para el administrador.
INSERT INTO marca_vehiculo (nombre) VALUES ('Toyota'),('Nissan'),('Chevrolet'),('Mazda'),('Hyundai') ON CONFLICT (nombre) DO NOTHING;

INSERT INTO modelo_vehiculo (id_marca, nombre, anio)
SELECT m.id_marca, v.n, v.a FROM (VALUES ('Toyota','Corolla',2018),('Nissan','Versa',2019),('Chevrolet','Spark',2017),('Mazda','3',2020),('Hyundai','i10',2018)) v(m,n,a)
JOIN marca_vehiculo m ON m.nombre = v.m ON CONFLICT (id_marca, nombre, anio) DO NOTHING;

INSERT INTO recepcionista (id_persona, turno) SELECT id_persona, 'ADMIN' FROM persona WHERE email = 'alberto@steps.test' ON CONFLICT (id_persona) DO NOTHING;

-- Funciones de menú
INSERT INTO funcion (id_tipo_funcion, codigo, nombre, ruta, metodo_http)
SELECT id_tipo_funcion, 'ordenes', 'Órdenes de trabajo', '/ordenes', 'GET' FROM tipo_funcion WHERE codigo = 'PAN'
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO funcion (id_tipo_funcion, codigo, nombre, ruta, metodo_http)
SELECT id_tipo_funcion, 'recepcion', 'Recepción', '/recepcion', 'GET' FROM tipo_funcion WHERE codigo = 'PAN'
ON CONFLICT (codigo) DO NOTHING;

-- Asignar permisos a los roles
INSERT INTO rol_funcion (id_rol, id_funcion)
SELECT r.id_rol, f.id_funcion FROM rol r JOIN funcion f ON f.codigo = 'ordenes' WHERE r.codigo IN ('ADMIN','RECEP','MECANICO','CLIENTE')
ON CONFLICT (id_rol, id_funcion) DO NOTHING;

INSERT INTO rol_funcion (id_rol, id_funcion)
SELECT r.id_rol, f.id_funcion FROM rol r JOIN funcion f ON f.codigo = 'recepcion' WHERE r.codigo IN ('ADMIN','RECEP')
ON CONFLICT (id_rol, id_funcion) DO NOTHING;